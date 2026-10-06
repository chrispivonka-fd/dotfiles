#!/usr/bin/env bash
# Claude Code status line: compact, responsive, and macOS-focused.
# Line 1: location | git/worktree | review/ticket
# Line 2: model/mode | context tokens/limits/cache | estimated session usage

input=$(cat)
umask 077

# GitHub Dark-inspired palette. Dynamic values are always printed with %s.
C_MUTED=$'\033[38;5;245m'
C_SUBTLE=$'\033[38;5;250m'
C_PURPLE=$'\033[38;5;183m'
C_RED=$'\033[38;5;209m'
C_ORANGE=$'\033[38;5;215m'
C_YELLOW=$'\033[38;5;221m'
C_GREEN=$'\033[38;5;114m'
C_CYAN=$'\033[38;5;80m'
C_BLUE=$'\033[38;5;117m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Parse Claude's payload once. Replace control characters in all displayed data
# so a repository, agent, or session name cannot inject terminal escapes.
if ! parsed=$(printf '%s' "$input" | jq -r '
  def clean:
    tostring
    | explode
    | map(
        if (. < 32 or (. >= 127 and . <= 159) or . == 1564 or
            (. >= 8206 and . <= 8207) or (. >= 8234 and . <= 8238) or
            (. >= 8294 and . <= 8297))
        then 32
        else .
        end
      )
    | implode;
  [
    (.model.display_name // "Claude"),
    (.workspace.current_dir // .cwd // ""),
    (if (.context_window.used_percentage | type) == "number" then
       .context_window.used_percentage
     elif (.context_window.remaining_percentage | type) == "number" then
       (100 - .context_window.remaining_percentage)
     else "" end),
    (if (.context_window.total_input_tokens | type) == "number" then
       .context_window.total_input_tokens
     elif (.context_window.current_usage | type) == "object" then
       ([.context_window.current_usage.input_tokens,
         .context_window.current_usage.cache_creation_input_tokens,
         .context_window.current_usage.cache_read_input_tokens]
        | map(if type == "number" then . else 0 end)
        | add)
     else "" end),
    (.vim.mode // ""),
    (.session_name // ""),
    (.effort.level // ""),
    (if .fast_mode == true then "fast" else "" end),
    (if .thinking.enabled == true then "thinking" else "" end),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.spend_limit.used_percentage // ""),
    (if (.prompt_cache.hit_ratio | type) == "number" then
       (.prompt_cache.hit_ratio * 100 | round)
     else "" end),
    (if .prompt_cache.warm == true then "warm"
     elif .prompt_cache.warm == false then "cold"
     else "" end),
    (.cost.total_cost_usd // ""),
    (.cost.total_duration_ms // ""),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.pr.number // ""),
    (.pr.review_state // ""),
    (.pr.kind // "pr"),
    (.worktree.name // .workspace.git_worktree // ""),
    (.agent.name // "")
  ]
  | map(clean)
  | join("\u001f")
' 2>/dev/null); then
  exit 0
fi

IFS=$'\037' read -r model cwd context_used context_tokens vim_mode session_name \
  effort fast_mode thinking five_hour seven_day spend_limit cache_pct \
  cache_state session_cost duration_ms lines_added lines_removed pr_number \
  pr_state pr_kind worktree_name agent_name <<< "$parsed"

sanitize_text() {
  printf '%s' "$1" | jq -Rr '
    explode
    | map(
        if (. < 32 or (. >= 127 and . <= 159) or . == 1564 or
            (. >= 8206 and . <= 8207) or (. >= 8234 and . <= 8238) or
            (. >= 8294 and . <= 8297))
        then 32
        else .
        end
      )
    | implode
  ' 2>/dev/null
}

string_width() {
  local value="$1"
  local LC_ALL=C
  printf '%s' "${#value}"
}

truncate_middle() {
  local value="$1" limit="$2" left right right_text result
  if [ "$(string_width "$value")" -le "$limit" ]; then
    printf '%s' "$value"
    return
  fi
  if [ "$limit" -le 3 ]; then
    printf '%.*s' "$limit" "..."
    return
  fi

  left=$(((${#value} + 1) / 2))
  right=$((${#value} - left))
  while [ "$left" -gt 0 ] || [ "$right" -gt 0 ]; do
    right_text=""
    [ "$right" -gt 0 ] && right_text="${value: -right}"
    result="${value:0:left}...$right_text"
    if [ "$(string_width "$result")" -le "$limit" ]; then
      printf '%s' "$result"
      return
    fi
    if [ "$left" -ge "$right" ] && [ "$left" -gt 0 ]; then
      left=$((left - 1))
    elif [ "$right" -gt 0 ]; then
      right=$((right - 1))
    fi
  done
  printf '%.*s' "$limit" "..."
}

round_percent() {
  local value="$1"
  [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || return
  printf '%.0f' "$value"
}

usage_color() {
  local value="${1%%.*}"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  if [ "$value" -ge 90 ]; then
    printf '%s' "$C_RED"
  elif [ "$value" -ge 70 ]; then
    printf '%s' "$C_YELLOW"
  else
    printf '%s' "$C_GREEN"
  fi
}

context_pressure_color() {
  local value="${1%%.*}"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  if [ "$value" -ge 90 ]; then
    printf '%s' "$C_RED"
  elif [ "$value" -ge 85 ]; then
    printf '%s' "$C_ORANGE"
  elif [ "$value" -ge 70 ]; then
    printf '%s' "$C_YELLOW"
  else
    printf '%s' "$C_GREEN"
  fi
}

context_token_color() {
  local value="${1%%.*}"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  if [ "$value" -ge 100000 ]; then
    printf '%s' "$C_RED"
  elif [ "$value" -ge 85000 ]; then
    printf '%s' "$C_ORANGE"
  elif [ "$value" -ge 70000 ]; then
    printf '%s' "$C_YELLOW"
  else
    printf '%s' "$C_GREEN"
  fi
}

format_tokens() {
  local value="${1%%.*}" tenths
  [[ "$value" =~ ^[0-9]+$ ]] || return
  if [ "$value" -ge 1000000 ]; then
    tenths=$((value / 100000))
    printf '%d.%dM' "$((tenths / 10))" "$((tenths % 10))"
  elif [ "$value" -ge 100000 ]; then
    printf '%dk' "$((value / 1000))"
  elif [ "$value" -ge 1000 ]; then
    tenths=$((value / 100))
    printf '%d.%dk' "$((tenths / 10))" "$((tenths % 10))"
  else
    printf '%d' "$value"
  fi
}

cache_color() {
  local value="${1%%.*}"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  if [ "$value" -ge 80 ]; then
    printf '%s' "$C_GREEN"
  elif [ "$value" -ge 50 ]; then
    printf '%s' "$C_YELLOW"
  else
    printf '%s' "$C_RED"
  fi
}

format_duration() {
  local milliseconds="$1" seconds minutes hours
  [[ "$milliseconds" =~ ^[0-9]+$ ]] || return
  seconds=$((milliseconds / 1000))
  if [ "$seconds" -lt 60 ]; then
    printf '%ss' "$seconds"
  elif [ "$seconds" -lt 3600 ]; then
    printf '%sm' "$((seconds / 60))"
  else
    hours=$((seconds / 3600))
    minutes=$(((seconds % 3600) / 60))
    printf '%sh%02dm' "$hours" "$minutes"
  fi
}

columns="${COLUMNS:-120}"
[[ "$columns" =~ ^[0-9]+$ ]] || columns=120
path_limit=44
branch_limit=34
if [ "$columns" -lt 40 ]; then
  path_limit="$columns"
  branch_limit=0
elif [ "$columns" -lt 100 ]; then
  path_limit=$((columns / 2 - 2))
  [ "$path_limit" -gt 32 ] && path_limit=32
  branch_limit=$((columns - path_limit - 9))
  [ "$branch_limit" -gt 28 ] && branch_limit=28
elif [ "$columns" -ge 160 ]; then
  path_limit=64
  branch_limit=48
fi

# Compact the home directory without losing useful project context.
if [[ "$cwd" == "$HOME" ]]; then
  short_dir="~"
elif [[ "$cwd" == "$HOME"/* ]]; then
  short_dir="~${cwd#"$HOME"}"
else
  short_dir="$cwd"
fi
[ -n "$short_dir" ] || short_dir="~"
short_dir_full="$short_dir"
short_dir=$(truncate_middle "$short_dir" "$path_limit")
session_name=$(truncate_middle "$session_name" 36)
worktree_name=$(truncate_middle "$worktree_name" 28)
agent_name=$(truncate_middle "$agent_name" 28)

# Git state is cached for two seconds because Claude can redraw several times
# for one UI event. The cache is private and scoped by session plus directory.
cache_dir="${TMPDIR:-$HOME/Library/Caches}/claude-statusline"
cache_ready=0
if [ ! -L "$cache_dir" ] && mkdir -p "$cache_dir" 2>/dev/null; then
  chmod 700 "$cache_dir" 2>/dev/null && cache_ready=1
  find "$cache_dir" -type f \( -name 'git-*' -o -name '.git-status.*' \) \
    -mtime +7 -delete 2>/dev/null
fi

git_branch=""
modified=0
staged=0
untracked=0
conflicted=0
ahead=0
behind=0

if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  git_branch=$(sanitize_text "$git_branch") || git_branch="[invalid branch]"
  git_status=""

  if [ "$cache_ready" -eq 1 ]; then
    cache_key=$(printf '%s' "$cwd" | shasum -a 256 | cut -c1-16)
    git_cache="$cache_dir/git-$cache_key"
    cache_age=9999
    if [ -f "$git_cache" ] && [ ! -L "$git_cache" ]; then
      cache_mtime=$(stat -f %m "$git_cache" 2>/dev/null || printf '0')
      [[ "$cache_mtime" =~ ^[0-9]+$ ]] || cache_mtime=0
      cache_age=$(($(date +%s) - cache_mtime))
    fi

    if [ "$cache_age" -lt 2 ]; then
      git_status=$(<"$git_cache")
    else
      git_status=$(git -C "$cwd" status --porcelain=v1 --branch --ignore-submodules 2>/dev/null)
      cache_tmp=$(mktemp "$cache_dir/.git-status.XXXXXX" 2>/dev/null || true)
      if [ -n "$cache_tmp" ] && printf '%s' "$git_status" > "$cache_tmp" 2>/dev/null; then
        chmod 600 "$cache_tmp" 2>/dev/null
        if [ -L "$git_cache" ] || { [ -e "$git_cache" ] && [ ! -f "$git_cache" ]; }; then
          rm -f "$cache_tmp"
        else
          mv -f "$cache_tmp" "$git_cache" 2>/dev/null || rm -f "$cache_tmp"
        fi
      elif [ -n "$cache_tmp" ]; then
        rm -f "$cache_tmp"
      fi
    fi
  else
    git_status=$(git -C "$cwd" status --porcelain=v1 --branch --ignore-submodules 2>/dev/null)
  fi

  while IFS= read -r status_line; do
    if [[ "$status_line" == "## "* ]]; then
      [[ "$status_line" =~ ahead\ ([0-9]+) ]] && ahead="${BASH_REMATCH[1]}"
      [[ "$status_line" =~ behind\ ([0-9]+) ]] && behind="${BASH_REMATCH[1]}"
      continue
    fi

    index_state="${status_line:0:1}"
    worktree_state="${status_line:1:1}"
    case "$index_state$worktree_state" in
      DD|AU|UD|UA|DU|AA|UU)
        conflicted=$((conflicted + 1))
        continue
        ;;
    esac
    case "$index_state" in
      M|A|D|R|C|T) staged=$((staged + 1)) ;;
    esac
    case "$worktree_state" in
      M|D|T) modified=$((modified + 1)) ;;
    esac
    [ "$index_state$worktree_state" = "??" ] && untracked=$((untracked + 1))
  done <<< "$git_status"
fi

# Pull the first Jira-style ticket from common branch naming conventions.
jira=""
if [[ "$git_branch" =~ ([a-zA-Z]+-[0-9]+) ]]; then
  jira=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
fi

SEP="${C_MUTED}  |  ${RESET}"
SEP_WIDTH=5

append_line1_segment() {
  local plain="$1" styled="$2" plain_width
  plain_width=$(string_width "$plain")
  if [ $((line1_width + SEP_WIDTH + plain_width)) -le "$columns" ]; then
    line1+="${SEP}${styled}"
    line1_width=$((line1_width + SEP_WIDTH + plain_width))
    return 0
  fi
  return 1
}

append_line1_token() {
  local plain="$1" styled="$2" plain_width
  plain_width=$(string_width "$plain")
  if [ $((line1_width + plain_width)) -le "$columns" ]; then
    line1+="${styled}"
    line1_width=$((line1_width + plain_width))
    return 0
  fi
  return 1
}

# Line 1: workspace and source-control state.
status_plain=""
status_styled=""
if [ "$conflicted" -gt 0 ]; then
  status_plain+=" !${conflicted}"
  status_styled+=" ${C_RED}!${conflicted}${RESET}"
fi
if [ "$modified" -gt 0 ]; then
  status_plain+=" *${modified}"
  status_styled+=" ${C_ORANGE}*${modified}${RESET}"
fi
if [ "$staged" -gt 0 ]; then
  status_plain+=" +${staged}"
  status_styled+=" ${C_GREEN}+${staged}${RESET}"
fi
if [ "$untracked" -gt 0 ]; then
  status_plain+=" ?${untracked}"
  status_styled+=" ${C_SUBTLE}?${untracked}${RESET}"
fi

branch_label=""
if [ -n "$git_branch" ] && [ "$branch_limit" -gt 0 ]; then
  status_width=$(string_width "$status_plain")
  available=$((columns - SEP_WIDTH - 4 - status_width))
  if [ "$available" -gt 1 ]; then
    path_budget=$((available / 2))
    branch_budget=$((available - path_budget))
    [ "$path_budget" -gt "$path_limit" ] && path_budget="$path_limit"
    [ "$branch_budget" -gt "$branch_limit" ] && branch_budget="$branch_limit"
    short_dir=$(truncate_middle "$short_dir_full" "$path_budget")
    branch_label=$(truncate_middle "$git_branch" "$branch_budget")
  fi
fi

line1="${C_BLUE}${BOLD}${short_dir}${RESET}"
line1_width=$(string_width "$short_dir")
if [ -n "$branch_label" ]; then
  git_plain="git:${branch_label}"
  git_styled="${C_PURPLE}${BOLD}${git_plain}${RESET}"
  if append_line1_segment "$git_plain" "$git_styled"; then
    [ -n "$status_plain" ] && append_line1_token "$status_plain" "$status_styled"
    [ "$ahead" -gt 0 ] && append_line1_token " up:${ahead}" " ${C_CYAN}up:${ahead}${RESET}"
    [ "$behind" -gt 0 ] && append_line1_token " down:${behind}" " ${C_RED}down:${behind}${RESET}"
  fi
fi

if [ -n "$pr_number" ]; then
  pr_label="PR"
  [ "$pr_kind" = "mr" ] && pr_label="MR"
  case "$pr_state" in
    approved)          pr_color="$C_GREEN"; pr_suffix=" approved" ;;
    changes_requested) pr_color="$C_RED"; pr_suffix=" changes" ;;
    draft)             pr_color="$C_MUTED"; pr_suffix=" draft" ;;
    pending)           pr_color="$C_YELLOW"; pr_suffix=" pending" ;;
    *)                 pr_color="$C_PURPLE"; pr_suffix="" ;;
  esac
  pr_number=$(truncate_middle "$pr_number" 16)
  pr_plain="${pr_label} #${pr_number}${pr_suffix}"
  append_line1_segment "$pr_plain" "${pr_color}${BOLD}${pr_plain}${RESET}" || true
fi

if [ -n "$worktree_name" ]; then
  worktree_plain="wt:${worktree_name}"
  append_line1_segment "$worktree_plain" "${C_CYAN}${worktree_plain}${RESET}" || true
fi

if [ -n "$jira" ]; then
  append_line1_segment "$jira" "${C_PURPLE}${BOLD}${jira}${RESET}" || true
fi

# Line 2: model and the limits most likely to affect the current session.
append_line2_segment() {
  local plain="$1" styled="$2" plain_width
  plain_width=$(string_width "$plain")
  if [ $((line2_width + SEP_WIDTH + plain_width)) -le "$columns" ]; then
    line2+="${SEP}${styled}"
    line2_width=$((line2_width + SEP_WIDTH + plain_width))
    return 0
  fi
  return 1
}

model_label="$model"
[ -n "$effort" ] && model_label+="/${effort}"
[ -n "$fast_mode" ] && model_label+=" fast"
[ -n "$thinking" ] && [ "$columns" -ge 120 ] && model_label+=" think"
model_limit=36
[ "$columns" -lt 90 ] && model_limit=26
[ "$model_limit" -gt "$columns" ] && model_limit="$columns"
model_label=$(truncate_middle "$model_label" "$model_limit")
line2="${C_BLUE}${BOLD}${model_label}${RESET}"
line2_width=$(string_width "$model_label")

if context_pct=$(round_percent "$context_used"); then
  context_color=$(context_pressure_color "$context_pct")
  context_pct_plain="ctx ${context_pct}%"
  context_pct_styled="${context_color}${context_pct_plain}${RESET}"
  context_plain="$context_pct_plain"
  context_styled="$context_pct_styled"
  context_token_label=""
  if context_token_label=$(format_tokens "$context_tokens"); then
    context_tokens_color=$(context_token_color "$context_tokens")
    context_plain+="/${context_token_label}"
    context_styled+="${C_MUTED}/${RESET}${context_tokens_color}${context_token_label}${RESET}"
  fi
  if ! append_line2_segment "$context_plain" "$context_styled"; then
    [ -n "$context_token_label" ] && \
      append_line2_segment "$context_pct_plain" "$context_pct_styled" || true
  fi
fi

if [ -n "$vim_mode" ]; then
  append_line2_segment "$vim_mode" "${C_PURPLE}${vim_mode}${RESET}" || true
fi

rate_parts=""
rate_plain=""
five_hour_pct=""
if rate_pct=$(round_percent "$five_hour"); then
  five_hour_pct="$rate_pct"
  rate_plain="5h ${rate_pct}%"
  rate_parts="$(usage_color "$rate_pct")${rate_plain}${RESET}"
fi
if rate_pct=$(round_percent "$seven_day"); then
  [ -n "$rate_parts" ] && rate_parts+="  "
  [ -n "$rate_plain" ] && rate_plain+="  "
  rate_plain+="7d ${rate_pct}%"
  rate_parts+="$(usage_color "$rate_pct")7d ${rate_pct}%${RESET}"
fi
if [ -n "$rate_plain" ]; then
  if ! append_line2_segment "$rate_plain" "$rate_parts" && [ -n "$five_hour_pct" ]; then
    rate_plain="5h ${five_hour_pct}%"
    append_line2_segment "$rate_plain" "$(usage_color "$five_hour_pct")${rate_plain}${RESET}" || true
  fi
fi

if spend_pct=$(round_percent "$spend_limit"); then
  spend_plain="spend ${spend_pct}%"
  append_line2_segment "$spend_plain" "$(usage_color "$spend_pct")${spend_plain}${RESET}" || true
fi

if cache_value=$(round_percent "$cache_pct"); then
  cache_label="cache ${cache_value}%"
  [ -n "$cache_state" ] && cache_label+=" ${cache_state}"
  append_line2_segment "$cache_label" "$(cache_color "$cache_value")${cache_label}${RESET}" || true
fi

session_parts=""
session_plain=""
if [[ "$session_cost" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  cost_label=$(printf '$%.2f est' "$session_cost")
  session_plain="$cost_label"
  session_parts="${C_YELLOW}${cost_label}${RESET}"
fi
duration=$(format_duration "$duration_ms")
if [ -n "$duration" ]; then
  [ -n "$session_parts" ] && session_parts+="  "
  [ -n "$session_plain" ] && session_plain+="  "
  session_plain+="$duration"
  session_parts+="${C_SUBTLE}${duration}${RESET}"
fi
[ -n "$session_plain" ] && append_line2_segment "$session_plain" "$session_parts" || true

[[ "$lines_added" =~ ^[0-9]+$ ]] || lines_added=0
[[ "$lines_removed" =~ ^[0-9]+$ ]] || lines_removed=0
if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
  lines_plain="+${lines_added}/-${lines_removed}"
  lines_styled="${C_GREEN}+${lines_added}${RESET}/${C_RED}-${lines_removed}${RESET}"
  append_line2_segment "$lines_plain" "$lines_styled" || true
fi

if [ -n "$agent_name" ]; then
  agent_plain="agent:${agent_name}"
  append_line2_segment "$agent_plain" "${C_PURPLE}${agent_plain}${RESET}" || true
fi
if [ -n "$session_name" ]; then
  append_line2_segment "$session_name" "${C_MUTED}${session_name}${RESET}" || true
fi

printf '%s\n' "$line1"
printf '%s\n' "$line2"
