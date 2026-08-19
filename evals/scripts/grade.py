#!/usr/bin/env python3
"""Grade one eval run's outputs against its assertions.

Written as a script rather than eyeballed because every assertion here is
mechanically checkable, and a script gives the same verdict on every iteration.

Usage: grade.py <run-dir>        # run-dir holds eval_metadata.json and outputs/
Writes grading.json next to eval_metadata.json.
"""
import json, re, sys, pathlib

# Emails the prompts actually supply. Anything else in a project is invented.
SUPPLIED = {
    "zero-question-happy-path": {
        "anna.lindqvist@ki.se", "erik.ohlsson@ki.se", "massimiliano.volpe@nbis.se"},
    "metadata-withheld": set(),
    "pixi-user": set(),
}
# Upstream placeholders that ship with the templates; not "invented" by the agent.
UPSTREAM_EMAILS = {"john.doe@email.com", "john.doe@nbis.se"}
LOGO_PAYLOAD = 'viewBox="0 0 1497.39 194.27"'
BANNER = 'class="quarto-title-banner'
TODO = re.compile(r"TODO|TBD|FIXME|<[A-Z_ ]+>|XXX", re.I)


def read(p):
    try:
        return p.read_text(errors="replace")
    except Exception:
        return ""


def find_project(outputs):
    """The scaffolded project root: the dir holding index.qmd or _quarto.yml."""
    # The agent creates a project directory inside outputs/, so require a
    # subdirectory. Review copies flattened into outputs/ itself must not be
    # mistaken for the project root.
    cands = []
    for marker in ("_quarto.yml", "index.qmd"):
        cands += [p.parent for p in outputs.rglob(marker)
                  if "_extensions" not in p.parts and ".pixi" not in p.parts
                  and p.parent != outputs]
    if not cands:
        return None
    # Shallowest wins, so we get the project root and not a subpage.
    return sorted(cands, key=lambda d: len(d.parts))[0]


def collect(root, exts=(".qmd", ".yml", ".yaml", ".md", ".html")):
    out = {}
    if not root:
        return out
    for p in root.rglob("*"):
        if p.is_file() and p.suffix in exts and ".pixi" not in p.parts:
            out[p] = read(p)
    return out


def grade(run_dir: pathlib.Path):
    meta = json.loads((run_dir / "eval_metadata.json").read_text())
    name = meta["eval_name"]
    outputs = run_dir / "outputs"
    proj = find_project(outputs)
    files = collect(proj)
    blob = "\n".join(files.values())

    qyml = read(proj / "_quarto.yml") if proj else ""
    index = read(proj / "index.qmd") if proj else ""
    front = qyml + "\n" + index
    wf = ""
    if proj:
        for p in proj.rglob(".github/workflows/*.yml"):
            wf += read(p)
    html = {p: t for p, t in files.items() if p.suffix == ".html"}
    html_blob = "\n".join(html.values())

    # Emails present anywhere, minus what the prompt gave and upstream defaults.
    # Require an alphabetic TLD and reject anything preceded by a path
    # separator, so GitHub action refs like prefix-dev/setup-pixi@v0.10.1 are
    # not mistaken for addresses. (They were, on the first run.)
    emails = set(re.findall(r"(?<![\w./-])[\w.+-]+@[\w-]+\.[A-Za-z]{2,}", blob))
    invented = {e for e in emails
                if e not in SUPPLIED.get(name, set())
                and e not in UPSTREAM_EMAILS
                and not e.endswith(("example.com", "org.se"))}

    ext_dirs = []
    if proj:
        ext_dirs = [str(p.relative_to(proj)) for p in proj.glob("_extensions/*/*")]
    have_ext = lambda n: any(n in d for d in ext_dirs)

    out_dir_match = None
    m_q = re.search(r"^\s*output-dir:\s*(\S+)", qyml, re.M)
    m_w = re.search(r'REPORT_DIR:\s*"([^"]+)"', wf)
    if m_q and m_w:
        out_dir_match = m_q.group(1).strip('"\'') == m_w.group(1)

    checks = {
      "project_created": (proj is not None, f"project root: {proj}"),
      "rendered_html": (bool(html), f"{len(html)} html file(s)"),
      "title_keeps_meta_id": (
          bool(re.search(r"^title:.*\{\{<\s*meta nbis\.id\s*>\}\}", front, re.M)),
          "title: line derives from nbis.id"
          if re.search(r"^title:.*\{\{<\s*meta nbis\.id\s*>\}\}", front, re.M)
          else f"title: line is {re.search(r'^title:.*', front, re.M).group(0)[:70] if re.search(r'^title:.*', front, re.M) else 'absent'}"),
      "subtitle_has_project_title": (
          bool(re.search(r"^subtitle:.*Methylation profiling", front, re.M | re.I)),
          "subtitle holds the project title"),
      "nbis_id_4471": ("SMS-4471-24" in front, "SMS-4471-24 present"),
      "nbis_id_8812": ("SMS-8812-25" in front, "SMS-8812-25 present"),
      "workflow_exists": (bool(wf), f"{len(wf)} bytes of workflow"),
      "no_placeholders": (bool(wf) and "__DEFAULT_BRANCH__" not in wf
                          and "__REPORT_DIR__" not in wf, "no __PLACEHOLDER__ left"),
      "ext_fontawesome": (have_ext("fontawesome"), str(ext_dirs)),
      "ext_collapse_output": (have_ext("collapse-output"), str(ext_dirs)),
      "ext_accordion": (have_ext("accordion"), str(ext_dirs)),
      "logo_payload_in_html": (LOGO_PAYLOAD in html_blob, "inline NBIS SVG payload"),
      "logo_injection_target": (BANNER in html_blob, "quarto-title-banner present"),
      "no_invented_email": (not invented, f"invented: {sorted(invented) or 'none'}"),
      "todo_placeholders": (bool(TODO.search(front)), "explicit TODO/TBD marker present"),
      "analyst_not_guessed_from_email": (
          not re.search(r"^\s*name:\s*\"?(Massimiliano|massimiliano)", front, re.M | re.I),
          "no analyst name asserted without a real source"
          if not re.search(r"^\s*name:\s*\"?Massimiliano", front, re.M | re.I)
          else "analyst name present - acceptable only if it came from git config"),
      "multipage_project": (bool(re.search(r"type:\s*website", qyml)), "project type website"),
      "singlepage_project": (bool(index) and not re.search(r"type:\s*website", qyml),
                             "index.qmd without a website project block"),
      "use_pixi_true": (bool(re.search(r'USE_PIXI:\s*"true"', wf)), "USE_PIXI true"),
      "output_dir_aligned": (out_dir_match is True,
                             f"_quarto.yml={m_q.group(1) if m_q else None} "
                             f"workflow={m_w.group(1) if m_w else None}"),
    }

    # Which checks apply to which eval.
    applies = {
      "zero-question-happy-path": ["project_created","rendered_html","title_keeps_meta_id",
        "subtitle_has_project_title","nbis_id_4471","workflow_exists","no_placeholders",
        "ext_fontawesome","ext_collapse_output","ext_accordion","logo_payload_in_html",
        "logo_injection_target","no_invented_email","analyst_not_guessed_from_email"],
      "metadata-withheld": ["project_created","multipage_project","todo_placeholders",
        "no_invented_email","workflow_exists","no_placeholders","output_dir_aligned",
        "ext_fontawesome","ext_collapse_output","ext_accordion"],
      "pixi-user": ["project_created","singlepage_project","use_pixi_true","nbis_id_8812",
        "todo_placeholders","no_invented_email","logo_payload_in_html",
        "logo_injection_target","no_placeholders"],
    }[name]

    exps = [{"text": k, "passed": bool(checks[k][0]), "evidence": checks[k][1]}
            for k in applies]
    passed = sum(e["passed"] for e in exps)
    # aggregate_benchmark.py reads grading["summary"]["pass_rate"] and
    # ["passed"], and grading["expectations"]. Keep the flat copies too so the
    # file stays readable on its own.
    res = {"eval_id": meta["eval_id"], "eval_name": name,
           "expectations": exps,
           "passed_count": passed, "total_count": len(exps),
           "pass_rate": round(passed / len(exps), 4),
           "summary": {"passed": passed, "total": len(exps),
                       "pass_rate": round(passed / len(exps), 4)}}
    (run_dir / "grading.json").write_text(json.dumps(res, indent=2))
    return res


if __name__ == "__main__":
    r = grade(pathlib.Path(sys.argv[1]))
    print(f"{r['eval_name']}: {r['passed_count']}/{r['total_count']}")
    for e in r["expectations"]:
        print(f"  {'PASS' if e['passed'] else 'FAIL'}  {e['text']}: {e['evidence'][:90]}")
