# Licensing and attribution

This distribution is licensed under CC BY-NC-SA 4.0; see the repository's
`LICENSE`. The generated report template is supplied by Roy Francis:

- <https://github.com/royfrancis/folium>
- <https://github.com/royfrancis/folium-webpage>

Preserve upstream copyright, attribution, and license files when scaffolding a
report. Do not represent the distribution's license as trademark permission to
use the NBIS or SciLifeLab names or logos. Confirm branding permission with the
relevant owner before redistribution outside the intended NBIS context.

Installed Quarto extensions have their own upstream licenses. Keep their
bundled license files and review them when adding or redistributing extension
assets. In particular, Font Awesome carries its upstream license notice in
`_extensions/quarto-ext/fontawesome/assets/LICENSE.txt`; that notice travels
with the extension when `quarto add` installs it into a scaffolded report, and
must be preserved there.

This repository no longer vendors extensions into its demo fixtures -- they are
installed at build time by `scripts/prepare-fixtures.sh` -- so no extension
license files are redistributed by this repository itself.

The inline SVG in `templates/include_logo.html` is a locally maintained
standalone-rendering workaround for `folium-webpage`. Preserve any provenance
or branding notices that accompany the upstream asset when copying or modifying
it.
