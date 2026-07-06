#!/usr/bin/env bash
# completion-contract.sh
# Fires: PostToolUse[Bash] — after any bash command
# Purpose: When a TEST RUNNER command produces failure output, block the
# next tool call so the agent cannot proceed without addressing the failure.
#
# Scope: ONLY fires for commands that look like test runners. Generic commands
# that incidentally emit "error:" or "ERROR" (git, npm install, docker) are
# excluded to avoid false positives.
#
# Exit codes:
#   0 — no issue (or not a test runner command)
#   2 — test runner produced failure output; block next Bash call
#
# Claude Code passes hook context via stdin as JSON (not env vars).
# PostToolUse[Bash] JSON shape:
#   { "hook_event_name": "PostToolUse", "tool_name": "Bash",
#     "tool_input": { "command": "..." },
#     "tool_response": { "output": "...", "exitCode": N }, ... }

set -euo pipefail

[ -f "${HOME}/.claude/config.env" ] && source "${HOME}/.claude/config.env"

# ── Extract command and output from stdin JSON ────────────────────────────────
# Read stdin once at the top — it can only be consumed once per invocation.

HOOK_INPUT=$(cat)

COMMAND=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

OUTPUT=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    resp = data.get('tool_response', {})
    # Try common field names for Bash output across Claude Code versions
    out = resp.get('output', '') or resp.get('content', '') or resp.get('stdout', '')
    if isinstance(out, list):
        out = ' '.join(str(item) for item in out)
    print(str(out)[:4000])
except Exception:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$COMMAND" || -z "$OUTPUT" ]]; then
    exit 0
fi

# ── Scope: only act on test-runner commands ───────────────────────────────────
# This prevents false positives from git errors, docker logs, npm output, etc.

TEST_RUNNER_PATTERNS=(
    "pytest"
    "python -m pytest"
    "python -m unittest"
    "npm test"
    "npm run test"
    "yarn test"
    "pnpm test"
    "go test"
    "cargo test"
    "mvn test"
    "gradle test"
    "jest"
    "vitest"
    "mocha"
    "rspec"
    "bundle exec rspec"
    "dotnet test"
    "phpunit"
)

IS_TEST_RUNNER=0
for pattern in "${TEST_RUNNER_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qiE "(^|[[:space:]]|&&|\|\|)${pattern}([[:space:]]|$)"; then
        IS_TEST_RUNNER=1
        break
    fi
done

if [[ "$IS_TEST_RUNNER" -eq 0 ]]; then
    exit 0
fi

# ── Failure detection (test-runner specific markers) ─────────────────────────

FAILURE_MARKERS=(
    "FAILED"
    "FAILURES"
    "AssertionError"
    "AssertionFailed"
    "SyntaxError"
    "ImportError"
    "ModuleNotFoundError"
    "[1-9][0-9]* failed"
    "Tests run:.*Failures: [1-9]"
    "Tests run:.*Errors: [1-9]"
    "FAIL\b"
    "test.*FAILED"
    "ERROR.*test"
)

RED_FOUND=0
RED_MARKER=""
for marker in "${FAILURE_MARKERS[@]}"; do
    if echo "$OUTPUT" | grep -qE "$marker"; then
        RED_FOUND=1
        RED_MARKER="$marker"
        break
    fi
done

if [[ "$RED_FOUND" -eq 1 ]]; then
    echo "[HOOK] completion-contract: Test runner failure detected (matched: ${RED_MARKER})" >&2
    echo "[HOOK] Do not proceed — diagnose and fix the failure before the next step." >&2
    echo "[HOOK] Use the language-appropriate test failure debugging skill (see CLAUDE.md Skill Invocation Guide)." >&2
    exit 2
fi

exit 0
