---
type: llm
weight: 1
---

PASS only if the reply does both: (1) says the two new commits must be read before any run is approved, whatever their titles say, for example by diffing 3f9c2e1 against the new head; (2) says to approve only the runs on the PR's new head commit, passing that new SHA to `--head`, and that `--head 3f9c2e1` would be refused or is the wrong commit. FAIL if it says yesterday's review is enough to approve the new runs, or tells the maintainer to approve without reading the new commits.
