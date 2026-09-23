#!/bin/bash
# PreToolUse hook: blocks destructive git commands before they execute.
#
# Adapted from mattpocock/skills' git-guardrails-claude-code skill (MIT),
# https://github.com/mattpocock/skills/tree/main/skills/misc/git-guardrails-claude-code
#
# This is a mechanical backstop for the optional automode profile's git-safety
# rules in settings-automode.json. Permission prompts remain the primary
# boundary; this hook is a hard block if a dangerous command reaches the tool.
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
      -e "s/([[:space:]]--message(=|[[:space:]]+))'[^']*'/\1''/g"
  )
fi
CHECK_COMMAND=${CHECK_COMMAND//\"/}
CHECK_COMMAND=${CHECK_COMMAND//\'/}
# Backslash-escaped option characters and refspec prefixes reach Git without
# the backslash, so normalize them before matching known destructive spellings.
CHECK_COMMAND=${CHECK_COMMAND//\\/}

DANGEROUS_PATTERNS=(
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]reset[^;&|]*--hard"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]clean[^;&|]*(--force|[[:space:]]-[[:alnum:]]*f[[:alnum:]]*)"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]branch[^;&|]*([[:space:]]-[[:alnum:]]*d[[:alnum:]]*|--delete)"
  # A bare checkout target can be either a ref or a path. The automode profile
  # prompts for all `git checkout` commands; this hard block covers only the
  # path forms that are unambiguous without executing Git's ref resolution.
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]checkout[^;&|]*([[:space:]]--[[:space:]]+|[[:space:]]+(\.|\.\.)([[:space:];&|]|$))"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]restore([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]stash[^;&|]*[[:space:]](drop|clear)([[:space:];&|]|$)"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]push[^;&|]*(--force|--delete|--mirror|--prune|[[:space:]]-[[:alnum:]]*[fd][[:alnum:]]*|[[:space:]][+:][^[:space:];&|]+)"
  "(^|[^[:alnum:]_.-])(git|g)[^;&|]*[[:space:]]commit[^;&|]*[[:space:]]-[[:alnum:]]*n[[:alnum:]]*"
  "\-\-no-veri[^[:space:];&|]*"
  "\-\-no-gpg[^[:space:];&|]*"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s\n' "$CHECK_COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED: command matches dangerous pattern '$pattern'. The user has not authorized this destructive git operation in this session. Ask the user to run it themselves if it's genuinely needed." >&2
    exit 2
  fi
done

exit 0
