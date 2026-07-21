#!/usr/bin/env python3
"""Full snippet sweep over the SwoftLang docs.

Extracts every ```swoftlang fence (including MappedCompare right panes and
ErrorToggle slots), applies the in-page swoftc marker conventions, and runs
the real compiler on each snippet.

Marker conventions (HTML comments in the markdown):
  <!-- swoftc-page excerpt=sources/X.sw -->   page fences are excerpts of X.sw;
                                              X.sw itself is checked, and each
                                              fence must be a verbatim substring
  <!-- swoftc name=X.sw -->                   snippet is written to X.sw in the
                                              page workdir (later snippets can
                                              import it); rechecked each time
  <!-- swoftc name=X.sw expect=error -->      must fail; the next txt fence is
                                              the byte-exact expected stderr
  <!-- swoftc match=prefix -->                expected stderr is a prefix match
  <!-- swoftc ... noaddons -->                run without --addon-path
  <!-- swoftc ... defer -->                   write now, check at end of page
  <!-- swoftc prelude=X.sw -->                check X.sw + snippet as one unit
  <!-- swoftc wrap=command -->                wrap fragment in command/execute
  <!-- swoftc wrap=event -->                  wrap fragment in event execute

ErrorToggle slots: #broken expects an error (expected text = the #error slot's
txt fence, filename = the file="..." attribute); #fixed must pass.

Unmarked fences must pass; fragments (first meaningful line not a top-level
declaration) are auto-wrapped in a command/execute body (event wrap when the
fragment mentions `event.`).
"""
import os, re, subprocess, sys, shutil, glob

SW = "/mnt/work/VSC/SwoftLang/compiler/_build/default/bin/main.exe"
DOCS = "/mnt/work/VSC/SwoftLang/docs"
REAL_ADDONS = "/mnt/work/VSC/SwoftLang/addons"
WORKROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sweep2-work")

FENCE_OPEN = re.compile(r"^```([A-Za-z0-9_-]*)(?:\s+\[[^\]]*\])?\s*$")
PAGE_DIRECTIVE = re.compile(r"<!--\s*swoftc-page\s+([^>]*?)\s*-->")
DIRECTIVE = re.compile(r"<!--\s*swoftc\s+([^>]*?)\s*-->")
TEMPLATE_OPEN = re.compile(r"<template\s+#(\w+)\s*>")
ETOGGLE_OPEN = re.compile(r"<ErrorToggle\b([^>]*)>")
FILE_ATTR = re.compile(r'file="([^"]+)"')
CODE_ANNO = re.compile(r"\s*//\s*\[!code[^\]]*\]\s*$", re.M)

TOP_LEVEL = re.compile(
    r"^(command|function|async\s+function|export\s+|import\s|bossbar\s|"
    r"gui\s|item\s|mob\s|persistent\s|scoreboard\s|server\s*\{|"
    r"storage\s*\{|tablist\s|var\s|api\s|every\s|fishing_loot\s|hologram\s|npc\s|"
    r"block_handler\s|placement_rule\s|"
    # OOP receiver blocks (Player { }, Mob { }, ...) and the Packet block
    r"Player\s*\{|Entity\s*\{|Mob\s*\{|Item\s*\{|Block\s*\{|Projectile\s*\{|"
    r"Inventory\s*\{|World\s*\{|Server\s*\{|Npc\s*\{|Hologram\s*\{|Packet\s*\{)"
)


def parse_kv(s):
    d = {}
    for tok in s.split():
        if "=" in tok:
            k, v = tok.split("=", 1)
            d[k] = v
        else:
            d[tok] = True
    return d


def strip_anno(code):
    return CODE_ANNO.sub("", code)


def first_meaningful(code):
    in_block = False
    for line in code.split("\n"):
        t = line.strip()
        if in_block:
            if "*/" in t:
                in_block = False
            continue
        if not t or t.startswith("//"):
            continue
        if t.startswith("/*"):
            if "*/" not in t:
                in_block = True
            continue
        return t
    return ""


def needs_wrap(code):
    fm = first_meaningful(code)
    if not fm:
        return None
    if TOP_LEVEL.match(fm):
        return None
    return "command"


def wrap(code, kind):
    body = "\n".join("        " + l if l.strip() else l for l in code.rstrip("\n").split("\n"))
    return 'command "snippetwrap" {\n    execute {\n%s\n    }\n}\n' % body


class Item:
    def __init__(self, lineno, lang, code, slot, directive, et_file):
        self.lineno, self.lang, self.code = lineno, lang, code
        self.slot, self.directive, self.et_file = slot, directive, et_file


def parse_page(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    items, page_dir = [], {}
    pending = None
    slot = None
    et_file = None
    in_et = False
    i = 0
    while i < len(lines):
        line = lines[i]
        m = FENCE_OPEN.match(line)
        if m:
            lang = m.group(1).lower()
            start = i + 1
            j = start
            while j < len(lines) and lines[j].rstrip() != "```":
                j += 1
            code = "\n".join(lines[start:j]) + "\n"
            items.append(Item(start + 1, lang, code, slot, pending if lang in ("swoftlang", "sw") else None, et_file if in_et else None))
            if lang in ("swoftlang", "sw"):
                pending = None
            i = j + 1
            continue
        pm = PAGE_DIRECTIVE.search(line)
        if pm:
            page_dir.update(parse_kv(pm.group(1)))
        else:
            dm = DIRECTIVE.search(line)
            if dm:
                pending = parse_kv(dm.group(1))
        em = ETOGGLE_OPEN.search(line)
        if em:
            in_et = True
            fa = FILE_ATTR.search(em.group(1))
            et_file = fa.group(1) if fa else "script.sw"
        if "</ErrorToggle>" in line:
            in_et = False
            et_file = None
        tm = TEMPLATE_OPEN.search(line)
        if tm:
            slot = tm.group(1)
        if "</template>" in line:
            slot = None
        if line.startswith("#"):
            pending = None
        i += 1
    return items, page_dir


def run_check(workdir, files, addons=True):
    cmd = [SW, "check"] + files
    if addons:
        cmd += ["--addon-path", "."]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=workdir)
    return r.returncode, r.stdout, r.stderr


def main():
    only = sys.argv[1:] or None
    pages = sorted(glob.glob(os.path.join(DOCS, "**", "*.md"), recursive=True))
    pages = [p for p in pages if "/node_modules/" not in p and "/.vitepress/" not in p and "/dist/" not in p and "/1.1.0/" not in p]
    if only:
        pages = [p for p in pages if any(o in p for o in only)]

    shutil.rmtree(WORKROOT, ignore_errors=True)
    total = checked = passed = wrapped = 0
    err_demos = err_demos_exact = 0
    failures = []

    for page in pages:
        items, page_dir = parse_page(page)
        rel = os.path.relpath(page, DOCS)
        sw_items = [it for it in items if it.lang in ("swoftlang", "sw")]
        if not sw_items and "excerpt" not in page_dir:
            continue

        workdir = os.path.join(WORKROOT, rel.replace("/", "__").replace(".md", ""))
        os.makedirs(workdir, exist_ok=True)
        for a in glob.glob(os.path.join(REAL_ADDONS, "*.sw")):
            shutil.copy(a, workdir)

        if "excerpt" in page_dir:
            # check the full source, then verify each fence is a substring
            src = os.path.normpath(os.path.join(os.path.dirname(page), page_dir["excerpt"]))
            shutil.copy(src, workdir)
            rc, so, se = run_check(workdir, [os.path.basename(src)])
            total += 1; checked += 1
            if rc == 0:
                passed += 1
            else:
                failures.append((rel, 0, "excerpt source failed check", se))
            src_text = open(src, encoding="utf-8").read()
            for it in sw_items:
                total += 1; checked += 1
                body = strip_anno(it.code)
                if body.rstrip("\n") in src_text:
                    passed += 1
                else:
                    failures.append((rel, it.lineno, "excerpt fence not a verbatim substring of " + page_dir["excerpt"], ""))
            continue

        deferred = []
        n_anon = 0
        for idx, it in enumerate(items):
            if it.lang not in ("swoftlang", "sw"):
                continue
            d = it.directive or {}
            total += 1
            code = strip_anno(it.code)

            expect_error = bool(d.get("expect") == "error" or (it.slot == "broken" and not d.get("expect")))
            if it.slot == "broken" and "expect" not in d:
                expect_error = True
            if it.slot == "fixed":
                expect_error = False

            name = d.get("name")
            if not name and it.et_file:
                name = it.et_file
            if not name:
                n_anon += 1
                name = "anon_%03d.sw" % n_anon

            wrap_kind = d.get("wrap") or needs_wrap(code)
            if wrap_kind and not expect_error:
                code = wrap(code, wrap_kind)
                wrapped += 1

            with open(os.path.join(workdir, name), "w", encoding="utf-8") as f:
                f.write(code)

            if d.get("defer"):
                deferred.append((it.lineno, name, d))
                continue

            files = [name]
            if d.get("prelude"):
                # concatenate prelude + snippet into one unit
                merged = "merged_" + name
                with open(os.path.join(workdir, merged), "w", encoding="utf-8") as f:
                    f.write(open(os.path.join(workdir, d["prelude"]), encoding="utf-8").read())
                    f.write("\n")
                    f.write(code)
                files = [merged]
            checked += 1
            rc, so, se = run_check(workdir, files, addons=not d.get("noaddons"))

            if not expect_error:
                if rc == 0:
                    passed += 1
                else:
                    failures.append((rel, it.lineno, "expected pass, got exit %d" % rc, se))
                continue

            # error demo
            err_demos += 1
            if rc == 0:
                failures.append((rel, it.lineno, "expected error, but check passed", ""))
                continue
            # find expected text: for ErrorToggle broken panes, the #error slot
            # fence; otherwise the next txt/plain fence before the next
            # swoftlang fence
            expected = None
            if it.slot == "broken":
                for it2 in items[idx + 1:]:
                    if it2.slot == "error" and it2.lang in ("txt", "text", ""):
                        expected = it2.code
                        break
            else:
                for it2 in items[idx + 1:]:
                    if it2.lang in ("swoftlang", "sw"):
                        break
                    if it2.lang in ("txt", "text", "") and "error" in it2.code:
                        expected = it2.code
                        break
            if expected is None:
                failures.append((rel, it.lineno, "error demo has no quoted expected output fence", se))
                continue
            actual = se
            exp = expected.rstrip("\n")
            act = actual.rstrip("\n")
            ok = act.startswith(exp) if d.get("match") == "prefix" else act == exp
            if ok:
                passed += 1
                err_demos_exact += 1
            else:
                failures.append((rel, it.lineno, "error text mismatch", "EXPECTED:\n%s\nACTUAL:\n%s" % (exp, act)))

        for lineno, name, d in deferred:
            checked += 1
            rc, so, se = run_check(workdir, [name], addons=not d.get("noaddons"))
            if rc == 0:
                passed += 1
            else:
                failures.append((rel, lineno, "deferred snippet failed", se))

    print("pages swept: %d" % len(pages))
    print("swoftlang snippets found: %d  checked: %d  passed: %d  (auto-wrapped fragments: %d)" % (total, checked, passed, wrapped))
    print("error demos: %d  byte-exact: %d" % (err_demos, err_demos_exact))
    print("failures: %d" % len(failures))
    for rel, lineno, why, detail in failures:
        print("\n== FAIL %s:%s — %s" % (rel, lineno, why))
        for l in detail.split("\n")[:14]:
            print("   " + l)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
