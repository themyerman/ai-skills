# ai-skills

Personal collection of Claude/Cursor agent skill docs covering web development, Python tooling, security, writing, and visual design.

Skills live in `skills/<name>/` as markdown files. Each skill has a `SKILL.md` (entry point) and one or more topic reference files.

## How it's wired up

`~/.claude/ai-skills` symlinks to this repo, so Claude Code picks up the skills automatically across all projects via `~/.claude/CLAUDE.md`.

For Cursor, run the installer script to symlink skills into a workspace:

```bash
./scripts/install-cursor-symlinks.sh /path/to/your/workspace
```

## Skills

| Skill | What it covers |
|-------|----------------|
| [web-frontend-basics](skills/web-frontend-basics/SKILL.md) | Semantic HTML, forms, small JS, fetch |
| [web-layout-css](skills/web-layout-css/SKILL.md) | Flex/grid, responsive, tables/cards, print |
| [web-accessibility](skills/web-accessibility/SKILL.md) | WCAG habits, keyboard, ARIA, contrast, motion |
| [docs-clear-writing](skills/docs-clear-writing/SKILL.md) | READMEs, install guides, plain English, runbooks |
| [python-internal-tools](skills/python-internal-tools/SKILL.md) | Project structure, config, DB, testing, Flask, CLI |
| [llm-integrations-safety](skills/llm-integrations-safety/SKILL.md) | LLM mock clients, prompt injection, I/O screening |
| [data-handling-pii](skills/data-handling-pii/SKILL.md) | PII classification, minimization, safe logs/exports |
| [secrets-management](skills/secrets-management/SKILL.md) | Credentials, CI, leak response |
| [shell-csv-pipelines](skills/shell-csv-pipelines/SKILL.md) | Bash/awk on CSVs, `set -euo pipefail`, ShellCheck |
| [executive-reports](skills/executive-reports/SKILL.md) | BLUF structure, plain English for leadership |
| [using-ai-assistants](skills/using-ai-assistants/SKILL.md) | Working effectively with AI in the editor |
| [shift-left-program](skills/shift-left-program/SKILL.md) | Security champions, CI defaults, escalation |
| [visual-design](skills/visual-design/SKILL.md) | Print production (DPI, color, bleed, formats) and design feedback vocabulary |
| [product-writing](skills/product-writing/SKILL.md) | Specs/PRDs, acceptance criteria, decision records (ADRs) |
| [indigenous-art-americas](skills/indigenous-art-americas/SKILL.md) | Indigenous art of the Americas — pre-contact to contemporary, all regions |
| [indigenous-bias-awareness](skills/indigenous-bias-awareness/SKILL.md) | Anti-Indigenous bias in professional contexts — terms, behaviors, historical context |

## Adding a skill

1. Create `skills/<new-skill-name>/SKILL.md` (add `reference.md` and other topic files as needed).
2. Add a row to the table above.
3. Add an entry to `global-claude.md` (symlinked from `~/.claude/CLAUDE.md`).
4. Re-run `scripts/install-cursor-symlinks.sh` if you use Cursor.

## License

MIT — see [LICENSE](LICENSE).
