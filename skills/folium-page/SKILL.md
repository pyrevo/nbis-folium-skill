---
name: folium-page
description: >-
  Start a new NBIS (National Bioinformatics Infrastructure Sweden) project
  report as one single self-contained HTML page, using Roy Francis's
  `folium-webpage` template. Use when the user wants a new NBIS report that
  travels as a single file, or types /folium-page. Do not use for the
  Python `folium` mapping library, Leaflet maps, marker clusters, GIS, or
  general geospatial visualization.
---

# Start an NBIS report (single self-contained page)

Preselects the **`folium-webpage`** template — one single self-contained HTML
page, for a report that should travel as a single file. This template also needs
the standalone-logo fix, which the scaffold script applies automatically.

Load the **`nbis-folium`** skill and follow its procedure with
`--template folium-webpage` already decided. Do not ask which template to use.
That skill holds the whole procedure, including `scripts/scaffold.sh`; this one
only fixes the template choice.

If `nbis-folium` is not installed, say so and point the user at
<https://github.com/pyrevo/nbis-folium-skill> — do not attempt the scaffold from
memory, because the corrected logo and the scaffold script are files in that
skill.

## How to behave

Aim for zero questions. A bare path in the invocation is the target directory.
Anything resembling `--install-deps` or "install whatever is needed" is consent
to install missing machine-scoped tools. Do not ask for anything the invocation
already answered.

Only two things should interrupt: project metadata that cannot be invented (NBIS
ID, client, PI, analyst — ask once, batched), and a target directory that is not
empty. If the user would rather fill metadata in later, scaffold with explicit
`TODO` placeholders and list them at the end. Never fabricate a client or PI
name, email address, or NBIS ID. The analyst may come from `git config`, since
whoever runs this is usually the analyst — but only when it looks like a work
identity (a name with a space, an institutional address), because a git handle or
personal address on a client deliverable is worse than a visible gap. Say which
values came from `git config`, and prefer a `TODO` on a shared or CI machine.
