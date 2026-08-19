---
description: Start a new NBIS report as a single self-contained page (folium-webpage template)
---

Start a new NBIS project report using the **`folium-webpage`** template — one
single self-contained HTML page, for a report that should travel as a single
file.

Use the `nbis-folium` skill and follow its procedure with
`--template folium-webpage` already decided; do not ask which template to use.
This template also needs the standalone-logo fix, which the scaffold script
applies automatically.

Arguments the user may have supplied: $ARGUMENTS

Interpret them leniently — a bare path is the target directory, and anything
resembling `--install-deps` or "install whatever is needed" is consent to
install missing machine-scoped tools. Do not ask for anything the arguments
already answer.

Aim for zero questions. If the target directory is unambiguous and Quarto is
present, scaffold without stopping to confirm. Ask at most one batched question,
and only for project metadata that cannot be invented (NBIS ID, client, PI,
analyst). If the user does not want to answer yet, scaffold with explicit
`TODO` placeholders and list them at the end — never fabricate a name, an
email address, or an NBIS ID.
