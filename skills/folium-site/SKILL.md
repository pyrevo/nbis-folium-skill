---
name: folium-site
description: >-
  Start a new NBIS (National Bioinformatics Infrastructure Sweden) project
  report as a multi-page Quarto website, using Roy Francis's `folium` template.
  Use when the user wants a new NBIS report with several report pages, or types
  /folium-site. Do not use for the Python `folium` mapping library, Leaflet
  maps, marker clusters, GIS, or general geospatial visualization.
---

# Start an NBIS report (multi-page website)

Preselects the **`folium`** template — a multi-page Quarto website, for work that
needs several report pages plus a completion page.

Load the **`nbis-folium`** skill and follow its procedure with
`--template folium` already decided. Do not ask which template to use. That skill
holds the whole procedure, including `scripts/scaffold.sh`; this one only fixes
the template choice.

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
name, email address, or NBIS ID. The analyst is usually the user, so a name may be
derived from a supplied institutional address when its local part is a clean
`first.last` pair, or taken from `git config` when that looks like a work identity
rather than a code-hosting handle and personal address. Say which values were
inferred and where from, and fall back to a `TODO` rather than guessing.
