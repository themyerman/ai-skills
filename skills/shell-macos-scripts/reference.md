# macOS shell scripting (reference)

Assumes you've read **shell-csv-pipelines/reference.md** for the baseline bash safety rules. This file covers the macOS-specific layer.

---

## 1. macOS-native image tools: `sips`

`sips` (Scriptable Image Processing System) ships with macOS — no Homebrew needed for resize, convert, and crop.

```bash
# Resize to max width (preserves aspect ratio)
sips --resampleWidth 1600 input.png --out output.jpg

# Convert PNG → JPEG at 85% quality
sips -s format jpeg -s formatOptions 85 input.png --out output.jpg

# Crop to exact dimensions from an offset (height width offset-y offset-x)
sips --cropToHeightWidth 630 1200 --cropOffset 100 550 input.jpg --out og-image.jpg

# Batch convert a folder
for f in *.png; do
  sips -s format jpeg -s formatOptions 85 "$f" --out "${f%.png}.jpg"
done
```

Key gotchas:
- `--cropOffset` takes **Y offset first, then X** (row, column order — opposite of what you might expect)
- Output file must differ from input; sips overwrites if same name and format
- For watermarks or compositing, you need ImageMagick — `sips` can't composite

---

## 2. Notifications and AppleScript: `osascript`

```bash
# Simple notification
osascript -e 'display notification "Build done" with title "MyScript"'

# With sound
osascript -e 'display notification "Done" with title "Backup" sound name "Glass"'

# Dialog with buttons (returns button name)
result=$(osascript -e 'button returned of (display dialog "Continue?" buttons {"Cancel", "OK"} default button "OK")')

# Open a file in default app
open -a "TextEdit" "$file"

# Speak text
say "Your backup is complete"
```

When embedding variables, build the AppleScript string carefully to avoid injection:

```bash
# Safe — escape the variable content
msg=$(printf '%s' "$user_message" | sed "s/\"/'/g")
osascript -e "display notification \"${msg}\" with title \"Alert\""

# Better for complex content — use a heredoc
osascript <<EOF
display notification "$msg" with title "Alert"
EOF
```

---

## 3. Clipboard: `pbpaste` / `pbcopy`

```bash
# Read from clipboard
text=$(pbpaste)

# Write to clipboard
echo "hello" | pbcopy
printf '%s' "$result" | pbcopy   # safer for arbitrary content

# Common pattern in ai/ scripts: accept file, stdin, or clipboard
if [[ -n "$1" && -f "$1" ]]; then
  TEXT=$(cat "$1")
elif ! [ -t 0 ]; then
  TEXT=$(cat)
else
  echo "Paste your content below, then press Ctrl-D:"
  TEXT=$(cat)
fi
```

---

## 4. Three-way input pattern

Every well-behaved utility script should accept input three ways. Use this boilerplate:

```bash
FILE="$1"

if [[ -n "$FILE" && -f "$FILE" ]]; then
  TEXT=$(cat "$FILE")
elif ! [ -t 0 ]; then
  # stdin is a pipe or redirect
  TEXT=$(cat)
else
  # interactive: prompt the user
  echo "Paste your content below, then press Ctrl-D:"
  TEXT=$(cat)
fi

if [[ -z "$TEXT" ]]; then
  echo "Usage: $(basename "$0") <file>"
  echo "       echo \"content\" | $(basename "$0")"
  exit 1
fi
```

`! [ -t 0 ]` checks whether stdin is a terminal — false when piped or redirected, so it's the right guard for "are we in a pipeline."

---

## 5. Keychain: `security`

Read saved WiFi passwords and stored credentials without hardcoding secrets:

```bash
# Read a WiFi password (requires user approval first time)
password=$(security find-generic-password -wa "NetworkName" 2>/dev/null)

# Read an internet password (e.g. stored API key)
api_key=$(security find-internet-password -a "myaccount" -s "api.example.com" -w 2>/dev/null)

# Store a secret
security add-generic-password -a "$USER" -s "my-script-token" -w "secret-value"
```

Prefer keychain over `~/.env` files for secrets used by shell scripts — keychain is encrypted and access-controlled.

---

## 6. launchd / `launchctl`

```bash
# List all loaded agents for current user
launchctl list

# Load a user agent
launchctl load ~/Library/LaunchAgents/com.example.myjob.plist

# Unload
launchctl unload ~/Library/LaunchAgents/com.example.myjob.plist

# Read a value from a plist (e.g. to display in a script)
defaults read /Library/LaunchDaemons/com.example.daemon.plist Label
```

Minimal launchd plist for a repeating job (every 3600 seconds):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>       <string>com.yourname.myjob</string>
  <key>ProgramArguments</key>
  <array><string>/Users/you/scripts/myjob.sh</string></array>
  <key>StartInterval</key> <integer>3600</integer>
  <key>RunAtLoad</key>     <true/>
</dict>
</plist>
```

---

## 7. WiFi and networking: `networksetup` / `airport`

```bash
# Current WiFi network name
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/{print $2}'

# Or with networksetup (more reliable on newer macOS)
networksetup -getairportnetwork en0

# List all network services
networksetup -listallnetworkservices

# Get current IP
ipconfig getifaddr en0

# Public IP (requires internet)
curl -sf https://api.ipify.org
```

---

## 8. macOS `sed` and `date` gotchas

**`sed` on macOS is BSD sed — it differs from GNU sed in two important ways:**

1. **In-place editing requires a backup extension** (even if empty):
   ```bash
   # Linux (GNU): sed -i 's/foo/bar/' file
   # macOS (BSD): sed -i '' 's/foo/bar/' file
   ```

2. **Multiline replacements with `sed` are unreliable on macOS.** If you need to insert or replace across multiple lines (e.g. inserting a multi-line HTML block before `</head>`), use Python instead:
   ```bash
   python3 -c "
   import pathlib
   p = pathlib.Path('file.html')
   p.write_text(p.read_text().replace('</head>', '${SNIPPET}\n</head>', 1))
   "
   ```

**`date` on macOS is BSD date — it also differs:**

```bash
# GNU (Linux): date -d "yesterday"
# macOS (BSD): date -v-1d

# GNU: date --date="2024-01-15" +%s
# macOS: date -j -f "%Y-%m-%d" "2024-01-15" +%s
```

When portability matters, use Python's `datetime` instead of shell `date`.

---

## 9. LLM from shell: the delegate pattern

When building multiple AI-powered scripts, put all the curl/auth/JSON logic in one base script and have others call it. This keeps each tool focused and makes key/model changes a one-file fix.

**Base script structure (`ask-claude.sh`):**

```bash
#!/usr/bin/env bash
MODEL="${CLAUDE_MODEL:-claude-haiku-4-5-20251001}"

[[ -z "$ANTHROPIC_API_KEY" ]] && { echo "Error: ANTHROPIC_API_KEY not set"; exit 1; }

# Accept prompt from args or stdin
if [[ -n "$1" ]]; then PROMPT="$*"
elif ! [ -t 0 ]; then PROMPT=$(cat)
else echo "Usage: ask-claude.sh \"prompt\""; exit 1
fi

# Encode prompt safely with python (handles quotes, newlines, unicode)
json_prompt=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))' <<< "$PROMPT")

response=$(curl -sf https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{\"model\":\"$MODEL\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":${json_prompt}}]}")

# Parse with python heredoc (handles nested JSON safely)
python3 - "$response" <<'EOF'
import sys, json
data = json.loads(sys.argv[1])
if 'content' in data:
    for block in data['content']:
        if block.get('type') == 'text':
            print(block['text'])
elif 'error' in data:
    print('API error:', data['error'].get('message', ''))
EOF
```

**Delegate scripts call it directly:**

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASK="${SCRIPT_DIR}/ask-claude.sh"

"$ASK" "Summarize this in 3 bullets: ${content}"
```

**Why `python3` for JSON encoding (not `jq` or string interpolation):**
- Single quotes, double quotes, newlines, and unicode in user content will break bare string interpolation
- `python3` is always available on macOS; `jq` requires Homebrew
- A one-liner `python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'` is safe for any input

**Why `python3` heredoc for parsing (not `grep`/`awk`):**
- JSON responses may have nested structures, escaped characters, or multi-block content arrays
- Python's `json.loads` handles all edge cases; `grep '"text"'` breaks on long responses

---

## 10. Truncation for large inputs

LLM APIs have context limits. For file-based scripts, truncate before sending:

```bash
content=$(cat "$FILE")
if (( ${#content} > 12000 )); then
  content="${content:0:12000}"
  echo "(Note: input truncated to 12,000 characters for API)"
fi
```

12,000 characters ≈ 3,000 tokens — leaves room for the prompt and response within most models' limits.

---

## Checklist (macOS script additions)

- [ ] `sips` crop offsets are in Y,X order (not X,Y)
- [ ] `sed -i ''` (BSD in-place) not `sed -i` (GNU)
- [ ] Multiline insert/replace → Python, not sed
- [ ] `date` operations → Python `datetime` if cross-platform
- [ ] Three-way input: file → stdin → interactive
- [ ] Secrets via `security` keychain, not dotfiles
- [ ] LLM JSON encoding and parsing via `python3`, not string interpolation
- [ ] Truncate large file inputs before sending to API
