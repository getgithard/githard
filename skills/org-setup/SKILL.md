---
name: org-setup
description: Use when creating or tidying up a GitHub organization, including its profile README, the public .github repo with default community files, a verified domain, pinned repos, the org's description and avatar, member defaults such as base permissions and two-factor authentication, or auditing how an existing org is set up.
---

# Org setup

An org's page is the first thing people see before they open a single repo. A blank one says nobody's home. This skill sets up an org the way you'd want it a year from now, or audits one that's already running.

The reasons behind each item are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Repo setup).

## The checklist

| Item | Who | How |
|---|---|---|
| Display name, description, website, public email | **owner** | Org settings, or `gh api -X PATCH orgs/ORG -f description="..." -f blog=https://...` run by the owner. Write the description with the `writing` skill. |
| Avatar | **owner** | **Settings**, then **Profile**, then **Upload new picture**. No API. |
| Public `.github` repo with `profile/README.md` | you prepare, **owner** runs | Fill `${CLAUDE_SKILL_DIR}/templates/profile/README.md`. Add the default community files from `repo-setup`: CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, issue and PR templates. Any repo without its own copy inherits them. |
| Verified domain | **owner** | **Settings**, then **Verified and approved domains**, then **Add a domain**. Add the TXT record GitHub shows at the DNS host, then click **Verify**. The org's public email must be on that domain. |
| Pinned repos | **owner** | The org's page, then **Customize pins**. No API. |
| Members get read access by default | **owner** | **Settings**, then **Member privileges**, then **Base permissions**: Read. |
| Two-factor authentication required | **owner** | **Settings**, then **Authentication security**, then **Require two-factor authentication**. Check every member has 2FA first, because anyone without it is removed from the org. |
| Sign-off required on web commits | **owner** | **Settings**, then **Repository**, then **Require contributors to sign off on web-based commits**, or `gh api -X PATCH orgs/ORG -F web_commit_signoff_required=true` run by the owner. |

Org settings are account changes, so every one goes to the owner, even when an API exists. Give each as numbered steps with the URL, the button names, or the exact command.

## The .github repo

Prepare the files in a local folder, then give the owner one command:

```sh
bash ${CLAUDE_SKILL_DIR}/bootstrap-dotgithub.sh ORG /absolute/path/to/folder
```

It creates the public repo if it isn't there, makes `main` match the folder, and is safe to run again. Agents are often blocked from creating public repos and changing org settings, and that's right. The owner runs it, and you check the result.

Once it exists, give `ORG/.github` the same treatment as any repo: run `repo-setup` on it, ruleset included.

## Checking an org

```sh
bash ${CLAUDE_SKILL_DIR}/org-audit.sh ORG
```

It prints `ok`, `missing`, `skipped` or `unknown` for each item. Add `--skip "verified domain"` (or any item's name, exactly as printed) for something that's off on purpose, such as a domain the project doesn't have. Settings only owners can see come back `unknown` for anyone else, never `ok`. Report what's missing in the order of the table, with the owner's steps for each.

## An existing org

Run the audit, then the `.github` repo first: it fixes community files for every repo that doesn't have its own. Change the default member permission or turn on 2FA only after checking who it affects. Never remove a member.
