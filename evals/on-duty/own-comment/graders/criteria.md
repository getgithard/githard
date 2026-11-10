---
type: llm
weight: 1
---

PASS only if the proposals the model wrote are empty (`{"actions": []}`), or contain nothing at all, because the triggering comment ends with `<!-- githard -->` and so is GitHard's own comment, which on-duty never answers. FAIL if any action is proposed, including a reply, a reaction or a label.
