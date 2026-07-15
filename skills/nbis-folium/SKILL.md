---
name: nbis-folium
description: Scaffold a new NBIS project report using the folium or folium-webpage Quarto template with GitHub Actions CI/CD and GitHub Pages deployment
---

# nbis-folium

Use this when starting a new NBIS bioinformatics project. It scaffolds a Quarto
report repository using Roy Francis' folium template, with CI/CD for GitHub
Pages deployment and proper NBIS branding.

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

### 2. Scaffold with Quarto

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

### 5. Add CI/CD for GitHub Pages

Create `.github/workflows/deploy-pages.yml` using the content from this skill's
`templates/deploy-pages.yml` (also reproduced under "Reference files" below).
This workflow renders the Quarto report and deploys it to GitHub Pages.

The template uses the placeholder `__REPORT_DIR__` for the output directory.
Replace it with the directory the user chose in step 1 (default `report`). It
appears in two places: the render command (`quarto render --output-dir
__REPORT_DIR__`) and the uploaded artifact path (`path: __REPORT_DIR__`).
Using `--output-dir` makes the workflow work for **both** folium templates.

### 6. Fix standalone logo rendering

Replace `assets/include_logo.html` with the version from this skill's
`templates/include_logo.html` (reproduced under "Reference files" below). It
embeds the NBIS logo as a base64 data URI so the logo renders correctly even in
standalone HTML output.

### 7. Inform the user

Tell the user to enable GitHub Pages in the repo **Settings → Pages → Source:
"GitHub Actions"**. The first deployment happens automatically on push to
`main`.

### 8. Write AGENTS.md

Create `AGENTS.md` in the project root with:

- The project's NBIS ID, client, PI, analyst
- Which folium template was chosen
- Key file locations (`_quarto.yml` or `index.qmd`, `assets/`,
  `.github/workflows/`)
- Rendering command: `quarto render --output-dir <dir>` (output goes to
  `<dir>/`; default `report/`)
- Reminder that R code chunks need `{r}` and require knitr/rmarkdown on the
  runner

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
    steps:
      - uses: actions/checkout@v4

      - name: Set up R
        uses: r-lib/actions/setup-r@v2

      - name: Install R packages
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

The file embeds the NBIS logo as a base64 data URI. Copy the full content from
this skill's `templates/include_logo.html` into
`<project>/assets/include_logo.html`. (The data URI is long; do not retype it —
copy the file verbatim.)
