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
| `quarto-ext/fontawesome` | Installed from the upstream repository if absent. | 1.3.0 in integration on 2026-07-16. |
| `mcanouil/quarto-collapse-output` | Pinned to `1.4.0` when added. | 1.4.0 in integration on 2026-07-16. |
| `royfrancis/quarto-accordion` | Installed from the upstream repository if absent. | 1.1.2 in integration on 2026-07-16. |

The skill currently does not pin the template repositories because `quarto use
template` does not provide a tested release identifier in this workflow. Treat
an unexpected scaffold layout as a compatibility failure, not an invitation to
guess replacements. Current upstream `folium` uses `website.navbar.logo` and
does not contain `assets/include_logo.html`; the inline-SVG workaround applies
only to `folium-webpage`.

Run `scripts/validate-skill.sh` on every change. When Quarto is installed, it
also renders the tracked `example/` fixture. Run
`RUN_UPSTREAM_INTEGRATION=1 scripts/integration-test.sh` to test both upstream
templates; it requires Quarto and network access.
