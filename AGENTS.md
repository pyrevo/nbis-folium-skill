## Context

We have an opencode skill at `~/.config/opencode/skills/nbis-folium/` that scaffolds NBIS project reports using the folium Quarto template. It:
- Asks which template (folium or folium-webpage)
- Asks project details (NBIS ID, client, PI, analyst, title)
- Runs `quarto use template` + installs extensions
- Adds `.github/workflows/deploy-pages.yml` (GH Pages CI/CD)
- Replaces `assets/include_logo.html` with a data-URI version for standalone rendering
- Writes/updates context files such as AGENTS.md
- Reminds user to enable Pages in github repo Settings

The skill lives at:
- `~/.config/opencode/skills/nbis-folium/SKILL.md`
- `~/.config/opencode/skills/nbis-folium/templates/deploy-pages.yml`
- `~/.config/opencode/skills/nbis-folium/templates/include_logo.html`

No analysis scripts, no project-specific content — purely a report scaffolder.

The goal is to publish the SKILL within this report to be compatible with different coding agents (OpenCode, Hermes, Codex, Antigravity, Cloude, etc.)

## Task 1: Dummy test project

Create a dummy NBIS project repo locally to test the skill:
1. Create a new directory `/tmp/test-nbis-folium`
2. Run the nbis-folium skill on it — use folium-webpage template with dummy metadata (NBIS ID: TEST-001, client: "Test Client", PI: "Test PI", analyst: "Test Analyst", title: "Test Project")
3. Verify the repo structure is correct (assets/, .github/workflows/, index.qmd, etc.)
4. Verify `deploy-pages.yml` exists and looks correct
5. Verify `include_logo.html` has the data URI NBIS logo
6. Optionally: test the Pages deployment, for example we can populate it with the information about the SKILL itself (this repo)

## Task 2: Public distribution repo

Create a GitHub repo (this repo) to distribute the skill (it would benice if it meets the skills.sh requirements but we don't need to publish it there):
1. The repo should have `skills/nbis-folium/SKILL.md` as the main skill file (standard skills.sh layout)
2. Include a `README.md` explaining what the skill does and how to install it
3. Include a `LICENSE` (MIT or CC BY-NC-SA 4.0)
4. The templates/ subdirectory should be included alongside SKILL.md
5. After pushing, verify `npx skills add <owner>/nbis-folium-skill` works

## Task 3: Multi-agent compatibility

The skills.sh ecosystem supports 70+ agents, but our SKILL.md references `opencode`-specific features (the skill tool). Research which agents support:
- The `skill` tool (loading skills on-demand)
- Reading template files from the skill's directory
- Running Quarto commands

For agents that don't support the `skill` tool (e.g. simpler agents), the skill should be adapted to also work as a standalone prompt — instructions that describe what to do without relying on tool access. This means:
- Keep the current opencode SKILL.md (with skill tool assumption)
- Add a note about which agents require the skill tool and which can use it as a plain prompt
- The instructions should be clear enough that any agent can follow them even without the `skill` tool — just tell the agent what files to create and what commands to run