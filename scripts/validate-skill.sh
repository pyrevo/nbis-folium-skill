#!/usr/bin/env sh
# Validate the distributable skill without requiring Quarto. If Quarto is
# available, also render the tracked examples as a smoke test.
set -eu

skip_render=false
if [ "${1:-}" = "--skip-render" ]; then
  skip_render=true
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
skill_dir="$repo_root/skills/nbis-folium"
workflow="$skill_dir/templates/deploy-pages.yml"
logo="$skill_dir/templates/include_logo.html"
scaffold="$skill_dir/scripts/scaffold.sh"
install_commands="$skill_dir/scripts/install-commands.sh"
site_skill="$repo_root/skills/folium-site/SKILL.md"
page_skill="$repo_root/skills/folium-page/SKILL.md"
example="$repo_root/example"
multi_example="$repo_root/example-folium"

# --- Everything the skill must ship -----------------------------------------
test -f "$skill_dir/SKILL.md"
test -f "$workflow"
test -f "$logo"
test -f "$skill_dir/references/compatibility.md"
test -f "$skill_dir/references/licensing.md"
test -f "$multi_example/_quarto.yml"
test -f "$multi_example/assets/logos/nbis-scilifelab.webp"

# The scaffold script and command wrappers live inside the skill so they survive
# `npx skills add`, which copies only skills/nbis-folium/.
test -x "$scaffold" || { echo "not executable: $scaffold" >&2; exit 1; }
test -x "$install_commands" || { echo "not executable: $install_commands" >&2; exit 1; }
test -f "$site_skill"
test -f "$page_skill"

sh -n "$scaffold"
sh -n "$install_commands"

# install-commands.sh copies files, so it must also be able to remove them.
grep -Fq -- '--uninstall' "$install_commands" \
  || { echo "$install_commands must support --uninstall." >&2; exit 1; }
# Uninstalling must target the two known filenames, never a glob or the whole dir.
if grep -qE 'rm -rf "\$dest"|rm .*\$dest"?/\*' "$install_commands"; then
  echo "$install_commands must not delete whole command directories." >&2
  exit 1
fi
# Users need a documented way out.
grep -Fq 'npx skills remove' "$repo_root/README.md" \
  || { echo "README.md must document how to uninstall the skills." >&2; exit 1; }
grep -Fq -- 'install-commands.sh --uninstall' "$repo_root/README.md" \
  || { echo "README.md must document removing the command files." >&2; exit 1; }

# --- The bug this repository has already shipped once ------------------------
# Every `quarto use template` / `quarto add` invocation must carry --no-prompt.
# Without it Quarto waits on an interactive trust confirmation and a
# non-interactive agent shell blocks forever, creating no files.
check_no_prompt() {
  file=$1
  # Strip comments so prose about the flag cannot satisfy or trip the check.
  found=$(grep -E '^[[:space:]]*[^#]*quarto (use template|add) ' "$file" || true)
  if [ -n "$found" ]; then
    missing=$(printf '%s\n' "$found" | grep -vF -- '--no-prompt' || true)
    if [ -n "$missing" ]; then
      echo "Commands in $file are missing --no-prompt and will hang:" >&2
      printf '%s\n' "$missing" >&2
      exit 1
    fi
  fi
  printf '%s' "$found"
}

# scaffold.sh is where these commands actually live, so require at least one
# match there; a silently empty result would make this check vacuous.
scaffold_cmds=$(check_no_prompt "$scaffold")
if [ -z "$scaffold_cmds" ]; then
  echo "No quarto use template/add commands found in $scaffold." >&2
  echo "Either the script stopped scaffolding, or this check has gone stale." >&2
  exit 1
fi
# SKILL.md should delegate rather than inline commands, but if prose ever
# reintroduces them they must carry the flag too.
check_no_prompt "$skill_dir/SKILL.md" >/dev/null

# Machine-scoped installs must never escalate unattended. Match sudo only in
# command position, so help text and error messages naming it still pass.
if grep -nE '(^|[;&|]|\$\()[[:space:]]*sudo[[:space:]]' "$scaffold"; then
  echo "$scaffold must never invoke sudo." >&2
  exit 1
fi

# --- No personal data may ship in the package -------------------------------
# The skill is distributed to colleagues, so a real name or address left in it
# would travel to every install. Only these generic placeholders are allowed.
allowed_emails='client@org.se pi@org.se analyst@nbis.se'
found_emails=$(grep -rhoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$repo_root/skills" \
  | grep -vE '@v[0-9]' | sort -u || true)
for e in $found_emails; do
  case " $allowed_emails " in
    *" $e "*) ;;
    *) echo "Unexpected email address in the shipped skill: $e" >&2
       echo "Only generic placeholders may ship: $allowed_emails" >&2
       exit 1 ;;
  esac
done

# Client and PI must never be inferred, the analyst's provenance must be
# disclosed, and no real identity may be written into the shared skill files.
# The email check above is the load-bearing guard; these keep the guidance intact.
grep -Fq 'Where identity may come from' "$skill_dir/SKILL.md" \
  || { echo "SKILL.md must keep the identity-provenance section." >&2; exit 1; }
grep -Fq 'never be written into these skill files' "$skill_dir/SKILL.md" \
  || { echo "SKILL.md must forbid real identities in the skill files." >&2; exit 1; }
# A tested machine returned a git handle and a gmail address; writing those into
# a client deliverable is worse than a TODO, so the plausibility check must stay.
grep -Fq 'only when they look like a work' "$skill_dir/SKILL.md" \
  || { echo "SKILL.md must gate the git identity on looking work-shaped." >&2; exit 1; }
grep -Fq 'clean `first.last` pair' "$skill_dir/SKILL.md" \
  || { echo "SKILL.md must scope email-derived names to clean first.last." >&2; exit 1; }
for wrapper in "$site_skill" "$page_skill"; do
  grep -Fq 'git config' "$wrapper" \
    || { echo "$wrapper must state where the analyst may come from." >&2; exit 1; }
done

# The email check cannot see handles. The repo owner's handle is legitimate in
# the distribution URL and the npx command, but nowhere else -- an example that
# happens to use a real handle would ship it to every colleague.
owner=pyrevo
bad_handle=$(grep -rn "$owner" "$repo_root/skills" \
  | grep -vF "github.com/$owner/nbis-folium-skill" \
  | grep -vF "npx skills add $owner/nbis-folium-skill" || true)
if [ -n "$bad_handle" ]; then
  echo "The owner handle '$owner' appears outside the distribution URL:" >&2
  printf '%s\n' "$bad_handle" >&2
  exit 1
fi

# --- SKILL.md contract ------------------------------------------------------
grep -Fq 'Python `folium`' "$skill_dir/SKILL.md"
grep -Fq 'Needs an agent that can read this skill directory' "$skill_dir/SKILL.md"
# The delegation to the script is the thing that keeps docs and tests aligned.
grep -Fq 'scripts/scaffold.sh' "$skill_dir/SKILL.md"
# The title/subtitle distinction is easy to "simplify" away and silently wrong.
grep -Fq 'subtitle' "$skill_dir/SKILL.md"

# --- Wrapper skills ---------------------------------------------------------
# folium-site and folium-page are thin skills so that agents exposing skills as
# slash commands give /folium-site and /folium-page with no extra install step.
# Each must preselect exactly one template and defer to nbis-folium, so the
# procedure is never duplicated into them.
for wrapper in "$site_skill" "$page_skill"; do
  # skills.sh reads the name from frontmatter; it must match the directory or
  # the slash command comes out under the wrong name.
  expected=$(basename "$(dirname "$wrapper")")
  grep -Fq "name: $expected" "$wrapper" \
    || { echo "$wrapper must declare 'name: $expected'." >&2; exit 1; }
  # The Python-folium collision matters most for description matching.
  grep -Fq 'Python `folium`' "$wrapper" \
    || { echo "$wrapper must keep the Python folium negative trigger." >&2; exit 1; }
  grep -Fq 'nbis-folium' "$wrapper" \
    || { echo "$wrapper must defer to the nbis-folium skill." >&2; exit 1; }
  # A wrapper that inlines the procedure defeats the point.
  if grep -Fq 'quarto use template' "$wrapper"; then
    echo "$wrapper must not inline the scaffold procedure." >&2
    exit 1
  fi
done
grep -Fq 'folium-webpage' "$page_skill"
if grep -Fq -- '--template folium-webpage' "$site_skill"; then
  echo "folium-site must not select the folium-webpage template." >&2
  exit 1
fi

# --- Workflow template ------------------------------------------------------
grep -Fq 'REPORT_DIR: "__REPORT_DIR__"' "$workflow"
grep -Fq 'branches: ["__DEFAULT_BRANCH__"]' "$workflow"
grep -Fq 'quarto render --output-dir "$REPORT_DIR"' "$workflow"

# --- pixi support in the workflow template ----------------------------------
grep -Fq 'USE_PIXI: "false"' "$workflow"
grep -Fq 'pixi run quarto render --output-dir "$REPORT_DIR"' "$workflow"
grep -Fq "hashFiles('pixi.lock') == ''" "$workflow"
# setup-pixi is a 0.x action, where a floating major may break. Require a pin.
if grep -Eq 'prefix-dev/setup-pixi@v0$|prefix-dev/setup-pixi@main' "$workflow"; then
  echo "Pin prefix-dev/setup-pixi to an exact version, not a floating ref." >&2
  exit 1
fi
grep -Eq 'prefix-dev/setup-pixi@v[0-9]+\.[0-9]+\.[0-9]+' "$workflow" \
  || { echo "prefix-dev/setup-pixi must be pinned to an exact version." >&2; exit 1; }
# pixi must replace the per-language setup, not run alongside it.
for step in 'Set up R' 'Set up Python' 'Restore Python dependencies'; do
  line=$(grep -A1 -F "name: $step" "$workflow" | grep 'if:' || true)
  case "$line" in
    *"USE_PIXI != 'true'"*) ;;
    *) echo "Step '$step' must be skipped when USE_PIXI is true." >&2; exit 1 ;;
  esac
done

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

# --- Argument validation in scaffold.sh -------------------------------------
# Cheap, no network: every one of these must be rejected before any file is
# written, so a bad value can never reach sed or the filesystem.
reject() {
  if "$scaffold" --template folium --dir "$tmp_dir/never" "$@" >/dev/null 2>&1; then
    echo "scaffold.sh accepted an argument it must reject: $*" >&2
    exit 1
  fi
  if [ -e "$tmp_dir/never" ]; then
    echo "scaffold.sh created $tmp_dir/never while rejecting: $*" >&2
    exit 1
  fi
}
reject --report-dir /absolute
reject --report-dir ../escape
reject --report-dir -dashy
reject --report-dir ''
reject --branch 'main;rm -rf /'
reject --branch 'a|b'
if "$scaffold" --template bogus --dir "$tmp_dir/never" >/dev/null 2>&1; then
  echo "scaffold.sh accepted an unknown template." >&2
  exit 1
fi

# --- Render fixtures --------------------------------------------------------
if [ "$skip_render" = false ] && command -v quarto >/dev/null 2>&1; then
  # The fixtures no longer vendor their Quarto extensions, so make sure they are
  # present first. On a clean offline checkout this cannot succeed; degrade to
  # static validation with a clear reason rather than failing the whole run.
  if ! "$repo_root/scripts/prepare-fixtures.sh"; then
    echo ""
    echo "Static validation passed; render skipped because the fixture" >&2
    echo "extensions are missing and could not be installed (offline?)." >&2
    exit 0
  fi
  output_dir="$tmp_dir/report"
  (cd "$example" && quarto render index.qmd --output-dir "$output_dir")
  test -f "$output_dir/index.html"
  # A bare `<svg` grep is a tautology here: the logo SVG is a string literal
  # inside the injected script, so it matches even when the logo never renders.
  # Assert the payload AND its injection target, which is what can actually fail.
  grep -Fq 'viewBox="0 0 1497.39 194.27"' "$output_dir/index.html"
  grep -Fq 'class="quarto-title-banner' "$output_dir/index.html"
  # Metadata substitution really resolved, rather than echoing the source YAML.
  grep -Fq 'DEMO-000' "$output_dir/index.html"
  multi_output_dir="$tmp_dir/folium"
  (cd "$multi_example" && quarto render --output-dir "$multi_output_dir")
  test -f "$multi_output_dir/index.html"
  test -f "$multi_output_dir/assets/logos/nbis-scilifelab.webp"
  grep -R -Fq 'assets/logos/nbis-scilifelab.webp' "$multi_output_dir"
  echo "Validation passed; both demo fixtures rendered with Quarto."
else
  echo "Static validation passed; Quarto render skipped."
fi
