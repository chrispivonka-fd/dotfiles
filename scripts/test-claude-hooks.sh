#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
GIT_GUARD="$ROOT_DIR/claude/hooks/block-dangerous-git.sh"
SECRET_SCANNER="$ROOT_DIR/claude/hooks/scan-written-file.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

decision_for() {
  local command_text="$1"
  local output decision

  output=$(
    printf '%s' "$command_text" |
      jq -Rs '{tool_input: {command: .}}' |
      "$GIT_GUARD" 2>&1
  ) || fail "Git guard failed while inspecting: $command_text"

  if [ -z "$output" ]; then
    printf 'passthrough\n'
    return
  fi

  decision=$(printf '%s' "$output" | jq -er '
    .hookSpecificOutput
    | select(.hookEventName == "PreToolUse")
    | select(.permissionDecisionReason | type == "string" and length > 0)
    | .permissionDecision
    | select(. == "ask" or . == "deny")
  ') || fail "Git guard returned invalid decision JSON for: $command_text"
  printf '%s\n' "$decision"
}

assert_decision() {
  local expected="$1"
  local command_text="$2"
  local actual

  actual=$(decision_for "$command_text")
  if [ "$actual" != "$expected" ]; then
    fail "expected '$expected' for '$command_text', got '$actual'"
  fi
}

# Ordinary and documentation-only commands pass through to normal permissions.
assert_decision passthrough 'git status'
assert_decision passthrough 'git switch feature/topic'
assert_decision passthrough 'git stash list'
assert_decision passthrough 'git tag -n 10'
assert_decision passthrough 'git push origin topic--force'
assert_decision passthrough 'git -c commit.gpgSign=true commit'
assert_decision passthrough 'git commit -m "docs: explain --no-verify"'
assert_decision passthrough 'gcm "docs: explain --no-verify"'
assert_decision passthrough 'gcm --no-verify'
assert_decision passthrough 'gcm -n'
assert_decision passthrough 'echo "git reset --hard HEAD~1"'
assert_decision passthrough 'printf "git push --force"'
assert_decision passthrough 'gpg --no-sign artifact'
assert_decision passthrough 'gpg --no-verify artifact'
assert_decision passthrough 'gbrain -f topic'
assert_decision passthrough 'gprofile --force x'
assert_decision passthrough 'grbuild --no-verify'
assert_decision passthrough 'gcman --no-sign'
assert_decision passthrough 'github reset --hard HEAD~1'
assert_decision passthrough 'git grep "git reset --hard"'
assert_decision passthrough 'git log -S"git reset --hard"'

# Recoverable but consequential operations require a real human checkpoint.
assert_decision ask 'git checkout feature/topic'
assert_decision ask 'git co README'
assert_decision ask 'gco release-1.2'
assert_decision ask 'git restore --staged README.md'
assert_decision ask 'git reset --soft HEAD~1'
assert_decision ask 'git reset topic--hard'
assert_decision ask 'git clean -n'
assert_decision ask 'git clean -n -- foo--force'
assert_decision ask 'git branch -d merged-feature'
assert_decision ask 'git branch merged-feature -d'
assert_decision ask 'git branch -d topic--force'
assert_decision ask 'git br --delete merged-feature'
assert_decision ask 'gbd merged-feature'
assert_decision ask 'git stash drop'
assert_decision ask 'gst clear'
assert_decision ask 'git push --force-with-lease origin topic'
assert_decision ask 'git push origin topic --force-with-lease'
assert_decision ask 'gpf origin topic'
assert_decision ask 'gpo --force-with-lease topic'
assert_decision ask 'git push --delete origin topic'
assert_decision ask 'git push -d origin topic'
assert_decision ask 'git push origin -d topic'
assert_decision ask 'gp -d origin topic'
assert_decision ask 'gpo -d topic'
assert_decision ask 'gp :topic'
assert_decision ask 'gpo :topic'
assert_decision ask 'gp origin :topic'
assert_decision ask 'git switch --force topic'
assert_decision ask 'git switch -f topic'
assert_decision ask 'git tag -d v1.0.0'
assert_decision ask 'git tag --delete v1.0.0'
assert_decision ask 'git update-ref -d refs/heads/topic'
assert_decision ask 'git unstage README.md'
assert_decision ask 'git undo'
assert_decision ask 'git cleanup'

# Unbounded deletion, history rewriting, and safeguard bypasses are denied.
assert_decision deny 'git reset --hard HEAD~1'
assert_decision deny 'git reset HEAD~1 --hard'
assert_decision deny 'git -C . reset --hard HEAD~1'
assert_decision deny 'git undo --hard'
assert_decision deny 'git clean -fd'
assert_decision deny 'git clean path -f'
assert_decision deny 'gclean'
assert_decision deny 'git branch -D topic'
assert_decision deny 'git branch topic -D'
assert_decision deny 'git branch -d -f topic'
assert_decision deny 'git branch --force --delete topic'
assert_decision deny 'git branch -df topic'
assert_decision deny 'git branch -f topic HEAD'
assert_decision deny 'git branch --force topic HEAD'
assert_decision deny 'git br -fd topic'
assert_decision deny 'gbd -f topic'
assert_decision deny 'git push --force origin topic'
assert_decision deny 'git push origin topic --force'
assert_decision deny 'gp -uf origin topic'
assert_decision deny 'gpf --force origin topic'
assert_decision deny 'git push --mirror origin'
assert_decision deny 'gpf --mirror origin'
assert_decision deny 'gpf origin --mirror'
assert_decision deny 'git push origin +topic'
assert_decision deny 'gp +topic'
assert_decision deny 'gpo +topic'
assert_decision deny 'gp origin +topic'
assert_decision deny 'gpf +topic'
assert_decision deny 'gpf origin +topic'
assert_decision deny 'gpf --no-force-with-lease +topic'
assert_decision deny 'git grep value; git reset --hard HEAD~1'
# shellcheck disable=SC2016 # Intentional literal substitution for hook input.
assert_decision deny 'git log "$(git reset --hard HEAD~1)"'
assert_decision deny 'git commit --no-verify'
assert_decision deny 'git commit --no-g --dry-run'
assert_decision deny 'git commit --no-si --dry-run'
assert_decision deny 'git commit --no-pos --dry-run'
assert_decision deny 'gca --no-pos'
assert_decision deny 'gca --no-verify'
assert_decision deny 'gcm fix --no-verify'
assert_decision deny 'git push --no-verify'
assert_decision deny 'git rebase --no-verify main'
assert_decision deny 'git am -n patch.mbox'
assert_decision deny 'grbi --no-verify main'
assert_decision deny 'git tag --no-sign v1.0.0'
assert_decision deny 'git tag --no-si v1.0.0'
assert_decision deny 'git cherry-pick --no-gpg-sign abc123'
assert_decision deny 'gcp --no-gpg-sign abc123'
assert_decision deny 'git -c core.hooksPath=. commit'
assert_decision deny 'git -c commit.gpgSign=false commit'
assert_decision deny 'git --config-env=core.hooksPath=HOOKS commit'
assert_decision deny 'git --config-env=commit.gpgSign=SIGN commit'

if printf '{' | "$GIT_GUARD" >/dev/null 2>&1; then
  fail 'Git guard accepted malformed hook input'
fi

# Exercise both file-edit payload shapes without depending on real gitleaks
# rules or introducing a credential-looking fixture into the repository.
TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR/bin"
# shellcheck disable=SC2016 # These literals generate a separate stub script.
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'input=$(cat)' \
  'if [[ "$input" == *FAKE_SECRET_MARKER* ]]; then' \
  '  printf '\''[{"RuleID":"test-secret","StartLine":1}]\n'\''' \
  '  exit 1' \
  'fi' \
  'printf '\''[]\n'\''' \
  > "$TEMP_DIR/bin/gitleaks"
chmod +x "$TEMP_DIR/bin/gitleaks"

printf '{}\n' > "$TEMP_DIR/clean.txt"
clean_output=$(
  jq -nc --arg path "$TEMP_DIR/clean.txt" \
    '{tool_input: {file_path: $path}}' |
    PATH="$TEMP_DIR/bin:$PATH" "$SECRET_SCANNER"
)
[ -z "$clean_output" ] || fail 'secret scanner warned on a clean file_path payload'

printf '{"cells":["FAKE_SECRET_MARKER"]}\n' > "$TEMP_DIR/flagged.ipynb"
notebook_output=$(
  jq -nc --arg path "$TEMP_DIR/flagged.ipynb" \
    '{tool_input: {notebook_path: $path}}' |
    PATH="$TEMP_DIR/bin:$PATH" "$SECRET_SCANNER"
)
printf '%s' "$notebook_output" | jq -e '
  .hookSpecificOutput
  | select(.hookEventName == "PostToolUse")
  | .additionalContext
  | select(contains("test-secret"))
' >/dev/null || fail 'secret scanner did not inspect a notebook_path payload'

printf 'Claude hook tests passed.\n'
