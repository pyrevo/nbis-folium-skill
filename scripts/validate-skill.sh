#!/usr/bin/env sh
# Validate the distributable skill without requiring Quarto. If Quarto is
# available, also render the tracked example as a smoke test.
set -eu

skip_render=false
if [ "${1:-}" = "--skip-render" ]; then
  skip_render=true
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
skill_dir="$repo_root/skills/nbis-folium"
workflow="$skill_dir/templates/deploy-pages.yml"
logo="$skill_dir/templates/include_logo.html"
example="$repo_root/example"

test -f "$skill_dir/SKILL.md"
test -f "$workflow"
test -f "$logo"
test -f "$skill_dir/references/compatibility.md"
test -f "$skill_dir/references/licensing.md"

grep -Fq 'Python `folium`' "$skill_dir/SKILL.md"
grep -Fq 'requires an agent that can read the installed skill directory' "$skill_dir/SKILL.md"
grep -Fq 'REPORT_DIR: "__REPORT_DIR__"' "$workflow"
grep -Fq 'branches: ["__DEFAULT_BRANCH__"]' "$workflow"
grep -Fq 'quarto render --output-dir "$REPORT_DIR"' "$workflow"
grep -Fq '<svg' "$logo"
if grep -Fq 'data:image' "$logo"; then
  echo "The logo template must use inline SVG, not a data URI." >&2
  exit 1
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/nbis-folium-validate.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
sed -e 's/__DEFAULT_BRANCH__/main/g' -e 's/__REPORT_DIR__/report/g' "$workflow" > "$tmp_dir/deploy-pages.yml"
if grep -Fq '__DEFAULT_BRANCH__' "$tmp_dir/deploy-pages.yml" || grep -Fq '__REPORT_DIR__' "$tmp_dir/deploy-pages.yml"; then
  echo "Workflow placeholders were not fully substituted." >&2
  exit 1
fi
grep -Fq 'REPORT_DIR: "report"' "$tmp_dir/deploy-pages.yml"

if [ "$skip_render" = false ] && command -v quarto >/dev/null 2>&1; then
  output_dir="$tmp_dir/report"
  (cd "$example" && quarto render index.qmd --output-dir "$output_dir")
  test -f "$output_dir/index.html"
  grep -Fq '<svg' "$output_dir/index.html"
  echo "Validation passed; example rendered with Quarto."
else
  echo "Static validation passed; Quarto render skipped."
fi
