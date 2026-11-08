<!-- Title: say the change, not the area. "Add a --json flag to `jot list`", not "JSON support". -->

**What and why**
One or two sentences: what's wrong or missing, and who it's for.

**Files to change**
- `src/cli/list.js`
- `test/list.test.js`

**How to test**
`npm test -- list` passes, and `jot list --json` prints valid JSON (pipe it to `jq .`).

**Done when**
- [ ] `jot list --json` prints one JSON object per note
- [ ] a test covers it
- [ ] the README's usage section mentions the flag

**Stay out of**
`src/sync/`. It's being rewritten in #41.

New here? Comment to claim it and we'll assign you. Your PR's CI waits for a maintainer to approve it, and if `main` moves on, click **Update branch**.
