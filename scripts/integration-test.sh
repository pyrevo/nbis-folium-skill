#!/usr/bin/env sh
# Scaffold and render both upstream templates through the SAME script the skill
# tells the agent to run. This is the point of the exercise: this test used to
# re-implement the procedure, which let the documented commands rot (they were
# missing --no-prompt and deadlocked) while CI stayed green.
#
# Network access is deliberately opt-in so normal local validation stays fast
# and deterministic.
set -eu

if [ "${RUN_UPSTREAM_INTEGRATION:-}" != "1" ]; then
  echo "Set RUN_UPSTREAM_INTEGRATION=1 to run the upstream scaffold test." >&2
  exit 2
fi
if ! command -v quarto >/dev/null 2>&1; then
  echo "Quarto is required for the upstream scaffold test." >&2
  exit 1
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
skill_dir="$repo_root/skills/nbis-folium"
scaffold="$skill_dir/scripts/scaffold.sh"
test -x "$scaffold" || { echo "not executable: $scaffold" >&2; exit 1; }

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/nbis-folium-integration.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

templates=${NBIS_FOLIUM_TEMPLATES:-"folium folium-webpage"}
for template in $templates; do
  case "$template" in
    folium|folium-webpage) ;;
    *) echo "Unknown template: $template" >&2; exit 2 ;;
  esac

  # A non-default report dir on one template and a nested one on the other, so
  # the sed substitution and output-dir alignment are both exercised for real.
  if [ "$template" = folium ]; then
    report_dir=report
  else
    report_dir=build/site
  fi

  project="$tmp_dir/$template"
  "$scaffold" --template "$template" --dir "$project" \
    --report-dir "$report_dir" --branch main

  # The script asserts its own success; re-check the contract it promises the
  # skill, from the outside.
  (
    cd "$project"
    test -f .github/workflows/deploy-pages.yml
    ! grep -Fq '__DEFAULT_BRANCH__' .github/workflows/deploy-pages.yml
    ! grep -Fq '__REPORT_DIR__' .github/workflows/deploy-pages.yml
    grep -Fq "REPORT_DIR: \"$report_dir\"" .github/workflows/deploy-pages.yml
    grep -Fq 'branches: ["main"]' .github/workflows/deploy-pages.yml
    grep -Fqx "/$report_dir/" .gitignore

    test -d _extensions/quarto-ext/fontawesome
    test -d _extensions/mcanouil/collapse-output
    test -d _extensions/royfrancis/accordion

    find "$report_dir" -type f -name '*.html' -print -quit | grep -q .

    if [ "$template" = folium ]; then
      grep -Fq "  output-dir: $report_dir" _quarto.yml
      test -f "$report_dir/assets/logos/nbis-scilifelab.webp"
      grep -R -Fq 'assets/logos/nbis-scilifelab.webp' "$report_dir"
    else
      # `<svg` alone is a tautology here; it matches the script string literal
      # even when the logo never renders. Assert payload AND injection target.
      cmp -s assets/include_logo.html "$skill_dir/templates/include_logo.html"
      grep -R -Fq 'viewBox="0 0 1497.39 194.27"' "$report_dir"
      grep -R -Fq 'class="quarto-title-banner' "$report_dir"
    fi
  )
  echo "ok: $template -> $report_dir"
done

# The script must refuse a non-empty directory rather than merging blindly.
guard_dir="$tmp_dir/guard"
mkdir -p "$guard_dir"
: > "$guard_dir/pre-existing.txt"
if "$scaffold" --template folium --dir "$guard_dir" --skip-render >/dev/null 2>&1; then
  echo "FAIL: scaffold.sh accepted a non-empty directory" >&2
  exit 1
fi
test -f "$guard_dir/pre-existing.txt"
echo "ok: refuses a non-empty target directory"

echo "Upstream scaffold integration test passed."
