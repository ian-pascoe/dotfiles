#!/usr/bin/env bash
# Rewrites hunk-themes.txt from the installed hunk's theme list, which the theme
# tests check the hunk mapping in dot_config/shell/interactive.sh against.
set -euo pipefail

hunk=$(command -v hunk) || {
  echo "hunk is not installed" >&2
  exit 1
}
# hunk's bin dir is node_modules/.bin beside the hunkdiff package.
names=$(dirname "$hunk")/../hunkdiff/dist/npm/opentui/themes.d.ts
[[ -f $names ]] || {
  echo "no theme list at $names" >&2
  exit 1
}

{
  echo "# Hunk's diff themes (Shiki's bundled themes): HUNK_DIFF_THEME_NAMES in"
  echo "# hunkdiff's dist/npm/opentui/themes.d.ts, hunk $(hunk --version). Refresh after"
  echo "# upgrading hunk with: pnpm run hunk-themes"
  grep -o 'HUNK_DIFF_THEME_NAMES: readonly \[[^]]*\]' "$names" | grep -o '"[^"]*"' | tr -d '"'
} >"$(dirname "$0")/hunk-themes.txt"
