#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# A small CLI repo whose only writing rules live in a Vale config, and they disagree with GitHard's voice.
set -euo pipefail
git init -q .
cat > README.md <<'MD'
# tidy

TODO: intro
MD
cat > .vale.ini <<'INI'
StylesPath = styles
MinAlertLevel = error

[*.md]
BasedOnStyles = House
INI
mkdir -p styles/House
cat > styles/House/Contractions.yml <<'YML'
extends: existence
message: "Spell out '%s'. This project uses no contractions."
level: error
ignorecase: true
tokens:
  - '\b\w+n''t\b'
  - '\b\w+''(s|re|ll|ve|d|m)\b'
YML
cat > styles/House/Directory.yml <<'YML'
extends: substitution
message: "Use '%s' instead of '%s'."
level: error
ignorecase: true
swap:
  folders?: directory
YML
cat > tidy.sh <<'SH'
#!/bin/sh
# tidy: renames files in a folder to lowercase-with-dashes.
SH
