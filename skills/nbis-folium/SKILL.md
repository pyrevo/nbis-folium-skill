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
template or `folium-webpage` single-page template. The skill configures project
metadata, reproducible code dependencies, local validation, and GitHub Pages.

Read [references/compatibility.md](references/compatibility.md) before
scaffolding and [references/licensing.md](references/licensing.md) before
redistributing a generated report.

## Required capabilities

This skill requires an agent that can read the installed skill directory,
including `templates/`, and execute shell commands. It also requires Git,
Quarto, and network access while fetching upstream templates and extensions.
It is **not** a self-contained pasted prompt because the corrected logo is in
`templates/include_logo.html` and must be copied verbatim.

Do not install system software or publish, commit, or push without the user's
explicit approval.

## 1. Inspect the target and tools

Run:

```bash
quarto --version
git --version
```

If Quarto is unavailable, stop and direct the user to
<https://quarto.org/docs/get-started/>. Do not recreate the upstream template
by hand.

Before changing files, inspect the target directory, `git status --short`, any
existing Quarto configuration, and existing Pages workflows. Scaffold only
into an empty directory by default. If the target is already a project or has
unrelated uncommitted work, show the proposed changes and ask before merging or
overwriting anything.

## 2. Collect settings

Obtain:

- template: `folium` (multi-page) or `folium-webpage` (single page);
- target directory;
- NBIS ID, title, client, PI, and analyst details;
- output directory (default `report`);
- whether the report executes R and/or Python code;
- dependency files: `renv.lock` for R, and `requirements.txt` or
  `pyproject.toml` for Python;
- deployment branch (default: current branch; `main` for a new repository).

Unknown metadata must stay an explicit placeholder. Never invent contact
details. Accept an output directory only when it is a non-empty relative path
matching `^[A-Za-z0-9._/-]+$`; reject absolute paths, `..` segments, paths
beginning with `-`, and newline characters.

## 3. Scaffold and inspect the upstream result

From the empty target directory, run exactly one command:

```bash
quarto use template royfrancis/folium
# or
quarto use template royfrancis/folium-webpage
```

Inspect the generated files before editing. `folium` must contain `_quarto.yml`
and its configured `website.navbar.logo`; `folium-webpage` must contain
`index.qmd` and `assets/include_logo.html`. If this structure differs, stop
with a compatibility error rather than guessing paths.

Install only extensions absent from the generated project, using the versions
in `references/compatibility.md`:

```bash
quarto add quarto-ext/fontawesome
quarto add mcanouil/quarto-collapse-output@1.4.0
quarto add royfrancis/quarto-accordion
```

## 4. Update metadata safely

- In `folium`, update the existing `nbis:` mapping in `_quarto.yml`.
- In `folium-webpage`, update the existing `nbis:` mapping in `index.qmd` YAML
  front matter.

Preserve all unrelated configuration. Quote every user-provided YAML scalar,
write UTF-8, and validate YAML/front matter before rendering. The example below
illustrates the shape only; it is not permission to replace the whole file.

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

Set the report title in the template's existing title/site-title field.

## 5. Configure reproducible dependencies

For R code, create and commit `renv.lock`; do not hardcode an assumed package
list. For Python code, commit `requirements.txt` or use an installable project
with `pyproject.toml`. `environment.yml` needs a project-specific CI setup and
is not supported by the bundled workflow without adapting it.

Set `NEEDS_R` and `NEEDS_PYTHON` in the workflow truthfully. Their default is
`"false"`. The workflow deliberately fails when a selected runtime lacks its
dependency manifest, preventing a misleading successful deployment.

## 6. Apply the standalone-logo fix (folium-webpage only)

For `folium-webpage`, compare `assets/include_logo.html` with
`templates/include_logo.html`. If the destination has user changes, show a diff
or create a backup before replacement. Copy the bundled file exactly; do not
retype the SVG.

It contains inline SVG markup. Do not call it a base64 data URI and do not
replace it with an external image path: the runtime-created image is not a
static resource that Quarto can reliably embed.

Current `folium` scaffolds use the configured `website.navbar.logo` asset and
do not create `assets/include_logo.html`. Do not add or overwrite that file in
`folium` projects unless a tested future upstream layout introduces it.

## 7. Configure GitHub Pages

Copy `templates/deploy-pages.yml` to `.github/workflows/deploy-pages.yml`.
Replace only these placeholders after validation:

- `__DEFAULT_BRANCH__` with the selected branch;
- `__REPORT_DIR__` with the validated output directory.

The output directory is passed through the quoted `$REPORT_DIR` environment
variable. Do not inject a user value directly into a shell command. Merge with
an existing Pages workflow only after review; never silently overwrite it.

## 8. Validate and report

Run:

```bash
quarto render --output-dir "$REPORT_DIR"
```

Check that HTML output exists, metadata is present, and no workflow placeholders
remain. For `folium-webpage`, also verify the rendered report contains the
inline NBIS SVG. Then report the files created/changed, any backups, template
and Quarto versions, dependency strategy, and one precise status: **scaffolded
locally**, **rendered locally**, **workflow configured**, **pushed**,
**deployment running**, **deployment successful**, or **Pages site verified**.

For GitHub Pages, the user must set **Settings → Pages → Source: GitHub
Actions**. A workflow file alone is not proof that a site has been published.
