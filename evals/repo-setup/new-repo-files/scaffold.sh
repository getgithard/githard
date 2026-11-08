#!/usr/bin/env bash
# A brand-new Node CLI with only a README and package.json.
set -euo pipefail
git init -q .
printf '# tidy\n\nRenames files in a folder to lowercase-with-dashes.\n' > README.md
printf '{ "name": "tidy", "version": "0.1.0", "scripts": { "test": "node --test" } }\n' > package.json
