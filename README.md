# nbis-folium-skill

A skill for coding agents that scaffolds an [NBIS](https://nbis.se) project
report using Roy Francis' [folium](https://github.com/royfrancis/folium)
(multi-page website) and
[folium-webpage](https://github.com/royfrancis/folium-webpage)
(single self-contained page) Quarto templates, with GitHub Pages publishing
wired up automatically.

The skill asks which report style you want, safely applies project metadata,
and configures a reproducible GitHub Pages workflow. It never treats a workflow
file as proof that a site has been published.

A live demo of the generated report (built from the real folium-webpage
template, with full NBIS branding) is published here:
<https://pyrevo.github.io/nbis-folium-skill/>

The corresponding multi-page `folium` demo is published at:
<https://pyrevo.github.io/nbis-folium-skill/folium/>

## What it does

- Scaffolds a new report repo from the `folium` (multi-page) or
  `folium-webpage` (single self-contained page) Quarto template
- Installs the required Quarto extensions
- Safely fills in the NBIS metadata (ID, client, PI, analyst, title)
- Adds a GitHub Actions workflow that renders and publishes the report to
  GitHub Pages
- Applies the inline-SVG standalone-logo fix for `folium-webpage` reports

## Two commands

Once installed you get two slash commands, and the only thing you need to decide
is which shape of report you want:

| Command | What you get |
| --- | --- |
| `/folium-site` | Multi-page Quarto **website** (`folium`) — several report pages plus a completion page |
| `/folium-page` | One single self-contained HTML **page** (`folium-webpage`) — travels as a single file |

Both aim for zero questions. If Quarto is installed and the target directory is
clear, the agent scaffolds, installs the extensions, applies the logo fix, writes
the Pages workflow, and renders once to verify — without stopping.

It will interrupt you for exactly two things:

- **Project metadata it cannot invent** — NBIS ID, client, PI, analyst. Asked as
  one batched question. Say "later" and you get explicit `TODO` placeholders and
  a checklist instead; it will never make up a PI's email address.
- **A non-empty target directory** — it refuses to merge into existing work
  silently.

Pass a path directly if you like: `/folium-page ~/projects/nbis-1234`.

### Missing Quarto

Quarto extensions and project-level R/Python dependencies install automatically.
Quarto itself is **not** installed silently — it's a machine-wide change, and a
half-finished system install costs far more to unpick than a three-second
confirmation. If it's missing you get the exact command to run, or you can opt in
explicitly:

```
/folium-site --install-deps
```

Even then it never runs `sudo` unattended: if elevation is the only route it
prints the command and stops. On a shared or HPC system, look for a module or
conda package first.

## Install it

The skill follows the [skills.sh](https://skills.sh) layout, so most agents can
install it with one command. From inside your project (or your agent's skills
directory), run:

```bash
npx skills add pyrevo/nbis-folium-skill
```

Then install the two slash commands. Skills are portable but slash commands are
not — every agent keeps them somewhere different — so a small script places them
for whichever agents you have:

```bash
skills/nbis-folium/scripts/install-commands.sh          # or --dry-run first
```

It writes to `~/.claude/commands`, `~/.config/opencode/command`, and
`~/.codex/prompts`, skipping any agent that isn't installed. Use
`--scope project` to install into the current project instead. Reload your agent
afterwards.

Without the commands the skill still works — just ask for "a new NBIS folium
report" and description-matching will find it. The commands exist so you don't
have to remember a phrasing.

### Manual install

If your agent doesn't support the install command, copy the folder
`skills/nbis-folium/` into your agent's skills directory (for example
`~/.config/opencode/skills/nbis-folium/`), then copy
`skills/nbis-folium/commands/*.md` into wherever it keeps slash commands.

## Requirements

- [Quarto](https://quarto.org) (the bundled example declares >= 1.8.25)
- [Git](https://git-scm.com) and a GitHub account (for publishing)
- The agent needs to be able to run shell commands
- The agent needs filesystem access to the installed skill's `templates/`
  directory; this is not a self-contained pasted prompt

Reports with executable R code should commit an `renv.lock`. Reports with
Python code should commit `requirements.txt` or be installable through
`pyproject.toml`; the deployment workflow restores these dependencies
conditionally. See the skill's compatibility and licensing references for the
upstream-version and attribution policy.

Publishing uses GitHub Pages, so the project must live in a GitHub repository
and Pages must be enabled (Settings → Pages → Source: "GitHub Actions").

## Credits & acknowledgements

This skill is a packaging/wrapper around the excellent NBIS report templates
created by **Roy Francis**:

- [royfrancis/folium](https://github.com/royfrancis/folium) — multi-page
  website template
- [royfrancis/folium-webpage](https://github.com/royfrancis/folium-webpage) —
  single self-contained page template

The skill would not exist without his work. The report templates themselves are
released under **CC-BY-NC-SA** (see the `LICENSE` in each template repo). To
keep the licensing consistent end-to-end, this distribution repo (the skill
packaging) is released under the same **CC-BY-NC-SA 4.0** license.

Built using [Quarto](https://quarto.org/).

Third-party components and branding considerations are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

CC-BY-NC-SA 4.0 — see [LICENSE](LICENSE). This matches the license of the
bundled report templates by Roy Francis. Attribution to Roy Francis is
required, commercial use is not permitted, and derivatives must carry the same
license (share-alike).
