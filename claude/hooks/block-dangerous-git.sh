#!/bin/bash
# PreToolUse hook: blocks or escalates directly spelled risky Git commands.
#
# Adapted from mattpocock/skills' git-guardrails-claude-code skill (MIT),
# https://github.com/mattpocock/skills/tree/main/skills/misc/git-guardrails-claude-code
#
# This is a mechanical backstop for the optional automode profile. It returns a
# structured `deny` for operations that should never run unattended and `ask`
# for recoverable but consequential operations that need a human checkpoint.
# Tracked zsh aliases are covered alongside their canonical spellings.
#
# This inspects command text, not shell semantics. Indirection, user-defined Git
# aliases, and commands hidden inside another program remain the responsibility
# of Auto mode's classifier, the sandbox, recoverable Git state, and remote
# branch protections.
#
# Hardening over the upstream script: quoted data for a tightly limited set of
# non-executing text commands and ordinary commit-message values are ignored,
# while executable arguments remain visible. This keeps `git push "--force"`
# and `bash -lc "git reset --hard ..."` blocked. Heredoc bodies deliberately
# remain subject to matching because they can feed another shell.

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: jq is required to inspect Bash commands safely." >&2
  exit 2
fi

return_decision() {
  local decision="$1"
  local reason="$2"

  jq -nc \
    --arg decision "$decision" \
    --arg reason "$reason" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: $decision,
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

INPUT=$(cat)
if ! COMMAND=$(printf '%s' "$INPUT" | jq -er '.tool_input.command // ""'); then
  echo "BLOCKED: malformed hook input; unable to inspect the Bash command safely." >&2
  exit 2
fi

# Additional pattern (2026-07-15, via wshobson/agents' block-no-verify-hook
# skill, MIT): block --no-verify/--no-gpg-sign, which bypass pre-commit
# hooks and commit signing entirely — a gap the original pattern list
# didn't cover. Their example hook config uses a different (and, in this
# environment, unverified) schema — $TOOL_INPUT env var instead of the
# stdin-JSON tool_input.command this script already reads and has tested
# working live — so only the underlying idea (block these two flags) was
# taken, not their hook wiring.

# Shell line continuations are removed before parsing. Without this,
# `git reset \\` followed by `--hard` evades a same-line pattern.
remove_line_continuations() {
  local input="$1"
  local result=""
  local char next_char
  local index=0

  while [ "$index" -lt "${#input}" ]; do
    char="${input:index:1}"
    next_char="${input:$((index + 1)):1}"
    if [ "$char" = "\\" ] && [ "$next_char" = $'\n' ]; then
      ((index += 2))
      continue
    fi
    result+="$char"
    ((++index))
  done
  printf '%s' "$result"
}

CHECK_COMMAND=$(remove_line_continuations "$COMMAND")

# A single search/print command treats quoted text as data. Use a quote-stripped
# copy only to verify that no command separator, substitution, or process
# substitution can turn that data into executable shell input. Ripgrep and ag
# are excluded because their runner/pager options can execute other commands.
strip_quoted_literals() {
  local input="$1"
  local result=""
  local state="unquoted"
  local char
  local index=0

  while [ "$index" -lt "${#input}" ]; do
    char="${input:index:1}"
    case "$state" in
      unquoted)
        case "$char" in
          "\\")
            # The next character is literal shell data, not a quote or
            # separator. Keep a placeholder so it cannot alter structure.
            result+="_"
            ((index += 2))
            continue
            ;;
          "'") result+="''"; state="single" ;;
          '"') result+='""'; state="double" ;;
          *) result+="$char" ;;
        esac
        ;;
      single)
        [ "$char" = "'" ] && state="unquoted"
        ;;
      double)
        if [ "$char" = "\\" ]; then
          ((index += 2))
          continue
        fi
        [ "$char" = '"' ] && state="unquoted"
        ;;
    esac
    ((++index))
  done

  [ "$state" = "unquoted" ] || return 1
  printf '%s' "$result"
}

if ! STRUCTURE_COMMAND=$(strip_quoted_literals "$CHECK_COMMAND"); then
  # Malformed quoting cannot qualify for the data-only shortcut.
  STRUCTURE_COMMAND="$CHECK_COMMAND"
fi
# shellcheck disable=SC2016 # Match the literal command-substitution opener.
if [[ "$STRUCTURE_COMMAND" =~ ^[[:space:]]*(command[[:space:]]+)?(grep|echo|printf)([[:space:]]|$) ]] \
  && [[ "$STRUCTURE_COMMAND" != *';'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *'&'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *'|'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *$'\n'* ]] \
  && [[ "$CHECK_COMMAND" != *'$('* ]] \
  && [[ "$CHECK_COMMAND" != *'`'* ]] \
  && [[ "$CHECK_COMMAND" != *'<('* ]] \
  && [[ "$CHECK_COMMAND" != *'>('* ]]; then
  exit 0
fi

# A single read-only Git inspection command also treats later Git spellings as
# search or display data. Shell composition and substitutions deliberately do
# not qualify, so `git grep value; git reset --hard` is still inspected below.
# shellcheck disable=SC2016 # Match the literal command-substitution opener.
if [[ "$STRUCTURE_COMMAND" =~ ^[[:space:]]*(command[[:space:]]+)?(git|g)[[:space:]]+(grep|log|show|diff|status)([[:space:]]|$) ]] \
  && [[ "$STRUCTURE_COMMAND" != *';'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *'&'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *'|'* ]] \
  && [[ "$STRUCTURE_COMMAND" != *$'\n'* ]] \
  && [[ "$CHECK_COMMAND" != *'$('* ]] \
  && [[ "$CHECK_COMMAND" != *'`'* ]] \
  && [[ "$CHECK_COMMAND" != *'<('* ]] \
  && [[ "$CHECK_COMMAND" != *'>('* ]]; then
  exit 0
fi

# A commit message may legitimately document a blocked flag. Remove only the
# quoted value attached to -m/--message; a quoted flag supplied directly to Git
# remains present and is still blocked below. Never discard a value containing
# command or process substitution because the shell executes it before Git.
# shellcheck disable=SC2016 # Match the literal command-substitution opener.
if [[ "$CHECK_COMMAND" != *'$('* ]] \
  && [[ "$CHECK_COMMAND" != *'`'* ]] \
  && [[ "$CHECK_COMMAND" != *'<('* ]] \
  && [[ "$CHECK_COMMAND" != *'>('* ]]; then
  CHECK_COMMAND=$(
    printf '%s' "$CHECK_COMMAND" | sed -E \
      -e "s/([[:space:]]-m[[:space:]]*)\"[^\"]*\"/\1\"\"/g" \
      -e "s/([[:space:]]-m[[:space:]]*)'[^']*'/\1''/g" \
      -e "s/([[:space:]]-m)\"[^\"]*\"/\1\"\"/g" \
      -e "s/([[:space:]]-m)'[^']*'/\1''/g" \
      -e "s/([[:space:]]--message(=|[[:space:]]+))\"[^\"]*\"/\1\"\"/g" \
      -e "s/([[:space:]]--message(=|[[:space:]]+))'[^']*'/\1''/g" \
      -e "s/(^|[;&|][[:space:]]*)(gcm[[:space:]]+)\"[^\"]*\"/\1\2\"\"/g" \
      -e "s/(^|[;&|][[:space:]]*)(gcm[[:space:]]+)'[^']*'/\1\2''/g" \
      -e "s/(^|[;&|][[:space:]]*)(gcm[[:space:]]+)[^[:space:];&|]+/\1\2_/g"
  )
fi
CHECK_COMMAND=${CHECK_COMMAND//\"/}
CHECK_COMMAND=${CHECK_COMMAND//\'/}
# Backslash-escaped option characters and refspec prefixes reach Git without
# the backslash, so normalize them before matching known destructive spellings.
CHECK_COMMAND=${CHECK_COMMAND//\\/}

# Git config keys are case-insensitive. Check the small set of security-control
# overrides against a lowercase copy without making -d and -D equivalent in the
# command patterns below.
LOWER_COMMAND=$(printf '%s' "$CHECK_COMMAND" | tr '[:upper:]' '[:lower:]')
GIT_COMMAND_PREFIX='(^|[^[:alnum:]_.-])(git|g)[[:space:]]([^;&|]*[[:space:]])?'
BRANCH_ALIAS_PREFIX='(^|[^[:alnum:]_.-])(gb|gba|gbd)[[:space:]]([^;&|]*[[:space:]])?'
PUSH_ALIAS_PREFIX='(^|[^[:alnum:]_.-])(gp|gpo)[[:space:]]([^;&|]*[[:space:]])?'
COMMIT_ALIAS_PREFIX='(^|[^[:alnum:]_.-])(gcm|gca|gcan)[[:space:]]([^;&|]*[[:space:]])?'
REWRITE_ALIAS_PREFIX='(^|[^[:alnum:]_.-])(grb|grbi|gcp)[[:space:]]([^;&|]*[[:space:]])?'

CORE_HOOKS_OVERRIDE_PATTERN="${GIT_COMMAND_PREFIX}-c[[:space:]]*core\\.hookspath[[:space:]]*="
SIGNING_OVERRIDE_PATTERN="${GIT_COMMAND_PREFIX}-c[[:space:]]*(commit|tag)\\.gpgsign[[:space:]]*=[[:space:]]*(false|no|off|0)([[:space:];&|]|$)"
CONFIG_ENV_OVERRIDE_PATTERN="${GIT_COMMAND_PREFIX}--config-env([[:space:]]+|[[:space:]]*=[[:space:]]*)(core\\.hookspath|(commit|tag)\\.gpgsign)[[:space:]]*="

if [[ "$LOWER_COMMAND" =~ $CORE_HOOKS_OVERRIDE_PATTERN ]]; then
  return_decision \
    "deny" \
    "Blocked by the dotfiles Git guard: overriding core.hooksPath bypasses the configured repository safeguards."
fi
if [[ "$LOWER_COMMAND" =~ $SIGNING_OVERRIDE_PATTERN ]]; then
  return_decision \
    "deny" \
    "Blocked by the dotfiles Git guard: this command disables the configured signing policy."
fi
if [[ "$LOWER_COMMAND" =~ $CONFIG_ENV_OVERRIDE_PATTERN ]]; then
  return_decision \
    "deny" \
    "Blocked by the dotfiles Git guard: an indirect environment override could bypass hooks or signing safeguards."
fi

HARD_BLOCK_PATTERNS=(
  "${GIT_COMMAND_PREFIX}reset[^;&|]*[[:space:]]--hard([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}undo[^;&|]*[[:space:]]--hard([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}clean[^;&|]*[[:space:]](--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gclean([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}branch[^;&|]*[[:space:]]-[[:alnum:]]*D[[:alnum:]]*([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}branch[^;&|]*[[:space:]](--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}br[^;&|]*[[:space:]]-[[:alnum:]]*D[[:alnum:]]*([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}br[^;&|]*[[:space:]](--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "${BRANCH_ALIAS_PREFIX}-[[:alnum:]]*D[[:alnum:]]*([[:space:];&|]|$)"
  "${BRANCH_ALIAS_PREFIX}(--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]]--force(=(true|1))?([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]]-[[:alnum:]]*f[[:alnum:]]*([[:space:];&|]|$)"
  "${PUSH_ALIAS_PREFIX}--force(=(true|1))?([[:space:];&|]|$)"
  "${PUSH_ALIAS_PREFIX}-[[:alnum:]]*f[[:alnum:]]*([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gpf[[:space:]]([^;&|]*[[:space:]])?(--force(=(true|1))?|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]]--mirror([[:space:];&|]|$)"
  "${PUSH_ALIAS_PREFIX}--mirror([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gpf[[:space:]]([^;&|]*[[:space:]])?--mirror([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]][+][^[:space:];&|]+"
  "${PUSH_ALIAS_PREFIX}[+][^[:space:];&|]+"
  "(^|[^[:alnum:]_.-])gpf[[:space:]]([^;&|]*[[:space:]])?[+][^[:space:];&|]+"
  "${GIT_COMMAND_PREFIX}(commit|ci|amend)[^;&|]*[[:space:]](--no-veri[^[:space:];&|]*|--no-g[^[:space:];&|]*|--no-si[^[:space:];&|]*|--no-pos[^[:space:];&|]*|-[[:alnum:]]*n[[:alnum:]]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}am[^;&|]*[[:space:]]-[[:alnum:]]*n[[:alnum:]]*([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}(tag|merge|rebase|am|cherry-pick|revert)[^;&|]*[[:space:]](--no-g[^[:space:];&|]*|--no-si[^[:space:];&|]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}(push|merge|rebase|am|cherry-pick|revert)[^;&|]*[[:space:]]--no-veri[^[:space:];&|]*"
  "${COMMIT_ALIAS_PREFIX}(--no-veri[^[:space:];&|]*|--no-g[^[:space:];&|]*|--no-si[^[:space:];&|]*|--no-pos[^[:space:];&|]*|-[[:alnum:]]*n[[:alnum:]]*)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])(gp|gpf|gpo)[[:space:]]([^;&|]*[[:space:]])?--no-veri[^[:space:];&|]*"
  "${REWRITE_ALIAS_PREFIX}(--no-veri[^[:space:];&|]*|--no-g[^[:space:];&|]*|--no-si[^[:space:];&|]*)([[:space:];&|]|$)"
)

PROMPT_PATTERNS=(
  "${GIT_COMMAND_PREFIX}reset([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}clean([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}branch[^;&|]*[[:space:]](-[[:alnum:]]*d[[:alnum:]]*|--delete)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}br[^;&|]*[[:space:]](-[[:alnum:]]*d[[:alnum:]]*|--delete)([[:space:];&|]|$)"
  "${BRANCH_ALIAS_PREFIX}-[[:alnum:]]*d[[:alnum:]]*([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gbd([[:space:];&|]|$)"
  # A bare checkout target can be a ref or a path. Escalate every checkout;
  # `git switch` remains the unambiguous, no-prompt branch-switching command.
  "${GIT_COMMAND_PREFIX}(checkout|co)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gco([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}discard([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}restore([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}unstage([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}stash[^;&|]*[[:space:]](drop|clear)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gst([[:space:]][^;&|]*)?[[:space:]](drop|clear)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]](--force-with-lease|--delete|--prune|-[[:alnum:]]*d[[:alnum:]]*)([=[:space:];&|]|$)"
  "${PUSH_ALIAS_PREFIX}(--force-with-lease|--delete|--prune|-[[:alnum:]]*d[[:alnum:]]*)([=[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])gpf([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}push[^;&|]*[[:space:]]:[^[:space:];&|]+"
  "${PUSH_ALIAS_PREFIX}:[^[:space:];&|]+"
  "${GIT_COMMAND_PREFIX}switch[^;&|]*[[:space:]](--discard-changes|--force|-[[:alnum:]]*f[[:alnum:]]*)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}tag[^;&|]*[[:space:]](-d|--delete)([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}update-ref[^;&|]*[[:space:]]-d([[:space:];&|]|$)"
  "${GIT_COMMAND_PREFIX}(cleanup|undo|amend)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])(gca|gcan)([[:space:];&|]|$)"
)

for pattern in "${HARD_BLOCK_PATTERNS[@]}"; do
  if [[ "$CHECK_COMMAND" =~ $pattern ]]; then
    return_decision \
      "deny" \
      "Blocked by the dotfiles Git guard: this spelling performs an unbounded or safety-bypassing Git operation. Use a safer, reviewable alternative."
  fi
done

for pattern in "${PROMPT_PATTERNS[@]}"; do
  if [[ "$CHECK_COMMAND" =~ $pattern ]]; then
    return_decision \
      "ask" \
      "The dotfiles Git guard requires confirmation because this command can discard local work, delete Git state, or rewrite remote history."
  fi
done

exit 0
