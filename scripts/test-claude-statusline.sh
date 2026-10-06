#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
statusline="$repo_root/claude/statusline-command.sh"
test_cache="$(mktemp -d)"
trap 'rm -rf "$test_cache"' EXIT

render() {
  local tokens="$1" percentage="$2"
  jq -nc \
    --arg cwd "$repo_root" \
    --argjson tokens "$tokens" \
    --argjson percentage "$percentage" \
    '{
      model: {display_name: "Claude"},
      workspace: {current_dir: $cwd},
      context_window: {
        used_percentage: $percentage,
        total_input_tokens: $tokens
      }
    }' |
    COLUMNS=200 TMPDIR="$test_cache" bash "$statusline"
}

assert_token_color() {
  local tokens="$1" percentage="$2" label="$3" color="$4" output expected
  output="$(render "$tokens" "$percentage")"
  expected=$(printf '\033[38;5;%sm%s\033[0m' "$color" "$label")
  if [[ "$output" != *"$expected"* ]]; then
    printf 'Expected %s tokens to render %s using color %s.\n' \
      "$tokens" "$label" "$color" >&2
    return 1
  fi
}

# Token pressure is independent of context-window percentage: a 1M-token
# model must still warn before a prompt crosses the 100k operational limit.
assert_token_color 69999 7 69.9k 114
assert_token_color 70000 7 70.0k 221
assert_token_color 85000 9 85.0k 215
assert_token_color 100000 10 100k 209
assert_token_color 350000 35 350k 209

printf 'Claude status-line tests passed.\n'
