# nbis-folium-skill

A skill for coding agents that scaffolds an [NBIS](https://nbis.se) project
report using Roy Francis' [folium](https://github.com/royfrancis/folium)
(multi-page website) and
[folium-webpage](https://github.com/royfrancis/folium-webpage)
(single self-contained page) Quarto templates, with GitHub Pages publishing
wired up automatically.

The skill asks which report style you want, fills in the project metadata, and
sets up everything needed to publish the report to GitHub Pages with one push.

A live demo of the generated report (built from the real folium-webpage
template, with full NBIS branding) is published here:
<https://pyrevo.github.io/nbis-folium-skill/>

## What it does

- Scaffolds a new report repo from the `folium` (multi-page) or
  `folium-webpage` (single self-contained page) Quarto template
- Installs the required Quarto extensions
- Fills in the NBIS metadata (ID, client, PI, analyst, title)
- Adds a GitHub Actions workflow that renders and publishes the report to
  GitHub Pages
- Embeds the NBIS logo so it renders correctly in standalone HTML

## Install it

The skill follows the [skills.sh](https://skills.sh) layout, so most agents can
install it with one command. From inside your project (or your agent's skills
directory), run:

```bash
npx skills add pyrevo/nbis-folium-skill
```

This drops the skill into your agent's skills folder. After that, ask your agent
to "start a new NBIS folium report" and it will guide you through the steps.

### Manual install

If your agent doesn't support the install command, copy the folder
`skills/nbis-folium/` into your agent's skills directory (for example
`~/.config/opencode/skills/nbis-folium/`).

## Requirements

- [Quarto](https://quarto.org) >= 1.8.25
- [Git](https://git-scm.com) and a GitHub account (for publishing)
- The agent needs to be able to run shell commands

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

## License

CC-BY-NC-SA 4.0 — see [LICENSE](LICENSE). This matches the license of the
bundled report templates by Roy Francis. Attribution to Roy Francis is
required, commercial use is not permitted, and derivatives must carry the same
license (share-alike).
