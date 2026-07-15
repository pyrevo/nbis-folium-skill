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
  `templates/deploy-pages.yml`, `templates/include_logo.html` and
  `templates/completion.qmd` are reproduced inline under "Reference files" at the
  bottom of this document, so you do not need tool access to use them.

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

### 4b. Add the Completion section (folium-webpage only)

For **NBIS reports it is good practice to end with a Completion section**
(data responsibility + acknowledgments). The multi-page `folium` template
already ships `completion.qmd` and lists it as the final chapter in
`_quarto.yml`, so **no action is needed for `folium`**.

For the **`folium-webpage`** (single self-contained page) template there is no
completion file, so append the Completion section to the end of `index.qmd`.
Copy the content of this skill's `templates/completion.qmd` (also reproduced
under "Reference files" below) and paste it as the final section of
`index.qmd`. This keeps the single page consistent with the NBIS convention.

(The demo report in this distribution repo intentionally omits the Completion
section; it is only added to real scaffolded projects.)

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

### templates/completion.qmd

The Completion section (Data responsibility + Acknowledgments) appended to the
end of `index.qmd` for the `folium-webpage` template (the multi-page `folium`
template already ships its own `completion.qmd`). Full content:

```markdown
---
title: "Completion"
---

## Data responsibility

The responsibility for data archiving lies with the PI of the project. We do not offer long-term storage or retrieval of data.

- **NBIS & UPPNEX:** We kindly ask that you remove the files from UPPMAX/UPPNEX. The main storage at UPPNEX is optimized for high-speed and parallel access, which makes it expensive and not the right place for longer time archiving. Please consider others by not taking up the expensive space. Please note that UPPMAX is a resource separate from the Bioinformatics Platform, administered by the National Academic Infrastructure for Super­computing in Sweden (NAISS) and NAISS-specific project rules apply to all projects hosted at UPPMAX.
- **Sensitive data:** Please note that special considerations may apply to the human-derived legally considered sensitive personal data. These should be handled according to specific laws and regulations.
- **Long-term backup:** We recommend asking your local IT for support with long-term data archiving. The [Data Office](https://www.scilifelab.se/data/) at SciLifeLab may be of help to discuss other options.

## Acknowledgments

If you are presenting the results in a paper, at a workshop or conference, we kindly ask you to acknowledge us.

- NBIS staff are encouraged to be co-authors when this is merited in accordance to the ethical recommendations for authorship, e.g. [ICMJE recommendations](http://www.icmje.org/recommendations/browse/roles-and-responsibilities/defining-the-role-of-authors-and-contributors.html). If applicable, please include **Name, Surname, National Bioinformatics Infrastructure Sweden, Science for Life Laboratory, Further Affiliations**, as co-author. In other cases, NBIS would be grateful if support by us is acknowledged in publications according to this example:

> "Support by NBIS (National Bioinformatics Infrastructure Sweden) is gratefully acknowledged."

- **UPPMAX** kindly asks you to [acknowledge UPPMAX and NAISS](https://www.uppmax.uu.se/support/faq/general-miscellaneous-faq/acknowledging-uppmax-and-naiss).

- **NGI:** For publications based on data from NGI Sweden, NGI and SciLifeLab should be acknowledged. Instructions are included in the NGI reports as described [here](https://ngisweden.scilifelab.se/resources/getting-started-at-ngi/).
```
