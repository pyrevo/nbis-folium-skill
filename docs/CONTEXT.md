# nbis-folium-skill — development context

## Agent session

```bash
claude --resume 229a6036-c067-48fc-a69d-559b4f054d94
```

Model: Claude Opus 5 (1M context). Session date: 2026-08-19.
Starting point: `4a49d89` ("Add initial report.qmd for example-folium demo").
Twelve commits followed; the last three were unpushed when this record was written.

Environment the work was verified against: Quarto 1.10.18, pixi 0.76.2,
gh 2.97.0, macOS (darwin 25.5.0).

## Overview

The session began as a review of the skill and turned into a rework: fixing four
real bugs, extracting the deterministic half into a script, adding two slash
commands, supporting pixi, de-duplicating the demo fixtures, and constraining
where report identity may come from. Every change was verified by execution
rather than inspection, including one live experiment against GitHub Pages.

---

## The four original bugs

Found by reviewing the skill against its own tests and then running the
documented commands.

### 1. `--no-prompt` deadlock (the important one)

`SKILL.md` documented `quarto use template royfrancis/folium` and `quarto add …`
without `--no-prompt`. Both wait on an interactive trust confirmation, so in a
non-interactive agent shell they **block forever and create nothing**. Reproduced
directly: with stdin closed the command sat for over five minutes and produced no
files; with `--no-prompt` it finished in seconds.

The reason it survived so long is the more useful lesson: `integration-test.sh`
already passed `--no-prompt`, because it **re-implemented** the procedure instead
of running the documented one. CI was green while the documented path deadlocked.
An independent baseline agent later hit the same hang and worked around it with
`git clone`, confirming the bug from outside.

### 2. Report title in the wrong field

`SKILL.md` said to set the report title in `title`. Both upstream templates ship
`title: "NBIS support {{< meta nbis.id >}}"` and put the human-readable title in
`subtitle`; neither has a `site-title`. Writing the title into `title` destroys
the link between the heading and the NBIS ID. A baseline agent made exactly this
mistake, deliberately: *"the one place I deliberately deviated from upstream."*

### 3. Output-directory divergence

The skill defaulted to `report` while upstream `folium` ships
`project.output-dir: docs`. The workflow's `--output-dir` flag overrode it in CI,
so a bare local `quarto render` and CI wrote to different trees. Defaults are now
per template (`docs` for folium, `report` for folium-webpage), and `scaffold.sh`
aligns `_quarto.yml` with the workflow.

### 4. A verification that could not fail

Both scripts verified the standalone logo by grepping rendered HTML for `<svg`.
The logo SVG is a string literal inside an injected `<script>`, so that matched
whether or not the logo appeared. Replaced with two assertions:

- `viewBox="0 0 1497.39 194.27"` — the payload reached the output
- `class="quarto-title-banner` — its injection target exists

The second is the one that can fail: `insertImage` inserts into
`.quarto-title-banner`, so dropping `title-block-banner` from the front matter
would silently remove the logo while an `<svg` grep still passed. An eval later
demonstrated this on a real artifact — a baseline run passed the banner check and
failed the payload check, i.e. a report with a banner and no NBIS logo.

---

## Architecture

### `scripts/scaffold.sh` — one source of truth

The mechanical half (scaffold, verify layout, install extensions, apply the logo
fix, align output-dir, write `.gitignore` and the Pages workflow, verification
render) lives in `skills/nbis-folium/scripts/scaffold.sh`. `SKILL.md` calls it and
`integration-test.sh` drives the same script, so the documented and tested
procedures cannot drift again.

It lives **inside** the skill directory because `npx skills add` copies only
`skills/nbis-folium/`; a script at repo-root `scripts/` would never reach a user's
machine.

Deliberately not its job: writing metadata (needs judgement, must never be
invented) and any git operation (outward-facing, needs approval).

### Three skills, so the commands need no install step

`npx skills add` has no postinstall hook and knows nothing about slash commands,
but it does support several skills per repository. So the two wrappers are thin
skills of their own:

| Skill | Role |
| --- | --- |
| `nbis-folium` | the procedure, `scaffold.sh`, templates, references |
| `folium-site` | preselects the multi-page `folium` template |
| `folium-page` | preselects the single-page `folium-webpage` template |

One `npx skills add` therefore yields `/folium-site` and `/folium-page` on any
agent that exposes skills as slash commands. Verified with the real CLI:
`--list` reports **"Found 3 skills"**. `install-commands.sh` remains for agents
that keep commands in their own directory, and reads the wrapper skills directly
so their text exists in one place only. It also supports `--uninstall`.

### Dependency tiers

| Tier | Examples | Behaviour |
| --- | --- | --- |
| Project-scoped | Quarto extensions, `renv`/venv packages | install unattended |
| Machine-scoped, required | Quarto | gated on `--install-deps`, aborts if absent |
| Machine-scoped, optional | `gh` | gated, warns and continues |

`sudo` is never run unattended: where elevation is the only route the script
prints the command and stops. A validator guard enforces that `scaffold.sh`
contains no `sudo` in command position.

---

## GitHub Pages — settled, including a negative result

Writing the workflow does not publish anything; Pages must be pointed at the
Actions source. Until then builds succeed and the deploy step 404s in the log.
**Nothing prompts the user** — no dialog, no email saying "authenticate".

Three candidate solutions were considered:

1. A human clicks **Settings → Pages → Source: GitHub Actions**
2. `gh api -X POST "repos/<owner>/<repo>/pages" -f build_type=workflow`
3. `actions/configure-pages@v5` with `enablement: true`, so the workflow enables
   Pages on itself

**Option 3 does not work.** Tested live on this repository: Pages was disabled via
`gh api -X DELETE`, the step was added, and the run failed in 9 seconds with

```
Get Pages site failed. Error: Not Found
Create Pages site failed. Error: Resource not accessible by integration
```

The workflow's own token cannot create a Pages site. Reverted in `86043ff`; Pages
restored and both demo URLs verified back at HTTP 200. Note that testing this
required *disabling* Pages first — with Pages already enabled, `enablement: true`
is a silent no-op that would have looked like success.

Not investigated: whether setting `default_workflow_permissions` to `write`
changes this. The repository has it at `read`. Expectation is that it still fails,
and requiring every report repo to loosen token permissions is a worse trade than
one click.

**Option 2 is the documented route and is proven** — it is the exact command used
to restore this repository's Pages after the experiment.

---

## Pixi support

Colleagues using pixi had no CI path: the workflow recognised only `renv.lock`,
`requirements.txt`, and `pyproject.toml`, so a pixi-only project with
`NEEDS_PYTHON=true` failed with *"requirements.txt or pyproject.toml is missing"*.

`USE_PIXI: "true"` now **replaces** the per-language setup rather than adding to
it: `setup-r` and `setup-python` are skipped, and the render becomes
`pixi run quarto render`. It requires `pixi.lock`, mirroring the `renv.lock` rule.

Two things verified rather than assumed:

- `pixi run` prepends its environment to `PATH` but **inherits the rest**, so
  Quarto from `quarto-actions/setup` is still found while `python` comes from
  pixi. The whole design rests on this.
- A real scaffolded `folium-webpage` report with a numpy chunk rendered through
  `pixi run quarto render`, executing against `.pixi/envs/default`, with the logo
  assertions still passing.

`prefix-dev/setup-pixi` is pinned to `v0.10.1`, not the floating `@v0`: it is a
0.x action where a major tag can still carry breaking changes.

---

## Demo fixtures

### De-duplicated

The two fixtures vendored **byte-identical** 1.3 MB `_extensions` trees, 35 files
each. `scripts/prepare-fixtures.sh` now installs them at pinned versions, and both
`validate-skill.sh` and the demo workflow call it before rendering.

Done in two commits so the risky half was isolated: `3ceb2b7` added the mechanism
while the vendored copies still existed and CI proved it; `c702ab8` deleted them.

Tracked content fell from **3.9 MB in 130 files to 1.6 MB in 65 files**. (An
earlier claim of "most of 9.9 MB" was wrong — that figure was the working
directory including untracked build output, and a `du` total inflated by
disk-block rounding.) The larger win is that the demo build now exercises the same
extension-install path users get, so an upstream break becomes a red CI run.

Cost: `validate-skill.sh`'s render leg needs network on a clean checkout. It
degrades to static validation with a clear reason rather than failing, and
`--skip-render` stays fully offline.

### Renamed

The names were backwards — `example/` held the folium-**webpage** demo while
`example-folium/` held the **folium** one:

- `example/` → `demo-folium-page/` (single page, matches `/folium-page`)
- `example-folium/` → `demo-folium-site/` (multi-page, matches `/folium-site`)

Published URLs are unchanged: the workflow still renders to `../demo` and
`../demo/folium`, verified by running CI's render commands and confirming both
`demo/index.html` and `demo/folium/index.html` appear.

---

## Where report identity may come from

This went through two revisions, because the first fix over-corrected. The
requirement is narrow: **one person's identity must never reach colleagues via the
package**, which is a property of the distributed files, not a reason to forbid
useful local inference.

Final rule, in `SKILL.md`:

- **Client and PI** — only from what the user states. They are never the person at
  the keyboard, so a guess is simply wrong.
- **Analyst** — preferred sources in order:
  1. what the user states;
  2. a supplied institutional email, when the local part is a clean `first.last`
     pair (NBIS uses `firstname.lastname`, so this yields a professional name
     reliably);
  3. `git config user.name`/`user.email`, **only when they look like a work
     identity** — a name containing a space, an institutional address;
  4. a `TODO` naming what was found.
- Provenance of anything inferred must be stated in the final report.
- The git identity is unavailable on shared or CI machines (`$CI`,
  `$GITHUB_ACTIONS`).
- A display name is never reconstructed from a local part that is not a clean
  pair — a single token, three or more parts, or an initial like `a.k.svensson`,
  where expanding `k` is a guess at spelling rather than reading a fact.

Why git config ranks third rather than second, empirically: on the development
machine `git config` held a one-word code-hosting handle and a consumer webmail
address. An intermediate version wrote **both** into a report addressed to a
client before the plausibility check was added.

---

## Guards in `scripts/validate-skill.sh`

Each exists because something actually went wrong, and each was negative-tested
(deliberately broken to confirm it fails). A check that cannot fail is worthless —
that was bug 4.

| Guard | Protects against |
| --- | --- |
| every `quarto use template`/`add` carries `--no-prompt` | the deadlock returning |
| `scaffold.sh` contains no `sudo` in command position | unattended privilege escalation |
| bad `--report-dir`/`--branch` rejected before any write | path escape, shell injection |
| logo payload **and** injection target asserted | the tautological check returning |
| wrapper skills stay thin, names match directories | duplicated procedure, wrong command name |
| pixi flag, render step, lockfile guard, exact `setup-pixi` pin | silent pixi breakage |
| `install-commands.sh` supports `--uninstall`, never `rm -rf` a whole dir | a one-way install, accidental deletion |
| README documents both removal paths | undocumented uninstall |
| every email in `skills/` is one of three generic placeholders | personal data shipping to colleagues |
| owner handle appears only in the distribution URL and npx command | the same, for handles |

The last two both caught real leaks **during this session**, in drafts of the very
change meant to prevent them: once a real email address used as an example, once a
real code-hosting handle. Both were stopped by the guard, not by review.

---

## Evaluation (skill-creator)

Three test cases, run with and without the skill via subagents.

| Iteration | Configuration | Assertions passed |
| --- | --- | --- |
| 1 | with skill | 32/33 (97%) |
| 1 | no skill (baseline) | 20/32 (62%) |
| 2 | with skill (after identity fix) | 33/33 (100%) |
| 4 | analyst-from-email check | 15/15 (100%) |

Timing, iteration 1: **124s ± 13s with the skill against 269s ± 63s without**, at
the same token cost. Baselines burn time discovering the template and recovering
from mistakes. The variance matters as much as the mean.

Findings worth keeping:

- Baselines never wired up a Pages workflow at all.
- Two baselines inferred identity they were not given.
- One baseline solved the standalone logo with a **base64 data URI** instead of
  inline SVG. `SKILL.md` forbids data URIs, but that prohibition may be stronger
  than its underlying reason requires — the original concern was an *external
  image path*, which a data URI is not. Unresolved.
- The grader needed fixing twice: an email regex matched
  `prefix-dev/setup-pixi@v0.10.1`, and a title check searched the whole document
  so it passed when the shortcode merely moved into `subtitle`. Both were faults
  in the measurement. A green assertion is only as good as the assertion.
- `project_created` and `rendered_html` pass in every configuration and so do not
  discriminate; they inflate the baseline's percentage.

Workspace: `evals-workspace/` (gitignored, regenerable). `evals/scripts/grade.py`
grades a run, `evals/scripts/flatten_for_review.py` copies reviewable artifacts
flat into `outputs/` because the viewer lists only top-level files and has no
`.qmd` handler.

---

## Verified facts, so they need not be re-derived

- `quarto use template` and `quarto add` **both** require `--no-prompt` in any
  non-interactive shell, or they hang indefinitely.
- Extension tag formats are inconsistent: `quarto-ext/fontawesome` uses a `v`
  prefix (`@v1.3.0`); `mcanouil` and `royfrancis` do not (`@1.4.0`, `@1.1.2`). A
  wrong prefix fails the add outright rather than falling back to latest.
- Upstream `folium` ships `project.output-dir: docs` and no
  `assets/include_logo.html`; `folium-webpage` has no project block.
- Both templates put the project title in `subtitle`; neither has a `site-title`.
- `pixi run` inherits the outer `PATH`, so a Quarto installed outside the pixi
  environment is still resolved.
- `actions/configure-pages@v5` with `enablement: true` **cannot** create a Pages
  site from the workflow token.
- Quarto's `embed-resources` pass can fail on the Google Fonts fetch while Quarto
  still reports success, emitting a small non-embedded page plus an
  `index_files/` directory. Observed by a baseline agent at roughly 1 render in 4;
  not reproduced in four checked renders here.
- `npx skills add` copies skill directories only. No postinstall hook, no slash
  command installation, but multiple skills per repository are supported.

---

## Open items

1. **Silent non-self-contained render.** `scaffold.sh` verifies HTML existence,
   the logo payload, and the banner — all of which pass on a non-embedded page.
   For `folium-webpage`, whose purpose is one self-contained file, assert that no
   `*_files` directory sits beside the output. That is robust where a size
   threshold would be brittle. **Strongest remaining candidate for real work.**
2. **Three unpushed commits** at the time of writing.
3. **Untested path:** a properly configured NBIS machine, where `git config` holds
   `Firstname Lastname` and an `@nbis.se` address. That is the case the identity
   refinement is designed to serve and it could not be exercised here.
4. **Manual test** of `/folium-page` by a human, the one thing no agent verified.
5. **Data-URI logo question** (see Evaluation) — is the prohibition too strong?
6. **CC-BY-NC-SA on code.** Creative Commons advises against CC licences for
   software, and NC blocks the consultancies most likely to use this. Dual
   licensing — MIT for `scripts/` and the workflow template, CC-BY-NC-SA for
   anything derived from Roy Francis's templates — would match the actual
   obligations better. Raised early, never acted on.

---

## Commit log

| Commit | Change |
| --- | --- |
| `44a2464` | `/folium-site` + `/folium-page`, four bug fixes, `scaffold.sh` extraction |
| `3ceb2b7` | fixture extensions installed at build time (mechanism only) |
| `c702ab8` | vendored `_extensions` trees deleted |
| `48d15fd` | Pages enablement documented, `gh` as an optional dependency |
| `f6ce3e8` | experiment: workflow-based Pages auto-enablement |
| `86043ff` | revert of the above — the token cannot create a Pages site |
| `1848dfd` | pixi-managed environments in the Pages workflow |
| `d8cfd33` | wrappers shipped as skills rather than command files |
| `30d2580` | `--uninstall` support, README brought up to date |
| `728871a` | identity provenance constrained (first attempt, over-corrected) |
| `acbfaa8` | supplied work address ranked above `git config` |
| `58498ad` | demo fixtures renamed, stale demo text corrected |
