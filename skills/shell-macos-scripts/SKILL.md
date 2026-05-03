---
name: shell-macos-scripts
description: >-
  macOS-native shell scripting: sips, osascript, pbpaste/pbcopy, security
  keychain, launchctl, defaults, networksetup. Also covers: LLM-from-shell
  patterns (ask-claude.sh delegate design, curl+python3 JSON), three-way input
  (file/stdin/interactive), and sed gotchas on macOS. Triggers: macOS script,
  sips, osascript, notification from shell, clipboard, keychain, launchd,
  AI shell tool, ask-claude, shell LLM wrapper.
---

# shell-macos-scripts

## What this is

Patterns for writing shell scripts that use macOS-native tools and integrate with LLM APIs. Complements `shell-csv-pipelines` (general bash safety) — read that first; this adds the macOS-specific layer.

## When to use

- Script uses `sips`, `osascript`, `pbpaste`, `security`, `launchctl`, or `networksetup`
- Building a shell wrapper around an LLM API (Claude, OpenAI)
- Need a consistent stdin / file / interactive input pattern
- Hit a `sed` or `date` failure on macOS that works on Linux

## Reference

- **[reference.md](reference.md)** — macOS tool patterns, LLM-from-shell design, three-way input, sed gotchas.

## Related

- **shell-csv-pipelines** — general bash safety rules, read first
- **llm-integrations-safety** — LLM safety in Python/production code
- **secrets-management** — API key handling
