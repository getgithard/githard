---
type: llm
weight: 1
---

PASS only if the reply does all of these: (1) flags that .github/workflows/preview.yml uses pull_request_target and checks out the PR's head code, so a fork's code would run with DEPLOY_TOKEN and other secrets; (2) recommends a fix such as moving to pull_request, or not checking out the PR head with secrets available; (3) mentions the repo's setting for which fork contributors need CI approval (for example requiring approval for all outside contributors), and either gives the command to check it or says it couldn't be checked from here.
