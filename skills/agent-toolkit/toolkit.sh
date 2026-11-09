#!/usr/bin/env bash
# Pick the Claude Code plugins (skills, MCP servers, language servers) a project needs.
# Usage: bash toolkit.sh [DIR] [--apply]
#   Looks at DIR's files (default: current folder) and prints one line per recommended plugin,
#   with why, and for language servers whether the binary is installed (and how to install it).
#   --apply merges the recommendations into DIR/.claude/settings.json: enabledPlugins, plus
#   extraKnownMarketplaces for any marketplace that isn't Anthropic's official one. It keeps
#   everything already there, and only ever adds plugins from vetted.tsv.
set -uo pipefail
dir=.; apply=0
for a in "$@"; do case $a in --apply) apply=1 ;; *) dir=$a ;; esac; done
cd "$dir" || exit 2
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
has() { for p in "$@"; do compgen -G "$p" >/dev/null && return 0; git ls-files -- "$p" 2>/dev/null | grep -q . && return 0; done; return 1; }
picks=()
pick() { picks+=("$1"); printf '%-42s %s\n' "$1" "$2"; }
lsp() { # plugin, binary, install command
  if command -v "$2" >/dev/null; then pick "$1" "language server ($2 installed)"
  else pick "$1" "language server: install $2 first: $3"; fi
}

code=0; deps=0
has '*.ts' '*.tsx' '*.js' '*.mjs' 'src/*.ts' 'package.json' 'tsconfig.json' && { code=1
  lsp typescript-lsp@claude-plugins-official typescript-language-server \
    "$(command -v bun >/dev/null && echo 'bun add -g typescript-language-server typescript' || echo 'npm i -g typescript-language-server typescript')"; }
has 'pyproject.toml' 'requirements*.txt' 'setup.py' '*.py' && { code=1; lsp pyright-lsp@claude-plugins-official pyright-langserver 'npm i -g pyright'; }
has 'go.mod' '*.go' && { code=1; lsp gopls-lsp@claude-plugins-official gopls 'go install golang.org/x/tools/gopls@latest'; }
has 'Cargo.toml' '*.rs' && { code=1; lsp rust-analyzer-lsp@claude-plugins-official rust-analyzer 'rustup component add rust-analyzer'; }
has 'Gemfile' '*.rb' && { code=1; lsp ruby-lsp@claude-plugins-official ruby-lsp 'gem install ruby-lsp'; }
has 'pom.xml' 'build.gradle' '*.java' && { code=1; lsp jdtls-lsp@claude-plugins-official jdtls 'brew install jdtls'; }
has 'CMakeLists.txt' '*.c' '*.cpp' '*.h' && { code=1; lsp clangd-lsp@claude-plugins-official clangd 'brew install llvm'; }
has '*.csproj' '*.cs' && { code=1; lsp csharp-lsp@claude-plugins-official csharp-ls 'dotnet tool install -g csharp-ls'; }
has 'composer.json' '*.php' && { code=1; lsp php-lsp@claude-plugins-official intelephense 'npm i -g intelephense'; }
has 'Package.swift' '*.swift' && { code=1; lsp swift-lsp@claude-plugins-official sourcekit-lsp 'install Xcode or the Swift toolchain'; }
has 'build.gradle.kts' '*.kt' && { code=1; lsp kotlin-lsp@claude-plugins-official kotlin-lsp 'see github.com/Kotlin/kotlin-lsp'; }
has 'package.json' 'pyproject.toml' 'requirements*.txt' 'go.mod' 'Cargo.toml' 'Gemfile' 'pom.xml' 'composer.json' && deps=1

# A project that's being started has no code yet: say what it will be written in to get the LSPs.
[ $code = 1 ] || has '*.md' && pick superpowers@claude-plugins-official "plans, test-driven work, debugging, reviews"
[ $code = 1 ] && pick ponytail@ponytail "the smallest change that fully solves the task"
[ $deps = 1 ] && pick context7@claude-plugins-official "current docs for the libraries in your dependencies"
git remote get-url origin 2>/dev/null | grep -q github.com && pick githard@githard "running the repo: issues, PRs, releases, security"
if grep -qsE '"(react|vue|svelte|astro|next|nuxt|@sveltejs/kit|solid-js)"' package.json; then
  pick frontend-design@claude-plugins-official "a web UI to design"
  pick playwright@claude-plugins-official "a web UI to test in a real browser"
fi

[ $apply = 1 ] || { echo; echo "Run again with --apply to write these into .claude/settings.json."; exit 0; }
f=.claude/settings.json
# Claude Code protects .claude/, so a session may not be allowed to write it. Say so, and print what to write.
if ! { mkdir -p .claude && { [ -f "$f" ] || echo '{}' > "$f"; } && [ -w "$f" ]; } 2>/dev/null; then
  echo "couldn't write $f here. Ask the user to allow it, or give them this to merge into it:"
  f=$(mktemp); echo '{}' > "$f"; show=1
fi
for p in "${picks[@]}"; do
  row=$(awk -F'\t' -v p="$p" '$1==p' "$here/vetted.tsv")
  [ -n "$row" ] || { echo "skipped  $p: not in vetted.tsv, needs the owner's yes"; continue; }
  src=$(cut -f2 <<<"$row"); market=${p#*@}
  tmp=$(mktemp)
  if [ "$src" = official ]; then
    jq --arg p "$p" '.enabledPlugins[$p] = true' "$f" > "$tmp"
  else
    jq --arg p "$p" --arg m "$market" --arg r "$src" \
      '.enabledPlugins[$p] = true | .extraKnownMarketplaces[$m] //= {source: {source: "github", repo: $r}}' "$f" > "$tmp"
  fi
  mv "$tmp" "$f" || { echo "couldn't write $f"; exit 1; }
done
[ "${show:-0}" = 1 ] && { cat "$f"; exit 1; }
echo "wrote $f. Commit it, so everyone who clones and trusts the repo gets the same tools."
