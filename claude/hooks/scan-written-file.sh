#!/bin/bash
# PostToolUse hook: scans a file for secrets after Claude's write/edit tools.
#
# Non-blocking (exit 0 always) — surfaces findings via additionalContext so
# the model sees them and can course-correct immediately. Shell commands can
# also change files without triggering this hook, so pre-commit and CI remain
# the authoritative repository-wide secret checks.
#
# Deliberately reuses gitleaks (and the nearest project .gitleaks.toml, when
# present) instead of hand-rolling a weaker regex scanner. This is the same
# secret-detection engine run by this repo's Git hooks and CI. The approach was
# inspired by the *concept* of
# luongnv89/claude-howto's 06-hooks/security-scan.sh (a PostToolUse
# secret-scan hook), but not its sed-based detection rules, since this repo
# already has a stronger, actively-maintained rule set.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  exit 0
fi

# Find the nearest .gitleaks.toml by walking up from the file's directory,
# so this hook behaves consistently whether the file is in this dotfiles
# repo or another repo that has its own .gitleaks.toml.
if ! CONFIG_DIR=$(cd -P "$(dirname "$FILE_PATH")" 2>/dev/null && pwd -P); then
  exit 0
fi
CONFIG_PATH=""
while :; do
  if [ -f "$CONFIG_DIR/.gitleaks.toml" ]; then
    CONFIG_PATH="$CONFIG_DIR/.gitleaks.toml"
    break
  fi
  PARENT_DIR=$(dirname "$CONFIG_DIR")
  [ "$PARENT_DIR" = "$CONFIG_DIR" ] && break
  CONFIG_DIR="$PARENT_DIR"
done

# Use `stdin` mode, not `dir` mode: `gitleaks dir` was observed to miss
# matches that `gitleaks stdin` catches for the exact same content (tested
# against this repo's own aws-access-key rule, gitleaks v8.30.1) — feed the
# file content through stdin instead of pointing gitleaks at the path.
GITLEAKS_ARGS=(stdin --no-banner --report-format json --report-path -)
if [ -n "$CONFIG_PATH" ]; then
  GITLEAKS_ARGS+=(--config "$CONFIG_PATH")
fi

REPORT=$(gitleaks "${GITLEAKS_ARGS[@]}" < "$FILE_PATH" 2>/dev/null)

FINDING_COUNT=$(echo "$REPORT" | jq -r 'if type == "array" then length else 0 end' 2>/dev/null)

if [ -z "$FINDING_COUNT" ] || [ "$FINDING_COUNT" = "0" ] || [ "$FINDING_COUNT" = "null" ]; then
  exit 0
fi

SUMMARY=$(printf '%s' "$REPORT" | jq -r '[.[] | "- \(.RuleID // "unknown-rule") at line \(.StartLine // "?")"] | join("\n")' 2>/dev/null)

jq -nc \
  --arg count "$FINDING_COUNT" \
  --arg path "$FILE_PATH" \
  --arg summary "$SUMMARY" \
  '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: (
        "gitleaks flagged \($count) finding(s) in \($path) " +
        "(using the nearest .gitleaks.toml when present, otherwise defaults):\n\($summary)\n" +
        "Review before committing — this hook is a non-blocking warning. " +
        "Run pre-commit or gitleaks before the commit if no project hook is installed."
      )
    }
  }'

exit 0
