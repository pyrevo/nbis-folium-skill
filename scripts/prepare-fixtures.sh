#!/usr/bin/env sh
# Install the Quarto extensions the demo fixtures need.
#
# The fixtures used to vendor these: two byte-identical 1.3 MB _extensions trees,
# 35 tracked files each. Installing them instead removes that duplication and
# makes the demo build exercise the same extension-install path the skill puts in
# front of users, so an upstream break shows up as a red CI run.
#
# Versions are pinned explicitly. The vendored copies were an implicit pin;
# dropping them without pinning would trade duplication for silent drift.
set -eu

if ! command -v quarto >/dev/null 2>&1; then
  echo "prepare-fixtures.sh: Quarto is required." >&2
  exit 1
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# dir-under-_extensions <tab> pinned-ref
# NB: tag formats differ between these repos -- quarto-ext uses a v prefix,
# mcanouil and royfrancis do not. A wrong prefix fails the add outright.
extensions="quarto-ext/fontawesome:quarto-ext/fontawesome@v1.3.0
mcanouil/collapse-output:mcanouil/quarto-collapse-output@1.4.0
royfrancis/accordion:royfrancis/quarto-accordion@1.1.2"

fixtures=${NBIS_FOLIUM_FIXTURES:-"example example-folium"}

for fixture in $fixtures; do
  dir="$repo_root/$fixture"
  test -d "$dir" || { echo "no such fixture: $dir" >&2; exit 1; }
  echo "Preparing $fixture"
  for entry in $extensions; do
    installed_dir=${entry%%:*}
    ref=${entry#*:}
    if [ -d "$dir/_extensions/$installed_dir" ]; then
      echo "  already present: $installed_dir"
    else
      # --no-prompt: without it Quarto waits on an interactive trust
      # confirmation and any non-interactive shell blocks forever.
      (cd "$dir" && quarto add "$ref" --no-prompt)
    fi
  done
  # The fixtures cannot render without these, so fail loudly rather than
  # letting a later render produce a subtly wrong page.
  for entry in $extensions; do
    installed_dir=${entry%%:*}
    test -d "$dir/_extensions/$installed_dir" \
      || { echo "missing after install: $fixture/_extensions/$installed_dir" >&2; exit 1; }
  done
done

echo "Fixture extensions ready."
