# Compatibility and version policy

This skill has a deliberately small compatibility surface: it scaffolds the
upstream templates and then applies local configuration. Upstream template and
extension releases can change their structure, so verify them before each
release of this skill.

| Component | Version policy | Last verified |
| --- | --- | --- |
| Quarto | The example declares `>= 1.8.25`. | 1.9.38 on 2026-07-16. |
| `royfrancis/folium` | Installed from the upstream repository at scaffold time. | Full scaffold/render integration passed on 2026-07-16. |
| `royfrancis/folium-webpage` | Installed from the upstream repository at scaffold time. | Full scaffold/render integration passed on 2026-07-16. |
| `quarto-ext/fontawesome` | Pinned to `@v1.3.0` when added (note the `v` prefix). | 1.3.0 in integration on 2026-07-16. |
| `mcanouil/quarto-collapse-output` | Pinned to `1.4.0` when added. | 1.4.0 in integration on 2026-07-16. |
| `royfrancis/quarto-accordion` | Pinned to `@1.1.2` when added (no `v` prefix). | 1.1.2 in integration on 2026-07-16. |

The skill currently does not pin the template repositories because `quarto use
template` does not provide a tested release identifier in this workflow. Treat
an unexpected scaffold layout as a compatibility failure, not an invitation to
guess replacements. Current upstream `folium` uses `website.navbar.logo` and
does not contain `assets/include_logo.html`; the inline-SVG workaround applies
only to `folium-webpage`.

## Testing

Run `scripts/validate-skill.sh` on every change. It is offline and fast: it
checks the shipped file set, that every `quarto use template`/`quarto add`
invocation carries `--no-prompt`, that `scaffold.sh` never invokes `sudo`, that
bad `--report-dir`/`--branch` values are rejected before anything is written,
and — when Quarto is installed — renders both tracked demo fixtures.

Tag formats are not consistent across these repositories: `quarto-ext` prefixes
releases with `v`, while `mcanouil` and `royfrancis` do not. A wrong prefix makes
`quarto add` fail outright rather than falling back to the latest release, so
verify the tag before changing a pin.

The demo fixtures do not vendor their extensions. `scripts/prepare-fixtures.sh`
installs them at the pinned versions, and both `validate-skill.sh` and the demo
Pages workflow call it before rendering. This removed two byte-identical 1.3 MB
extension trees from version control, and means the demo build exercises the same
extension-install path the skill puts in front of users.

Run `RUN_UPSTREAM_INTEGRATION=1 scripts/integration-test.sh` to scaffold both
upstream templates for real; it needs Quarto and network access.

The integration test drives `skills/nbis-folium/scripts/scaffold.sh` — the same
script `SKILL.md` tells the agent to call. Keep it that way. When the test
re-implemented the procedure instead, the documented commands silently rotted:
they lacked `--no-prompt`, so they deadlocked on Quarto's trust confirmation in
any non-interactive shell while CI stayed green.

## Dependency policy

Project-scoped dependencies (Quarto extensions, and R/Python packages inside the
project) install unattended. Machine-scoped tools require `--install-deps`:
Quarto is **required** and aborts the run when absent, while `gh` is **optional**
and only warns, because without it enabling GitHub Pages stays a manual step in
Settings and nothing else changes. `sudo` is never run unattended — if elevation is
the only route, the script prints the command and stops.
