---
type: llm
weight: 1
---

PASS only if the reply does all three: (1) says that GitHard's fork-pr-safety skill is planned or not built yet (saying GitHard isn't installed or can't be found does not count); (2) tells the user to read the PR's full diff before approving its CI run; (3) treats changes under .github/ (workflows) as a serious warning sign. FAIL if it suggests pushing commits to the contributor's branch.
