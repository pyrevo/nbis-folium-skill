#!/usr/bin/env sh
# Deterministic scaffolding for an NBIS folium report.
#
# This is the single source of truth for the mechanical half of the skill.
# SKILL.md tells the agent to call this script, and the repository's
# integration test calls the same script, so the documented procedure and the
# tested procedure cannot drift apart. (They previously did: the documented
# `quarto` commands lacked --no-prompt and deadlocked, while CI passed because
# it re-implemented the steps with the flag.)
#
# Deliberately NOT this script's job:
#   - writing project metadata (NBIS ID, client, PI, analyst) -- needs judgement
#     and must never be invented, so the agent edits YAML in place afterwards;
#   - git init / commit / push -- outward-facing, needs explicit approval.
set -eu

usage() {
  cat <<'EOF'
Usage: scaffold.sh --template <folium|folium-webpage> --dir <path> [options]

Required:
  --template <name>    folium (multi-page website) or folium-webpage (single page)
  --dir <path>         target directory; must be empty or not yet exist

Options:
  --report-dir <path>  render output directory
                       (default: docs for folium, report for folium-webpage)
  --branch <name>      deployment branch for the Pages workflow (default: main)
  --install-deps       permit installing missing machine-scoped tools.
                       Never runs sudo; prints the command and stops instead.
  --skip-render        skip the verification render
  -h, --help           show this help

Exit codes: 0 ok, 1 environment or verification failure, 2 usage error.
EOF
}

fail() {
  echo "scaffold.sh: $1" >&2
  exit "${2:-1}"
}

template=""
target=""
report_dir=""
report_dir_set=false
branch="main"
install_deps=false
skip_render=false

while [ $# -gt 0 ]; do
  case "$1" in
    --template) [ $# -ge 2 ] || fail "--template needs a value" 2; template=$2; shift 2 ;;
    --dir)      [ $# -ge 2 ] || fail "--dir needs a value" 2;      target=$2;   shift 2 ;;
    --report-dir) [ $# -ge 2 ] || fail "--report-dir needs a value" 2; report_dir=$2; report_dir_set=true; shift 2 ;;
    --branch)   [ $# -ge 2 ] || fail "--branch needs a value" 2;   branch=$2;   shift 2 ;;
    --install-deps) install_deps=true; shift ;;
    --skip-render)  skip_render=true;  shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown argument: $1" 2 ;;
  esac
done

case "$template" in
  folium|folium-webpage) ;;
  "") usage >&2; fail "--template is required" 2 ;;
  *) fail "unknown template: $template (expected folium or folium-webpage)" 2 ;;
esac
[ -n "$target" ] || { usage >&2; fail "--dir is required" 2; }

# Upstream folium ships `project.output-dir: docs`; folium-webpage is a single
# document with no project block. Defaulting per template keeps a bare local
# `quarto render` writing to the same tree as CI.
if [ "$report_dir_set" = false ]; then
  if [ "$template" = folium ]; then report_dir=docs; else report_dir=report; fi
fi

# Reject anything that could escape the project or be read as a shell option.
# The character class excludes | so it is safe as a sed delimiter below.
validate_rel_path() {
  label=$1
  value=$2
  [ -n "$value" ] || fail "$label must not be empty" 2
  [ "$(printf '%s' "$value" | wc -l | tr -d ' ')" = 0 ] \
    || fail "$label must not contain a newline" 2
  case "$value" in
    /*)   fail "$label must be relative, got: $value" 2 ;;
    -*)   fail "$label must not begin with '-', got: $value" 2 ;;
    *..*) fail "$label must not contain '..', got: $value" 2 ;;
  esac
  printf '%s' "$value" | grep -Eq '^[A-Za-z0-9._/-]+$' \
    || fail "$label must match ^[A-Za-z0-9._/-]+\$, got: $value" 2
}

validate_rel_path "--report-dir" "$report_dir"
validate_rel_path "--branch" "$branch"

skill_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
workflow_template="$skill_dir/templates/deploy-pages.yml"
logo_template="$skill_dir/templates/include_logo.html"
test -f "$workflow_template" || fail "missing $workflow_template"
test -f "$logo_template" || fail "missing $logo_template"

# --- Tier 3 dependencies: machine-scoped, gated ------------------------------
# Project-scoped dependencies (Quarto extensions) install unattended further
# down. Machine-scoped tools are a bigger blast radius than a scaffold command
# implies, and a half-finished system install is expensive to unpick, so they
# need either --install-deps or a human running one printed command.
#
# Required tools abort when missing. Optional ones only warn: the scaffold is
# still correct without them, so refusing to run would be worse than degrading.

# Prints a non-sudo install command for a tool, or nothing if none is known.
# Only Homebrew qualifies today; apt and dnf both need elevation, and this
# script never escalates unattended.
install_command_for() {
  case "$(uname -s)" in
    Darwin)
      command -v brew >/dev/null 2>&1 || return 0
      case "$1" in
        quarto) echo "brew install --cask quarto" ;;
        gh)     echo "brew install gh" ;;
      esac
      ;;
    *) ;;
  esac
}

# require_tool <name> <required|optional> <manual-url> [why-it-is-needed]
require_tool() {
  tool=$1
  requirement=$2
  manual_url=$3
  purpose=${4:-}

  command -v "$tool" >/dev/null 2>&1 && return 0

  cmd=$(install_command_for "$tool")

  if [ -n "$cmd" ] && [ "$install_deps" = true ]; then
    echo "$tool is missing. Installing with: $cmd"
    # shellcheck disable=SC2086
    if $cmd; then
      command -v "$tool" >/dev/null 2>&1 && return 0
      echo "warning: $tool still not on PATH; open a new shell and retry" >&2
    else
      echo "warning: the install command for $tool failed" >&2
    fi
    [ "$requirement" = optional ] && return 0
    fail "$tool is required and could not be installed"
  fi

  # Not installing: explain, then either stop or carry on.
  if [ "$requirement" = required ]; then
    echo "$tool is required but not installed." >&2
  else
    echo "note: $tool is not installed${purpose:+ ($purpose)}." >&2
  fi
  if [ -n "$cmd" ]; then
    echo "  install with: $cmd" >&2
    echo "  or pass --install-deps to let this script run it." >&2
  else
    echo "  no unprivileged install route was detected on this platform." >&2
    echo "  This script never runs sudo unattended, so install it yourself:" >&2
    echo "    $manual_url" >&2
    echo "  On a shared or HPC system, look for a module or conda package first." >&2
  fi
  [ "$requirement" = required ] && exit 1
  return 0
}

require_tool quarto required "https://quarto.org/docs/get-started/"
# gh is optional: without it, enabling GitHub Pages stays a manual click in
# Settings -> Pages. Everything else works.
require_tool gh optional "https://cli.github.com/" \
  "GitHub Pages must then be enabled by hand in Settings -> Pages"

command -v git >/dev/null 2>&1 \
  || echo "scaffold.sh: warning: git not found; publishing steps will not work" >&2

quarto_version=$(quarto --version)

# --- Target directory --------------------------------------------------------
if [ -e "$target" ]; then
  test -d "$target" || fail "--dir exists but is not a directory: $target"
  if [ -n "$(ls -A "$target" 2>/dev/null || true)" ]; then
    fail "refusing to scaffold into a non-empty directory: $target
Inspect it and merge by hand, or choose an empty directory."
  fi
fi
mkdir -p "$target"
target_abs=$(CDPATH= cd -- "$target" && pwd)

cd "$target_abs"

# --- Scaffold ----------------------------------------------------------------
# --no-prompt is mandatory: without it Quarto waits on an interactive trust
# confirmation and a non-interactive shell blocks forever, creating no files.
echo "Scaffolding $template into $target_abs"
quarto use template "royfrancis/$template" --no-prompt

# Treat an unexpected layout as a compatibility failure, never as an invitation
# to guess replacement paths.
if [ "$template" = folium ]; then
  test -f _quarto.yml || fail "upstream folium layout changed: no _quarto.yml"
  grep -Fq 'logo:' _quarto.yml || fail "upstream folium layout changed: no navbar logo"
else
  test -f index.qmd || fail "upstream folium-webpage layout changed: no index.qmd"
  test -f assets/include_logo.html \
    || fail "upstream folium-webpage layout changed: no assets/include_logo.html"
fi

# --- Tier 1 dependencies: project-scoped, always unattended ------------------
# collapse-output and fontawesome are referenced by both templates' front
# matter and are required. accordion is for authoring convenience.
add_extension() {
  dir=$1
  ref=$2
  if [ -d "$dir" ]; then
    echo "  extension already present: $ref"
  else
    quarto add "$ref" --no-prompt
  fi
}

# All three are pinned. Tag formats differ between the repos -- quarto-ext uses
# a v prefix, mcanouil and royfrancis do not -- and a wrong prefix fails the add
# outright rather than falling back to the latest release.
add_extension _extensions/quarto-ext/fontawesome quarto-ext/fontawesome@v1.3.0
add_extension _extensions/mcanouil/collapse-output mcanouil/quarto-collapse-output@1.4.0
add_extension _extensions/royfrancis/accordion royfrancis/quarto-accordion@1.1.2

# --- Standalone-logo fix (folium-webpage only) -------------------------------
# folium renders its navbar logo as a real asset and needs no fix; only the
# single-page template must inline the logo to survive embed-resources.
if [ "$template" = folium-webpage ]; then
  cp "$logo_template" assets/include_logo.html
  echo "  applied standalone-logo fix to assets/include_logo.html"
fi

# --- Output directory --------------------------------------------------------
# Keep _quarto.yml and the workflow pointing at the same tree.
if [ "$template" = folium ]; then
  sed -i.bak "s|^  output-dir: .*|  output-dir: $report_dir|" _quarto.yml
  rm -f _quarto.yml.bak
  grep -Fq "  output-dir: $report_dir" _quarto.yml \
    || fail "could not set project.output-dir in _quarto.yml"
fi

# Rendered output is a build artifact.
if [ ! -f .gitignore ] || ! grep -Fqx "/$report_dir/" .gitignore; then
  {
    echo "/$report_dir/"
    echo "/.quarto/"
    echo "**/*.quarto_ipynb"
  } >> .gitignore
fi

# --- GitHub Pages workflow ---------------------------------------------------
# | cannot appear in either value (see validate_rel_path), so it is a safe
# sed delimiter and no user value reaches a shell command.
mkdir -p .github/workflows
sed -e "s|__DEFAULT_BRANCH__|$branch|g" -e "s|__REPORT_DIR__|$report_dir|g" \
  "$workflow_template" > .github/workflows/deploy-pages.yml
if grep -Fq '__DEFAULT_BRANCH__' .github/workflows/deploy-pages.yml \
  || grep -Fq '__REPORT_DIR__' .github/workflows/deploy-pages.yml; then
  fail "workflow placeholders were not fully substituted"
fi

# --- Verification render -----------------------------------------------------
if [ "$skip_render" = false ]; then
  echo "Rendering to verify the scaffold"
  quarto render --output-dir "$report_dir"
  find "$report_dir" -type f -name '*.html' -print -quit | grep -q . \
    || fail "render produced no HTML in $report_dir"
  if [ "$template" = folium ]; then
    test -f "$report_dir/assets/logos/nbis-scilifelab.webp" \
      || fail "navbar logo asset missing from $report_dir"
  else
    # A bare `<svg` grep is a tautology: the logo SVG is a string literal
    # inside the injected script, so it matches even when nothing renders.
    # Assert the payload AND its injection target, which is what can fail.
    grep -R -Fq 'viewBox="0 0 1497.39 194.27"' "$report_dir" \
      || fail "NBIS logo payload missing from rendered output"
    grep -R -Fq 'class="quarto-title-banner' "$report_dir" \
      || fail "no .quarto-title-banner in output; the logo has nowhere to attach"
  fi
fi

cat <<EOF

Scaffolded: $template
Directory:  $target_abs
Output dir: $report_dir
Branch:     $branch
Quarto:     $quarto_version
Workflow:   .github/workflows/deploy-pages.yml

Still to do (not this script's job):
  1. Replace the placeholder nbis: metadata with real values. Never invent
     contact details; leave an explicit TODO where a value is unknown.
  2. Set the project title in "subtitle". Leave "title" as
     "NBIS support {{< meta nbis.id >}}" so the heading tracks nbis.id.
  3. Declare the runtime in the workflow and commit a lockfile:
       - renv.lock for R (NEEDS_R), requirements.txt or pyproject.toml for
         Python (NEEDS_PYTHON);
       - or set USE_PIXI: "true" and commit pixi.lock, which covers both.
  4. Enable Pages: Settings -> Pages -> Source: GitHub Actions.
EOF
