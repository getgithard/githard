#!/usr/bin/env bash
# A new Bun and TypeScript CLI on GitHub, with dependencies and no Claude Code setup yet.
set -euo pipefail
git init -q .
git remote add origin https://github.com/example-org/keyparity.git
printf '{ "name": "keyparity", "type": "module", "dependencies": { "commander": "^14.0.0", "picocolors": "^1.1.0" } }\n' > package.json
printf '{ "compilerOptions": { "strict": true } }\n' > tsconfig.json
mkdir -p src && printf 'console.log(process.env.API_KEY)\n' > src/index.ts
git add -A
