---
name: nbis-folium
description: >-
  Scaffold a new NBIS (National Bioinformatics Infrastructure Sweden) project
  report using Roy Francis' folium or folium-webpage Quarto template, with
  GitHub Actions CI/CD and GitHub Pages deployment wired up. Use this skill
  whenever the user wants to start a new NBIS report, mentions folium /
  folium-webpage, asks to publish a Quarto report to GitHub Pages, or needs an
  NBIS-branded analysis/delivery report — even if they don't explicitly say
  "use the nbis-folium skill".
compatibility: >-
  Requires `quarto` (>= 1.8.25), `git`, and a GitHub account with Pages
  enabled. The agent must be able to run shell commands and have network
  access. The final render + deploy runs on GitHub Actions, but Quarto must be
  installed locally to scaffold the project (it pulls the template repo and
  installs extensions). R is optional — only needed if the report uses `{r}`
  chunks.
---

# nbis-folium

Use this when starting a new NBIS bioinformatics project. It scaffolds a Quarto
report repository using Roy Francis' folium template, with CI/CD for GitHub
Pages deployment and proper NBIS branding.

**Upstream templates (Roy Francis):** this skill wraps two open-source Quarto
report templates. Browse them for reference, structure, and the latest version:
- `folium` (multi-page website): <https://github.com/royfrancis/folium>
- `folium-webpage` (single self-contained page): <https://github.com/royfrancis/folium-webpage>

Both are released under CC-BY-NC-SA 4.0. This skill (and reports it scaffolds)
keep the same license and must attribute Roy Francis. See the distribution
repo's README for full credits.

## Requirements

Before scaffolding, verify the toolchain is present. Run:

```bash
quarto --version   # must be >= 1.8.25
git --version
```

If `quarto` is **not found**, stop and tell the user to install it first:
<https://quarto.org/docs/get-started/> (or `brew install quarto` / `conda
install -c conda-forge quarto`). Do not try to hand-write the template files —
`quarto use template` and `quarto add` pull Roy's template repo, SCSS,
`_extensions/`, `assets/` and install the required extensions, which cannot be
reproduced reliably by writing a `.qmd` by hand. The agent can proceed once
Quarto is available. (Git and network access are also required.)

**Install scope (for local testing before GitHub Actions):** the scaffold and
the local `quarto render` only need Quarto on the machine — it does **not** have
to be inside the project. Choose one:
- **Globally** (recommended for simplicity): install Quarto system-wide as above
  (`brew install quarto`, the official installer, or `conda install -c
  conda-forge quarto`). Then run `quarto render` from the project directory.
- **Locally / in an isolated environment**: if the user prefers isolation (e.g.
  to match the CI runner or avoid touching system packages), put Quarto in a
  `conda` env (`conda create -n nbis python=3.12 && conda install -c
  conda-forge quarto -n nbis`, then `conda activate nbis`). Alternatively
  download the standalone Quarto binary and add it to `PATH` for just that
  shell. Activate/open that environment before running `quarto render` so the
  local test mirrors the Actions runner. (Note: Quarto is **not** a PyPI
  package, so it cannot be `pip install`ed into a Python venv — use conda or the
  standalone binary.)

Either way, the final **render + deploy runs on GitHub Actions** (the workflow
installs Quarto itself via `quarto-dev/quarto-actions/setup@v2`), so a local
install is only for the user to preview the report before pushing — it is
optional. R is only needed locally if the report uses `{r}` chunks (the workflow
installs R automatically when `NEEDS_R` is `true`).

## Agent compatibility

- **Agents with a `skill` tool** (e.g. OpenCode, Claude Code / Codex with skills
  enabled): load this skill and read the template files from this skill's
  `templates/` directory as instructed below.
- **Agents without a `skill` tool**: you can still follow this skill as a plain
  prompt. The workflow below is written so that any agent can execute it by
  creating the listed files and running the listed commands. The contents of
  `templates/deploy-pages.yml` and `templates/include_logo.html` are reproduced
  inline under "Reference files" at the bottom of this document, so you do not
  need tool access to use them.

## Workflow

### 1. Ask the user

- **Which template**: `folium` (multi-page website) or `folium-webpage`
  (single self-contained HTML page)
- **Project details**: NBIS ID, client, PI, analyst, project title
- **Report output directory**: where the rendered report is written and uploaded
  to GitHub Pages (default `report`). Examples: `report`, `docs`, `_site`.
- **R support**: does the report contain R code chunks (reading CSV, ggplot,
  etc.)? Most NBIS reports do, so default **yes**. Choose **no** only for a
  pure-Python or markdown report with no R. (Default: yes.)

### 2. Scaffold with Quarto

These `quarto use template` commands pull Roy Francis' template repos from
GitHub (see the "Upstream templates" note above for the browsable URLs):

```bash
cd <project-directory>
quarto use template royfrancis/folium          # multi-page website
# or
quarto use template royfrancis/folium-webpage # single self-contained page
```

### 3. Install Quarto extensions

```bash
quarto add quarto-ext/fontawesome
quarto add mcanouil/quarto-collapse-output@1.4.0
quarto add royfrancis/quarto-accordion
```

### 4. Customise project metadata

- **folium (multi-page)**: edit the `nbis:` block in `_quarto.yml` with the
  NBIS metadata (id, client, PI, analyst, project title, date).
- **folium-webpage (single-page)**: edit the `nbis:` block in the `index.qmd`
  front matter with the same metadata.

Minimal `nbis:` block to set (same shape in both files):

```yaml
nbis:
  id: "NBIS-ID"          # e.g. TEST-001
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

Also set `title` / `subtitle` in `index.qmd` (webpage) or the site title in
`_quarto.yml` (multi-page) to the project title.

Note: both templates already include the Completion section (Data responsibility
+ Acknowledgments) — inline at the end of `index.qmd` for folium-webpage, and as
a `completion.qmd` chapter in `_quarto.yml` nav for folium. No action needed.

### 5. Add CI/CD for GitHub Pages

Create `.github/workflows/deploy-pages.yml` using the content from this skill's
`templates/deploy-pages.yml` (also reproduced under "Reference files" below).
This workflow renders the Quarto report and deploys it to GitHub Pages.

The template uses the placeholder `__REPORT_DIR__` for the output directory.
Replace it with the directory the user chose in step 1 (default `report`). It
appears in two places: the render command (`quarto render --output-dir
__REPORT_DIR__`) and the uploaded artifact path (`path: __REPORT_DIR__`).
Using `--output-dir` makes the workflow work for **both** folium templates.

The workflow also has an `NEEDS_R` environment variable (default `"true"`).
If the user chose **no R support** in step 1, set it to `"false"` so the runner
skips installing R — this is the normal case for pure-Python / markdown
reports. NBIS reports that read CSV or run ggplot in `{r}` chunks must keep it
`"true"`.

### 6. Fix standalone logo rendering

Replace `assets/include_logo.html` with the version from this skill's
`templates/include_logo.html` (reproduced under "Reference files" below).

**Why this matters (gotcha):** the NBIS SciLifeLab logo must be **inlined as
SVG markup** in `include_logo.html`. Do NOT reference it as an external file
(`assets/logos/nbis-scilifelab.svg`) and do NOT use a base64 data URI:

- An external `src` breaks on deploy: `quarto render` with `embed-resources:
  true` only copies/inlines files that are *statically* referenced. The logo
  `<img>` is created by JavaScript at runtime, so Quarto never sees it and the
  file is absent from the published site → broken-image icon. (Roy's own
  template uses a file path, but that only works because his site is served
  with the assets folder present; a scaffolded/deployed report is not.)
- A base64 data URI of the viewBox-only SVG renders as a black box in several
  browsers.

The inlined-SVG approach renders everywhere with no external dependency. Copy
the file verbatim — the SVG is long, do not retype it.

### 7. Inform the user

Tell the user to enable GitHub Pages in the repo **Settings → Pages → Source:
"GitHub Actions"**. The first deployment happens automatically on push to
`main`.

## Reference files

### templates/deploy-pages.yml

```yaml
name: Deploy report to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      # Set to "false" for pure-Python / markdown reports that contain no R chunks.
      NEEDS_R: "true"
    steps:
      - uses: actions/checkout@v4

      - name: Set up R
        if: ${{ env.NEEDS_R == 'true' }}
        uses: r-lib/actions/setup-r@v2

      - name: Install R packages
        if: ${{ env.NEEDS_R == 'true' }}
        run: |
          install.packages(c("knitr", "rmarkdown"))
        shell: Rscript {0}

      - name: Set up Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Render report
        run: quarto render --output-dir __REPORT_DIR__

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: __REPORT_DIR__

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### templates/include_logo.html

Inlines the NBIS SciLifeLab logo as SVG markup (no external `src`, no data
URI) so it renders correctly in the deployed/standalone report. Copy the full
content from this skill's `templates/include_logo.html` into
`<project>/assets/include_logo.html`. (The SVG is long; do not retype it — copy
the file verbatim. See step 6 for why an external file or data URI fails.)
