---
name: nbis-folium
description: >-
  Scaffold and configure an NBIS (National Bioinformatics Infrastructure Sweden)
  bioinformatics project report with Roy Francis's `folium` or
  `folium-webpage` Quarto templates, including validated metadata, a
  standalone-logo fix, and GitHub Pages deployment. Use for a new NBIS report
  or specifically for these Roy Francis Quarto templates. Do not use for the
  Python `folium` mapping library, Leaflet maps, marker clusters, GIS, or
  general geospatial visualization.
---

# NBIS Folium report scaffolder

Create an NBIS-branded Quarto report from Roy Francis's `folium` multi-page
template or `folium-webpage` single-page template.

The mechanical half of this job lives in `scripts/scaffold.sh`. Call it rather
than reproducing its steps: the script is what the repository's integration test
exercises, so anything you re-derive by hand is untested. Your job is the half a
script cannot do — choosing the template, collecting metadata, editing YAML in
place, and deciding whether a directory is safe to touch.

Read [references/compatibility.md](references/compatibility.md) before
scaffolding and [references/licensing.md](references/licensing.md) before
redistributing a generated report.

## Required capabilities

Needs an agent that can read this skill directory (`scripts/`, `templates/`) and
run shell commands, plus Quarto, Git, and network access. It is **not** a
self-contained pasted prompt: the corrected logo and the scaffold script are
files here.

## Aim for zero questions

Invoked through `/folium-site` or `/folium-page` the template is already chosen.
Do not re-ask it, and do not ask for anything the invocation already answered.
If the target directory is unambiguous and Quarto is present, scaffold without
stopping to confirm.

Two things legitimately interrupt that, and nothing else should:

**Metadata that cannot be invented.** NBIS ID, client, PI, and analyst details.
Ask for these in one batched question, not an interrogation. If the user would
rather not answer yet, scaffold with explicit `TODO` placeholders and list them
at the end. Never fabricate a name, an email address, or an NBIS ID — a wrong
PI address on a delivered report is worse than a visible `TODO`.

**A directory that is not empty.** Never merge into existing work silently.

## Dependency tiers

Treat these differently; they are not the same kind of "missing dependency".

| Tier | Examples | Behaviour |
| --- | --- | --- |
| Project-scoped | Quarto extensions | Install unattended, no prompt |
| Project-scoped | R/Python packages via `renv`/venv inside the project | Install unattended |
| Machine-scoped | Quarto, R, Python runtimes | Gated, **required** — aborts when absent |
| Machine-scoped | `gh` | Gated, **optional** — warns and continues |

`scripts/scaffold.sh` handles the first tier itself.

`gh` is optional because the scaffold is entirely correct without it; its only
role is enabling GitHub Pages from the terminal (step 7). Missing it costs the
user one click in Settings, so refusing to scaffold over it would be worse than
carrying on with a clear note.

For machine-scoped tools the script detects what is missing and prints the exact
install command. Pass `--install-deps` only when the user has actually asked for
missing tools to be installed — a bare `/folium-page` is not that consent. The
script never runs `sudo` unattended even with the flag; if the only route needs
elevation it prints the command and stops. On a shared or HPC system, suggest
looking for a module or conda package before any install.

## 1. Inspect the target

Check the target directory, `git status --short`, and any existing Quarto config
or Pages workflow. Scaffold only into an empty or non-existent directory. If the
target is already a project or holds unrelated uncommitted work, show what you
propose to change and ask first.

## 2. Settle the settings

- template: `folium` (multi-page) or `folium-webpage` (single page);
- target directory;
- NBIS ID, title, client, PI, analyst details;
- output directory — default `docs` for `folium` (matching upstream
  `project.output-dir`), `report` for `folium-webpage`, which has no project
  block;
- deployment branch (default: current branch, or `main` for a new repository);
- whether the report executes R and/or Python code.

The script validates the output directory and branch: they must be non-empty
relative paths matching `^[A-Za-z0-9._/-]+$`, with no absolute paths, no `..`
segments, no leading `-`, and no newlines. Do not pre-format or quote them
yourself, and do not interpolate them into a shell command.

## 3. Scaffold

```bash
<skill-dir>/scripts/scaffold.sh --template folium --dir <target> \
  --report-dir <dir> --branch <branch>
```

`<skill-dir>` is this skill's own installed directory, which is not your working
directory — resolve it from the path you loaded `SKILL.md` from and pass it
absolutely. `--dir` may be relative to the user's cwd.

One command does all of the deterministic work: scaffolds the upstream template
with `--no-prompt`, verifies the resulting layout, installs the three extensions
if absent, applies the standalone-logo fix for `folium-webpage`, aligns
`project.output-dir`, writes `.gitignore`, writes
`.github/workflows/deploy-pages.yml` with placeholders substituted, and renders
once to verify.

`--no-prompt` is not optional tidiness — it is why this is a script. Without it
Quarto waits on an interactive trust confirmation and a non-interactive agent
shell blocks forever, creating no files.

If the script reports a layout mismatch, that is a compatibility failure against
a changed upstream template. Stop and say so. Do not guess replacement paths or
rebuild the template by hand.

## 4. Write the metadata

The script deliberately leaves this to you, because it needs judgement and must
never be invented.

- In `folium`, update the existing `nbis:` mapping in `_quarto.yml`.
- In `folium-webpage`, update the existing `nbis:` mapping in the `index.qmd`
  front matter.

Preserve all unrelated configuration, quote every user-provided scalar, write
UTF-8, and re-validate the YAML afterwards. The shape below is an illustration,
not permission to replace the file:

```yaml
nbis:
  id: "NBIS-ID"
  client:
    name: "Client Name"
    email: "client@org.se"
    org: "Client Organisation"
  pi:
    name: "PI Name"
    email: "pi@org.se"
  analyst:
    name: "Analyst Name"
    email: "analyst@nbis.se"
```

**The report title goes in `subtitle`, not `title`.** Both templates ship
`title: "NBIS support {{< meta nbis.id >}}"`, deriving the heading from
`nbis.id`; overwriting it breaks that link. `subtitle` holds the human-readable
project title (upstream placeholder: `"Project title"`). Neither template has a
`site-title`. For `folium` you may also update `website.description` and
`website.site-url` in `_quarto.yml`.

## 5. Configure reproducible dependencies

Pick one of two strategies and declare it in the workflow truthfully. All three
flags default to `"false"`, and the workflow fails deliberately when a runtime is
enabled without its lockfile rather than deploying something misleading.

**Per-language.** Set `NEEDS_R` and/or `NEEDS_PYTHON`. For R, create and commit
`renv.lock`; never hardcode an assumed package list. For Python, commit
`requirements.txt` or make the project installable via `pyproject.toml`.

**pixi.** Set `USE_PIXI: "true"` and commit `pixi.lock`. This covers R and Python
together and replaces the per-language setup: the workflow skips `setup-r` and
`setup-python` entirely and renders with `pixi run quarto render`, so the pixi
environment is active. Quarto still comes from `quarto-actions/setup` — `pixi
run` prepends its environment to `PATH` but inherits the rest, so both are found.

If a project uses pixi, prefer `USE_PIXI` over the per-language flags. Setting
both is contradictory: pixi wins and the others are ignored.

`environment.yml` (conda) still needs project-specific CI changes and the bundled
workflow does not support it unadapted.

## 6. Verify and report

Re-render if you changed anything after the script ran:

```bash
quarto render --output-dir "$REPORT_DIR"
```

Confirm HTML exists and no workflow placeholders remain. Check metadata
substitution by finding the configured NBIS ID **in the rendered HTML**, not by
re-reading the source YAML.

For `folium-webpage`, verifying the logo needs two assertions. Grepping the
output for `<svg` proves nothing — the SVG is a string literal inside the
injected `<script>`, so it matches whether or not the logo appears. Check that

- the payload reached the output (`viewBox="0 0 1497.39 194.27"`), and
- its injection target exists (`class="quarto-title-banner`).

The second is the one that can fail: `insertImage` inserts into
`.quarto-title-banner`, so if `title-block-banner` ever leaves the front matter
the logo silently vanishes while an `<svg` grep still passes.

Then report files created or changed, any backups, template and Quarto versions,
dependency strategy, and one precise status: **scaffolded locally**, **rendered
locally**, **workflow configured**, **pushed**, **deployment running**,
**deployment successful**, or **Pages site verified**.

Never publish, commit, or push without explicit approval.

## 7. Enable GitHub Pages

A workflow file is not proof that a site was published. Until Pages is switched
to the GitHub Actions source, every run builds fine and deploys nowhere: the
`deploy-pages` step fails with a 404 in the Actions log. Nobody is prompted, and
no email says "authenticate" — so this step is easy to miss and worth being
explicit about.

With `gh` installed and authenticated, this can be done without leaving the
terminal. It creates a public site, so treat it as outward-facing and get
explicit approval first:

```bash
gh api -X POST "repos/<owner>/<repo>/pages" -f build_type=workflow
```

It needs admin rights on the repository, and returns 409 if Pages is already
configured — treat that as success, not failure. Check the current state first
with `gh api "repos/<owner>/<repo>/pages"`; `"build_type": "workflow"` means it
is already correct and nothing needs doing.

If `gh` is missing or unauthenticated, say plainly that the user must set
**Settings → Pages → Source: GitHub Actions** by hand, and report the status as
**workflow configured** rather than implying a live site.

Two caveats worth passing on: Pages on a **private** repository requires a paid
GitHub plan, and the first deployment can take a few minutes to become
reachable. Verify the real URL before claiming **Pages site verified**.
