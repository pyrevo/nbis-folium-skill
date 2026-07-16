#!/usr/bin/env sh
# Scaffold and render both upstream templates. Network access is deliberately
# opt-in so normal local validation remains fast and deterministic.
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
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/nbis-folium-integration.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

templates=${NBIS_FOLIUM_TEMPLATES:-"folium folium-webpage"}
for template in $templates; do
  case "$template" in
    folium|folium-webpage) ;;
    *) echo "Unknown template: $template" >&2; exit 2 ;;
  esac
  project="$tmp_dir/$template"
  mkdir -p "$project"
  (
    cd "$project"
    quarto use template "royfrancis/$template" --no-prompt
    if [ "$template" = folium ]; then
      test -f _quarto.yml
      grep -Fq 'logo:' _quarto.yml
    else
      test -f index.qmd
      test -f assets/include_logo.html
    fi

    if [ ! -d _extensions/quarto-ext/fontawesome ]; then
      quarto add quarto-ext/fontawesome --no-prompt
    fi
    if [ ! -d _extensions/mcanouil/collapse-output ]; then
      quarto add mcanouil/quarto-collapse-output@1.4.0 --no-prompt
    fi
    if [ ! -d _extensions/royfrancis/accordion ]; then
      quarto add royfrancis/quarto-accordion --no-prompt
    fi

    mkdir -p .github/workflows
    sed -e 's/__DEFAULT_BRANCH__/main/g' -e 's/__REPORT_DIR__/report/g' \
      "$skill_dir/templates/deploy-pages.yml" > .github/workflows/deploy-pages.yml
    ! grep -Fq '__DEFAULT_BRANCH__' .github/workflows/deploy-pages.yml
    ! grep -Fq '__REPORT_DIR__' .github/workflows/deploy-pages.yml
    if [ "$template" = folium-webpage ]; then
      cp "$skill_dir/templates/include_logo.html" assets/include_logo.html
    fi
    quarto render --output-dir report
    find report -type f -name '*.html' -print -quit | grep -q .
    if [ "$template" = folium ]; then
      test -f report/assets/logos/nbis-scilifelab.webp
      grep -R -Fq 'assets/logos/nbis-scilifelab.webp' report
    else
      grep -R -Fq '<svg' report
    fi
  )
done

echo "Upstream scaffold integration test passed."
