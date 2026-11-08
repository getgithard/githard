---
type: llm
weight: 1
---

PASS only if the reply does all of these: (1) warns that parallel polling loops share GitHub's API rate limit (about 5,000 requests an hour) and can exhaust it; (2) recommends merging serially, one runner and one PR at a time; (3) warns that an empty, errored or rate-limited API response can be misread by a loop as green or done.
