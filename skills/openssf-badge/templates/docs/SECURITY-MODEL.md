# Security model

<!-- Covers OpenSSF silver: documentation_security, assurance_case, implement_secure_design, input_validation; gold: security_review. Keep it honest: list what you don't defend against. -->

## What you can expect

{{What the software protects, and what it doesn't. For example: "It never sends your notes anywhere. It does not encrypt them on disk; use full-disk encryption for that."}}

## Threat model

| Threat | Where (see [ARCHITECTURE.md](ARCHITECTURE.md) trust boundaries) | How it's handled |
|---|---|---|
| {{e.g. malicious input file}} | {{boundary}} | {{validation, allowlist, rejection}} |

## Secure design principles we follow

{{One line each, with where you can see it: least privilege, fail-safe defaults, complete mediation, economy of mechanism, open design, input validation by allowlist.}}

## Common weaknesses we counter

{{For each relevant CWE or OWASP class, how the project avoids it, such as injection, path traversal or deserialization.}}

## Security reviews

| Date | Who | Scope | Result |
|---|---|---|---|
| {{date}} | {{reviewer, and their relationship to the project}} | {{what was reviewed}} | {{link to findings and fixes}} |

Gold needs a review within the last five years that covers the requirements and boundaries above.
