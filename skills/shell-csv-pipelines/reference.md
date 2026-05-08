# Shell scripting for text and CSV (reference)

If your org keeps a **shared** `unix-shell` or `scripts/csv` tree, use its **README** as a concrete index. This file is the **portable** habits and rules for **any** similar pipeline.

---

## 1. Script header and options

- Use **`#!/usr/bin/env bash`** when you need bash features (`[[`, arrays, `[[ -v var ]]`, `pipefail`). Use **`#!/bin/sh`** only for **strictly POSIX** scripts you have tested on both macOS and Linux.
- **Always** start **non-trivial** scripts with:

  ```bash
  set -euo pipefail
  ```

  - **`-e`** — exit on first command failure (don’t ignore errors).
  - **`-u`** — error on use of unset variables (catches typos).
  - **`-o pipefail`** — pipeline fails if *any* stage fails (not only the last).

  **Exception:** the smallest one-liner wrappers or legacy scripts that you are not allowed to change; if you use only `set -e`, know that **assignments** and **tests** in `if` do not always behave the way you expect with `-e`—test your paths.

- Put **`set -euo pipefail` immediately after the shebang** (and after any file-level comment block if you use one), before other code.

---

## 2. Quoting and word splitting

- **Double-quote every variable** unless you intend word splitting: `"$file"`, `"$dir"`, `"$line"`, not `$file`.
- **Never** build commands with unquoted user or file content: `rm $x` and `command $arg` are wrong; use `rm -- "$x"` and `command -- "$arg"`.
- Use **`[[ ... ]]`** in bash for string tests; avoid `[` for complex cases. Prefer `[[ -f "$path" ]]` not `[ -f $path ]`.
- **Don't** rely on `echo` for arbitrary data: **`printf '%s\n' "$var"`** is safe for format surprises.
- **Read lines** with `while IFS= read -r line; do ...; done < file` (or from a process substitution), not `for line in $(cat file)` (breaks on spaces, globs, and performance).

---

## 3. Paths, globs, and `find`

- **Expand globs** only when you mean it: `*.csv` in the script directory is not the same as user input. For user-provided patterns, be explicit (validated path or `find`).
- **Never** parse `ls` output. Use `find`, glob arrays in bash, or a **while read** over `find -print0` + `read -d ''`.
- **`find` + `exec`:** prefer `find ... -print0 | xargs -0 command` or `find ... -exec ... {} +` for many files. Avoid `find | while read` with default newline delimiter if paths can contain newlines (rare in internal CSV trees; still use `-0` in robust tools).
- Use **`--`** before pathnames that could start with `-` when passing to commands: `command -- "$path"`.

---

## 4. Conventions (team / operator stability)

A typical internal `unix-shell` or `scripts/` tree uses rules like:

| Rule | Why |
|------|-----|
| **Column index 1-based** | Matches `cut -f` and team muscle memory. |
| **Default delimiter** often **comma**; override with a final arg where scripts support it. | Same as `cut` mental model. |
| **Default to stdout**; optional output path or **`-o`** for file. | Easy to pipe and debug. |
| **Accept `-` for stdin** where documented. | Composes in pipelines. |
| **Usage text** in `Usage: ...` on bad args; exit **non-zero**. | Consistent CLI feel. |
| **Meaningful script names** under `csv/`, `list/`, `jira/`, `system/`. | Don't scatter one-offs at repo root. |

When a script **already exists** in your org’s tree, **extend or call it** instead of copying a 20-line variant.

---

## 5. Pipelines: `cut`, `awk`, `grep`, `sort`, `uniq`

- **`cut -d` / `-f`:** 1-based fields; delimiter is a **single character**; for multi-char delimiters you need `awk` or a different design.
- **`awk`:** set `FS`/`OFS` for delimiters; use for column stats, filters, and keyed uniqueness when `sort | uniq` is not enough. Keep `awk` blocks in small files or functions so you can add a one-line comment on **field numbers**.
- **`grep`:** use **`grep -E`** for extended regex when you need it; **`grep -F`** for fixed strings (faster, fewer escape surprises). Know that **return code 1** means “no match,” not always an error—don’t `set -e` a pipeline that treats “no lines” as success without `|| true` where appropriate.
- **`sort | uniq` vs `sort -u`:** use **`-u`** for unique lines; use **`uniq -c`** when you need counts. Sort before `uniq` if not already sorted.
- **Avoid** `cat file | command` when `command < file` or `command file` works (fewer processes, clearer).

---

## 6. Subshells, errors, and `|| true`

- If you need to **allow** a command to fail without aborting the script, be explicit: `command || true` or `if ! command; then ...; fi`—and **comment why** (e.g. “optional file”).
- For pipelines where you need the exit status of an **earlier** stage, use a **named pipe** or **PIPESTATUS** in bash, or restructure; don’t assume the last command’s status is enough when `pipefail` is on.

---

## 7. Environment and secrets

- **No secrets in scripts** (tokens, internal URLs with embedded keys). Pass via **env vars** or a **config file** read by a program that is not world-readable in your threat model.
- **Don’t** `export` credentials needlessly; scope variables to the script.
- If you `curl` or `ssh` in shell, use the same rules as in **python-scripts-and-services** / **security.md** (no tokens in URLs, timeouts, don’t log bodies).

---

## 8. Portability (macOS + Linux)

- Prefer **bash 3.2+** on macOS (default `/bin/bash` is old); avoid **bash 4+ only** features unless the repo documents **Homebrew bash** or **GNU tools** as a requirement.
- For **`sed` / `awk` / `date`**, GNU vs BSD differ; for anything non-trivial, test on **both** or centralize the logic in **Python**.
- **`sed -i` on macOS requires an empty backup extension:** `sed -i '' 's/foo/bar/' file` — omitting `''` is a syntax error on BSD sed.
- **Multiline `sed` replacements are unreliable on macOS.** If you need to insert a multi-line block (e.g. before `</head>`), use Python: `python3 -c "import pathlib; p=pathlib.Path('f'); p.write_text(p.read_text().replace('X','Y',1))"`. See **shell-macos-scripts** for the full pattern.
- **Use `mktemp`** for temp files, not `/tmp/$RANDOM` alone.

```bash
tmp=$(mktemp) || exit 1
trap 'rm -f -- "$tmp"' EXIT
```

---

## 9. `xargs` and large argument lists

- Use **`xargs -0`** with `find -print0` to handle spaces in paths.
- Know **`xargs` default behavior** on macOS (line length limits, sometimes `echo`); for critical batching, test with your largest realistic input.

---

## 10. Testing and static analysis

- Run **[ShellCheck](https://www.shellcheck.net/)** on new scripts before review: `shellcheck script.sh` (or your editor integration).
- For **data transforms**, keep a **tiny sample file** in `tests/` or `examples/` and document one command that must produce the same hash or line count (even if you don’t automate CI for shell yet).
- **Dry-run** destructive operations: when a script might **overwrite** a file, support **`-n`**, **stdout-only default**, or require an explicit **output** path.

---

## 11. Style

- **Functions** for repeated blocks; **local** variables in functions: `local var=...` (bash).
- **Uppercase** for **environment-backed** or **exported** vars; **lowercase** for locals is a common convention.
- **Indent** with two spaces; keep lines readable (avoid 300-character one-liners—use a here-doc or `awk` file for heavy logic).
- **Comments** at the top: what the script does, **usage**, and any **non-obvious** delimiter or column.

---

## 12. Ties to Python and Jira

- **Read-only** shaping of Jira **exports** in shell is fine; **Jira writes** (REST, PAT, allowlists) belong in **Python** with tests—see **python-scripts-and-services** and **jira.md** there.
- If the pipeline grows **regex** that must stay in sync with product behavior, that’s a sign to **move the rule** into a **Python** module and call it from CI.

---

## Checklist (before you merge a new script)

- [ ] `set -euo pipefail` (or documented exception)
- [ ] Quoted variables; `read -r`; `printf` over `echo` for data
- [ ] No `ls` parsing; safe `find` / globs
- [ ] Usage + non-zero exit on bad args; `-` for stdin if applicable
- [ ] ShellCheck clean (or waivers explained in a comment)
- [ ] No secrets; temp files with `mktemp` + `trap` when needed
- [ ] Tested on **target** OS (macOS and/or Linux as required by the repo)
