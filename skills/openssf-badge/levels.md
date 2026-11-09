# Meeting each criterion

Criteria ids, levels and requirements are in `criteria.tsv`, taken from bestpractices.dev/en/criteria/0, /1 and /2 on 2026-11-08. This file says how a GitHard project meets each MUST. "Skill" means another GitHard skill does the work. "Template" means a file in `templates/`. **Needs others** marks a criterion that only other people can satisfy.

On the form, every Met answer needs evidence: a URL to the file, the setting or the workflow run. "N/A" needs a reason that's true. When in doubt, answer Unmet and fix it. Never answer Met for something that isn't.

## Passing

Most of passing is `repo-setup` (license, CONTRIBUTING, SECURITY, private vulnerability reporting, CI), `releases` (unique versions, tags, release notes), `security-baseline` (static analysis with CodeQL, secret scanning, no leaked credentials) and `contributors` (a reply to every report). A project that has run those skills usually needs only to answer the form with URLs.

## Silver

| Criterion | How |
|---|---|
| contribution_requirements, code_of_conduct, dco | Skill `repo-setup`: CONTRIBUTING, CODE_OF_CONDUCT and the DCO check. |
| governance, roles_responsibilities, access_continuity | Template `GOVERNANCE.md`. Access continuity needs a second person with owner access, which is **needs others**. |
| documentation_roadmap | Template `ROADMAP.md`, linked to milestones (skill `issues-and-roadmap`). |
| documentation_architecture | Template `docs/ARCHITECTURE.md`. |
| documentation_security, assurance_case, implement_secure_design, input_validation | Template `docs/SECURITY-MODEL.md`. The assurance case is its threat model, trust boundaries and the weaknesses it counters. |
| documentation_quick_start, documentation_current | Skill `docs-honesty`, with an audit at each release. |
| documentation_achievements | Put the badge in the README within 48 hours of earning it. |
| sites_password_security | N/A if the project's sites have no logins of their own (GitHub handles accounts). |
| maintenance_or_update | Document in the README or SECURITY which versions get fixes. "Only the latest release" is a valid policy if it's written down. |
| report_tracker | GitHub Issues. |
| vulnerability_report_credit, vulnerability_response_process | SECURITY.md says how reports are handled, and advisories credit the reporter. |
| coding_standards, coding_standards_enforced | Name the style guide for each language in CONTRIBUTING, and enforce it in CI with a linter or formatter (shellcheck, ruff, eslint, gofmt...). |
| build_standard_variables, build_non_recursive, build_repeatable, installation_common, installation_standard_variables | N/A with a reason for projects that don't compile or install files. Otherwise use the language's standard build and install tools. |
| installation_development_quick | CONTRIBUTING has a "set up and run the tests" section of a few commands. |
| external_dependencies, dependency_monitoring, updateable_reused_components | A lockfile or manifest, plus Dependabot (skill `repo-setup`). |
| automated_integration_testing, test_policy_mandated, tests_documented_added | CI on every PR. The PR template and CONTRIBUTING say new behaviour needs tests. |
| regression_tests_added50 | At least half of the bug fixes in the last six months add a test. Check it with `gh pr list --state merged --search "fix in:title"`. |
| test_statement_coverage80 | A coverage tool in CI (coverage.py, c8, go test -cover, tarpaulin, or kcov for shell). Report the number. |
| warnings_strict | The strictest practical linter settings, failing CI. |
| crypto_* | N/A for projects that do no cryptography themselves. Otherwise use vetted libraries and their safe defaults. |
| signed_releases | Skill `releases`: build attestations, plus documented verification (`gh attestation verify`). |
| static_analysis_common_vulnerabilities | Skill `security-baseline`: CodeQL. |
| dynamic_analysis_unsafe | N/A unless written in a memory-unsafe language. Otherwise run sanitizers (ASan, UBSan) in CI. |

## Gold

| Criterion | How |
|---|---|
| bus_factor, contributors_unassociated | **Needs others.** At least two people who could keep the project going, and two significant contributors from different organizations. Grow them with skills `contributors`, `issues-and-roadmap` and `growth`. There's no shortcut. |
| two_person_review | **Needs others.** At least half of the changes in a release are reviewed by someone other than the author. Count them with `gh pr list --state merged --json reviews,author`. |
| code_review_standards | Template `CODE-REVIEW.md`, pasted into CONTRIBUTING. |
| copyright_per_file, license_per_file | `add-spdx.sh "HOLDER" SPDX-ID` adds both lines to every source file, and `--check` in CI keeps them there. |
| repo_distributed | Git. |
| small_tasks | Skill `issues-and-roadmap`: a pool of `good first issue` issues. |
| require_2FA, secure_2FA | Skill `org-setup`: require 2FA for the org. secure_2FA asks for app or hardware keys, not SMS. Say so in GOVERNANCE. |
| build_reproducible | N/A with a reason when nothing is built. Otherwise pin the toolchain and dependencies, and show two builds produce the same output. |
| test_invocation, test_continuous_integration | The language's standard test command, run in CI. |
| test_statement_coverage90, test_branch_coverage80 | A coverage tool in CI with these as minimums. |
| crypto_used_network, crypto_tls12 | HTTPS only, TLS 1.2 or later. GitHub, Cloudflare and Netlify meet it by default. N/A if the software itself doesn't use the network. |
| hardened_site | `csp-headers.py` writes `_headers` for Cloudflare Pages or Netlify, and `check-headers.sh URL...` checks the website, the repo and the download site. |
| security_review | Template `docs/SECURITY-MODEL.md`, with a dated review in the last five years. A self-review counts if it's real and written up. An outside review is stronger. |
| hardening | Hardened headers on the sites, least-privilege workflow tokens, and the language's own hardening (compiler flags, safe defaults). Document them in SECURITY-MODEL. |
| dynamic_analysis | At least one dynamic tool (a fuzzer, a sanitizer, or property-based tests) on each major release, or N/A with a true reason. |
