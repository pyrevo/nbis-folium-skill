# nbis-folium-skill

A skill for coding agents that scaffolds an [NBIS](https://nbis.se) project
report using Roy Francis' [folium](https://github.com/royfrancis/folium)
(multi-page website) and
[folium-webpage](https://github.com/royfrancis/folium-webpage)
(single self-contained page) Quarto templates, with GitHub Pages publishing
wired up automatically.

You pick the report shape by which command you run, then the skill applies your
project metadata safely and configures a reproducible GitHub Pages workflow. It
never treats a workflow file as proof that a site has been published.

A live demo of the generated report (built from the real folium-webpage
template, with full NBIS branding) is published here:
<https://pyrevo.github.io/nbis-folium-skill/>

The corresponding multi-page `folium` demo is published at:
<https://pyrevo.github.io/nbis-folium-skill/folium/>

## What it does

- Scaffolds a new report repo from the `folium` (multi-page) or
  `folium-webpage` (single self-contained page) Quarto template
- Installs the required Quarto extensions, at pinned versions
- Fills in the NBIS metadata (ID, client, PI, analyst) and puts the project
  title in `subtitle`, leaving `title` deriving from the NBIS ID as the
  templates intend
- Adds a GitHub Actions workflow that renders and publishes the report to
  GitHub Pages, supporting `renv`, pip, or `pixi`
- Applies the inline-SVG standalone-logo fix for `folium-webpage` reports
- Renders once to verify before reporting success

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

That installs three skills, and on any agent that exposes skills as slash
commands you immediately have `/folium-site` and `/folium-page`. No second step:

| Skill | Purpose |
| --- | --- |
| `nbis-folium` | The whole procedure, plus the scaffold script and templates |
| `folium-site` | Thin wrapper: preselects the multi-page template |
| `folium-page` | Thin wrapper: preselects the single-page template |

Install just one with `--skill nbis-folium`, or be explicit with `--skill '*'`.

### Agents without skill-backed slash commands

Some agents read commands from their own directory rather than exposing skills
that way. For those, a script copies the two wrappers into place:

```bash
skills/nbis-folium/scripts/install-commands.sh          # or --dry-run first
```

It writes to `~/.claude/commands`, `~/.config/opencode/command`, and
`~/.codex/prompts`, skipping any agent that isn't installed, and reads the
wrapper skills directly so there is only ever one copy of their text. Use
`--scope project` for the current project instead.

Either way the skill also works with no commands at all — just ask for "a new
NBIS folium report" and description-matching will find it.

### Manual install

Copy the three folders under `skills/` into your agent's skills directory (for
example `~/.config/opencode/skills/`).

## Uninstall it

Remove the skills:

```bash
npx skills remove nbis-folium folium-site folium-page
```

If you also ran `install-commands.sh`, remove the command files it copied:

```bash
skills/nbis-folium/scripts/install-commands.sh --uninstall     # or --dry-run
```

That deletes only `folium-site.md` and `folium-page.md` from the agent command
directories, by exact name, and leaves everything else alone. Pass the same
`--scope project` you installed with. Reload your agent afterwards.

Reports you already generated are ordinary Quarto projects and keep working —
nothing in them points back at this skill.

## Requirements

- [Quarto](https://quarto.org) (the bundled example declares >= 1.8.25)
- [Git](https://git-scm.com) and a GitHub account (for publishing)
- The agent needs to be able to run shell commands
- The agent needs filesystem access to the installed skill's `templates/` and
  `scripts/` directories; this is not a self-contained pasted prompt
- Optionally [`gh`](https://cli.github.com/), only to enable GitHub Pages from
  the terminal. Everything works without it.

### Executable code

The deployment workflow restores dependencies conditionally, and fails loudly
rather than deploying a report built without them. Pick one strategy:

| Strategy | Set in the workflow | Commit |
| --- | --- | --- |
| R | `NEEDS_R: "true"` | `renv.lock` |
| Python | `NEEDS_PYTHON: "true"` | `requirements.txt` or `pyproject.toml` |
| pixi (covers both) | `USE_PIXI: "true"` | `pixi.lock` |

`USE_PIXI` takes precedence: it skips the R and Python setup and renders with
`pixi run quarto render`. conda `environment.yml` is not supported without
adapting the workflow.

### Publishing

The project must live in a GitHub repository, and Pages must be pointed at the
Actions source. Until then builds succeed and deploy nowhere, with only a 404 in
the Actions log — nothing prompts you. Either click **Settings → Pages → Source:
GitHub Actions**, or run:

```bash
gh api -X POST "repos/<owner>/<repo>/pages" -f build_type=workflow
```

A 409 means it was already configured. Pages on a private repository needs a
paid GitHub plan.

## Development

```bash
scripts/validate-skill.sh                                   # fast, offline
scripts/validate-skill.sh --skip-render                     # fully offline
RUN_UPSTREAM_INTEGRATION=1 scripts/integration-test.sh      # needs network
```

`validate-skill.sh` checks the shipped file set, that every `quarto use
template`/`quarto add` carries `--no-prompt`, that `scaffold.sh` never invokes
`sudo`, that bad `--report-dir`/`--branch` values are rejected before anything is
written, and that the wrapper skills stay thin. With Quarto present it also
renders both demo fixtures.

`integration-test.sh` scaffolds both upstream templates for real, driving the
same `scaffold.sh` the skill tells the agent to call. Keep it that way: when the
test re-implemented the procedure instead, the documented commands silently
rotted while CI stayed green.

The demo fixtures under `example/` and `example-folium/` do not vendor their
Quarto extensions — `scripts/prepare-fixtures.sh` installs them at pinned
versions, and both the validator and the demo workflow call it before rendering.
A fresh clone therefore needs network access the first time it renders.

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
