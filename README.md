# nbis-folium-skill

A skill for coding agents that scaffolds an [NBIS](https://nbis.se) project
report using Roy Francis' [folium](https://github.com/royfrancis/folium)
Quarto template, with GitHub Pages publishing wired up automatically.

The skill asks which report style you want, fills in the project metadata, and
sets up everything needed to publish the report to GitHub Pages with one push.

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

## License

MIT — see [LICENSE](LICENSE).
