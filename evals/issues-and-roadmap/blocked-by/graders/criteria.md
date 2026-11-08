---
type: llm
weight: 1
---

PASS only if the reply does both: (1) gives a GitHub API call to the issue dependencies endpoint (repos/OWNER/REPO/issues/12/dependencies/blocked_by) passing the blocking issue's id; (2) gives a call to the sub_issues endpoint (repos/OWNER/REPO/issues/9/sub_issues) passing sub_issue_id. For both it must make clear that the id is the issue's API id (for example from gh api .../issues/N --jq .id), not the issue number.
