#!/usr/bin/env bash
# block_dangerous_commands.sh
# Fires: PreToolUse[Bash]
# Purpose: Block or warn on commands that could cause irreversible damage.
#
# Claude Code passes hook context via stdin as JSON (not env vars).
# PreToolUse JSON shape:
#   { "hook_event_name": "PreToolUse", "tool_name": "Bash",
#     "tool_input": { "command": "..." }, ... }

set -euo pipefail

# Read the full stdin JSON once — stdin can only be consumed once.
HOOK_INPUT=$(cat)

COMMAND=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
    exit 0
fi

# --- Absolute blocks (exit code 2 = block the tool call) ---

BLOCKED_PATTERNS=(
    "rm -rf /"
    "rm -rf ~"
    "mkfs"
    "fdisk"
    "dd if="
    "curl.*[|].*sh"     # pipe curl output to shell (e.g. curl url | sh); [|] = literal pipe in ERE
    "wget.*[|].*sh"     # pipe wget output to shell (e.g. wget -O- url | sh)
    "DROP TABLE"
    "DROP DATABASE"
    "TRUNCATE TABLE"
    "git reset --hard"
    "git clean -fd"
    "git clean -f"
    "kill -9 -1"
    "killall"
    ":(){:|:&};:"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
        echo "[HOOK] BLOCKED: Dangerous command pattern detected: $pattern" >&2
        echo "[HOOK] Command: $COMMAND" >&2
        echo "[HOOK] This command requires explicit user confirmation. Do not retry automatically." >&2
        exit 2
    fi
done

# Force-push: block --force and -f, but explicitly allow --force-with-lease.
# Check for the flags anywhere in the command (not just immediately after "git push")
# so that "git push origin --force" and "git push origin main -f" are also caught.
# Pattern anchors on word boundaries (space or start/end) to avoid matching
# substrings of other flags (e.g. --force-with-lease is excluded separately).
if echo "$COMMAND" | grep -qiE "git push"; then
    if echo "$COMMAND" | grep -qiE "(^|[[:space:]])(--force|-f)([[:space:]]|$)" \
       && ! echo "$COMMAND" | grep -q "force-with-lease"; then
        echo "[HOOK] BLOCKED: git push --force / -f is forbidden without explicit confirmation." >&2
        echo "[HOOK] If a force-push is truly needed, use --force-with-lease for safety." >&2
        echo "[HOOK] Command: $COMMAND" >&2
        exit 2
    fi
fi

# --- Confirmation-required patterns (warn, do not block) ---

WARN_PATTERNS=(
    "npm publish"
    "cargo publish"
    "pip upload"
    "twine upload"
    "docker push"
    "git tag"
    "heroku"
    "terraform apply"
    "terraform destroy"
)

for pattern in "${WARN_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
        echo "[HOOK] WARNING: High-impact command requires explicit confirmation: $pattern" >&2
        echo "[HOOK] Command: $COMMAND" >&2
        exit 0
    fi
done

exit 0
