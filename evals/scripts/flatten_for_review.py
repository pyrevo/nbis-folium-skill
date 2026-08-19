#!/usr/bin/env python3
"""Copy each run's reviewable artifacts flat into outputs/ for the eval viewer.

The viewer lists only files at the top level of outputs/ and does not recurse,
so a run whose outputs/ holds a single project directory shows "No output
files". It also has no .qmd handler, and would dump a 2.6 MB rendered page as
raw source, so the rendered report is summarised rather than embedded.

Usage: flatten_for_review.py <iteration-dir>
"""
import re, sys, pathlib, shutil

TODO = re.compile(r"TODO|TBD|FIXME|XXX", re.I)


def project_root(outputs: pathlib.Path):
    cands = []
    for marker in ("_quarto.yml", "index.qmd"):
        cands += [p.parent for p in outputs.rglob(marker)
                  if "_extensions" not in p.parts and ".pixi" not in p.parts
                  and p.parent != outputs]
    return sorted(cands, key=lambda d: len(d.parts))[0] if cands else None


def flatten(run: pathlib.Path):
    outputs = run / "outputs"
    proj = project_root(outputs)
    # Clear previous review copies so reruns do not accumulate.
    for old in outputs.glob("0*-*"):
        old.unlink()
    if not proj:
        (outputs / "00-SUMMARY.md").write_text("No project directory was produced.\n")
        return "no project"

    lines = [f"# Run summary\n", f"Project directory on disk:\n\n    {proj}\n"]

    html = [p for p in proj.rglob("*.html") if ".pixi" not in p.parts]
    if html:
        lines.append("## Rendered output\n")
        for h in sorted(html)[:8]:
            size = h.stat().st_size
            lines.append(f"- `{h.relative_to(proj)}` — {size:,} bytes")
        lines.append("\nOpen the real page in a browser (too large to embed here):\n")
        main = max(html, key=lambda h: h.stat().st_size)
        lines.append(f"    file://{main}\n")
        blob = "\n".join(h.read_text(errors="replace") for h in html)
        checks = [
            ("NBIS logo payload (inline SVG)", 'viewBox="0 0 1497.39 194.27"' in blob),
            ("Logo injection target present", 'class="quarto-title-banner' in blob),
            ("base64 data-URI logo instead", "data:image/svg+xml;base64" in blob),
            ("Self-contained (no *_files dir)", not any(
                d.is_dir() and d.name.endswith("_files") for d in proj.rglob("*"))),
        ]
        lines.append("## Verification in the rendered HTML\n")
        for label, ok in checks:
            lines.append(f"- {'yes' if ok else 'no '} — {label}")
        lines.append("")

    # Front matter is what the reviewer most wants to judge (TODO style).
    copied = 0
    for n, src in enumerate(
            [p for p in (proj / "_quarto.yml", proj / "index.qmd") if p.exists()], start=1):
        dest = outputs / f"0{n}-{src.name}.md"
        text = src.read_text(errors="replace")
        lang = "yaml" if src.suffix in (".yml", ".yaml") else "markdown"
        dest.write_text(f"# {src.name}\n\n```{lang}\n{text}\n```\n")
        copied += 1

    wf = list(proj.rglob(".github/workflows/*.yml"))
    if wf:
        shutil.copy(wf[0], outputs / "03-deploy-pages.yml")
    else:
        (outputs / "03-deploy-pages.yml").write_text(
            "# No GitHub Pages workflow was created by this run.\n")

    todos = []
    for src in list(proj.glob("*.qmd")) + list(proj.glob("*.yml")):
        for i, line in enumerate(src.read_text(errors="replace").splitlines(), 1):
            if TODO.search(line):
                todos.append(f"{src.name}:{i}: {line.strip()}")
    lines.append("## Placeholder markers left for the user\n")
    lines += [f"- `{t}`" for t in todos[:25]] or ["- none"]
    (outputs / "00-SUMMARY.md").write_text("\n".join(lines) + "\n")
    return f"{copied} source file(s), {len(todos)} placeholder(s)"


if __name__ == "__main__":
    # Resolve so the file:// links in the summaries are absolute and clickable.
    it = pathlib.Path(sys.argv[1]).resolve()
    for run in sorted(it.glob("eval-*/*/run-1")):
        print(f"{str(run.relative_to(it)):>46}  {flatten(run)}")
