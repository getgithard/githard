## Code review

<!-- Paste into CONTRIBUTING.md. Covers OpenSSF gold: code_review_standards; supports two_person_review. -->

Every change reaches `main` through a pull request. A reviewer checks:

- it does what the PR says, and nothing it doesn't say
- it has tests for new behaviour, and they pass in CI
- it doesn't weaken security: input validation, secrets, permissions, dependencies
- docs change with the behaviour

At least one person who didn't write the change reviews it before a release ships it. When there's only one maintainer, the reviewer is {{a named second reviewer, or "anyone we can find: ask in the PR"}}. We track how many merged changes had a second reviewer, because gold needs at least half.
