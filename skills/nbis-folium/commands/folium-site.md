---
description: Start a new NBIS report as a multi-page Quarto website (folium template)
---

Start a new NBIS project report using the **`folium`** template — a multi-page
Quarto **website**, for work that needs several report pages plus a completion
page.

Use the `nbis-folium` skill and follow its procedure with `--template folium`
already decided; do not ask which template to use.

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
