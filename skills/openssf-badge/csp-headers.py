"""Write a _headers file with hardened HTTP headers for a static site, for the gold
criterion hardened_site. Cloudflare Pages and Netlify both read _headers.

Usage: python3 csp-headers.py SITE_DIR [--check]

It hashes every inline <script>, <style> and style="" attribute in SITE_DIR's HTML,
so the Content-Security-Policy can allow exactly those and nothing inline besides.
With --check it writes nothing, and exits 1 if SITE_DIR/_headers is missing or stale.
"""
import base64
import hashlib
import re
import sys
from pathlib import Path


def sha(text):
    return "'sha256-" + base64.b64encode(hashlib.sha256(text.encode()).digest()).decode() + "'"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    site = Path(sys.argv[1])
    scripts, styles, attrs = set(), set(), set()
    for page in sorted(site.rglob("*.html")):
        html = page.read_text(encoding="utf-8")
        # Inline scripts only: a script with src= is covered by 'self'. JSON data blocks don't run.
        for attrs_text, body in re.findall(r"<script\b([^>]*)>(.*?)</script>", html, re.S | re.I):
            if "src=" not in attrs_text and "application/ld+json" not in attrs_text and body.strip():
                scripts.add(sha(body))
        styles.update(sha(body) for body in re.findall(r"<style\b[^>]*>(.*?)</style>", html, re.S | re.I))
        attrs.update(sha(v) for v in re.findall(r'\sstyle="([^"]*)"', html, re.I))

    # WebAssembly (Pagefind search, for one) needs this narrow allowance. It is not general eval.
    wasm = " 'wasm-unsafe-eval'" if any(site.rglob("*.wasm")) or any(site.rglob("wasm.*")) else ""

    def src(name, hashes, extra=""):
        return f"{name} 'self'{extra}" + "".join(" " + h for h in sorted(hashes))

    policy = "; ".join([
        "default-src 'self'",
        src("script-src", scripts, wasm),
        src("style-src", styles),
        f"style-src-attr 'unsafe-hashes' {' '.join(sorted(attrs))}" if attrs else "style-src-attr 'none'",
        "img-src 'self' data:",
        "font-src 'self'",
        "connect-src 'self'",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'none'",
    ])
    headers = "\n".join([
        "/*",
        f"  Content-Security-Policy: {policy}",
        "  Strict-Transport-Security: max-age=31536000; includeSubDomains",
        "  X-Content-Type-Options: nosniff",
        "  X-Frame-Options: DENY",
        "  Referrer-Policy: strict-origin-when-cross-origin",
        "  Permissions-Policy: camera=(), microphone=(), geolocation=()",
        "",
    ])
    # Hosts cap a header line (Cloudflare Pages at about 2,000 characters). A truncated CSP breaks
    # the site, so fail loudly instead.
    longest = max(len(line) for line in headers.splitlines())
    if longest > 2000:
        sys.exit(f"the Content-Security-Policy line is {longest} characters, over the 2,000 hosts allow. "
                 "Move inline style=\"\" attributes and <style> blocks into CSS files to drop their hashes.")
    target = site / "_headers"
    if "--check" in sys.argv:
        if not target.exists() or target.read_text() != headers:
            sys.exit(f"{target} is missing or out of date: run python3 csp-headers.py {site}")
        print(f"{target} is up to date")
        return
    target.write_text(headers)
    print(f"wrote {target}: {len(scripts)} inline scripts, {len(styles)} styles, {len(attrs)} style attributes hashed")


if __name__ == "__main__":
    main()
