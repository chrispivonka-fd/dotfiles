#!/usr/bin/env bash
# Claude Code status line — GitHub Dark, two-line layout
# Line 1:  cwd ┊  git ┊ 󰯄 jira ┊ infra ┊ runtimes ┊ env
# Line 2: 󰚩 model ┊ 󰍛 ctx ┊  mcp ┊ vim ┊ session

input=$(cat)

# --- GitHub Dark palette (256-color) ---
C_SUBTEXT='\033[38;5;246m'
C_OVERLAY='\033[38;5;243m'
C_MAUVE='\033[38;5;183m'
C_RED='\033[38;5;209m'
C_PEACH='\033[38;5;215m'
C_YELLOW='\033[38;5;172m'
C_GREEN='\033[38;5;71m'
C_TEAL='\033[38;5;80m'
C_SKY='\033[38;5;111m'
C_SAPPHIRE='\033[38;5;86m'
C_LAVENDER='\033[38;5;153m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Parse Claude JSON ---
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')

# --- Short cwd with ~ ---
if [[ "$cwd" == "$HOME" ]]; then
  short_dir="~"
elif [[ "$cwd" == "$HOME"/* ]]; then
  short_dir="~${cwd#"$HOME"}"
else
  short_dir="$cwd"
fi
[ -z "$short_dir" ] && short_dir="~"

# --- Find a file walking up from a directory ---
find_up() {
  local dir="$1" file="$2"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    [ -e "$dir/$file" ] && { echo "$dir/$file"; return; }
    dir=$(dirname "$dir")
  done
}

# --- Cache dir ---
cache_dir="${TMPDIR:-/tmp}/cc-statusline"
mkdir -p "$cache_dir" 2>/dev/null

# --- Git segment (cached 2s to avoid hammering on large repos) ---
git_branch=""
mod=0; staged=0; untracked=0; ahead=0; behind=0
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
               || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  cache_key=$(echo "$cwd" | tr '/' '_' | tr -cd '[:alnum:]_')
  gcache="$cache_dir/git-$cache_key"
  cage=9999
  [ -f "$gcache" ] && cage=$(($(date +%s) - $(stat -f %m "$gcache" 2>/dev/null || stat -c %Y "$gcache" 2>/dev/null || echo 0)))

  if [ "$cage" -lt 2 ]; then
    gstatus=$(cat "$gcache")
  else
    gstatus=$(git -C "$cwd" status --porcelain=v1 --branch --ignore-submodules 2>/dev/null)
    printf '%s' "$gstatus" > "$gcache"
  fi

  header=$(echo "$gstatus" | head -n1)
  [[ "$header" =~ ahead\ ([0-9]+) ]] && ahead="${BASH_REMATCH[1]}"
  [[ "$header" =~ behind\ ([0-9]+) ]] && behind="${BASH_REMATCH[1]}"

  body=$(echo "$gstatus" | tail -n +2)
  if [ -n "$body" ]; then
    mod=$(echo "$body" | grep -c '^.[MD]' 2>/dev/null)
    staged=$(echo "$body" | grep -c '^[MADRC]' 2>/dev/null)
    untracked=$(echo "$body" | grep -c '^??' 2>/dev/null)
  fi
fi

# --- Jira ticket from branch (e.g. mc-368/foo -> MC-368) ---
jira=""
if [[ "$git_branch" =~ ^([a-zA-Z]+-[0-9]+) ]]; then
  jira=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
fi

# --- AWS profile / region ---
aws_info=""
if [ -n "$AWS_PROFILE" ]; then
  aws_info="$AWS_PROFILE"
  [ -n "$AWS_REGION" ] && aws_info="$aws_info/$AWS_REGION"
elif [ -n "$AWS_DEFAULT_PROFILE" ]; then
  aws_info="$AWS_DEFAULT_PROFILE"
fi

# --- Terraform workspace (only show when in a .tf dir) ---
tf_ws=""
if [ -n "$cwd" ] && compgen -G "$cwd/*.tf" >/dev/null 2>&1; then
  if [ -f "$cwd/.terraform/environment" ]; then
    tf_ws=$(cat "$cwd/.terraform/environment" 2>/dev/null)
  else
    tf_ws="default"
  fi
fi

# --- Node version from .nvmrc ---
node_ver=""
if [ -n "$cwd" ]; then
  nvmrc=$(find_up "$cwd" ".nvmrc")
  [ -n "$nvmrc" ] && node_ver=$(head -n1 "$nvmrc" 2>/dev/null | tr -d 'v \t\r\n')
fi

# --- Python version from .python-version ---
py_ver=""
if [ -n "$cwd" ]; then
  pv=$(find_up "$cwd" ".python-version")
  [ -n "$pv" ] && py_ver=$(head -n1 "$pv" 2>/dev/null | tr -d ' \t\r\n')
fi

# --- .NET version from global.json (or .csproj presence) ---
dotnet_ver=""
if [ -n "$cwd" ]; then
  gj=$(find_up "$cwd" "global.json")
  if [ -n "$gj" ]; then
    dotnet_ver=$(jq -r '.sdk.version // empty' "$gj" 2>/dev/null)
  fi
  if [ -z "$dotnet_ver" ] && compgen -G "$cwd/*.csproj" >/dev/null 2>&1; then
    dotnet_ver="net"
  fi
  if [ -z "$dotnet_ver" ] && compgen -G "$cwd/*.sln" >/dev/null 2>&1; then
    dotnet_ver="net"
  fi
fi

# --- Go version from go.mod ---
go_ver=""
if [ -n "$cwd" ]; then
  gomod=$(find_up "$cwd" "go.mod")
  [ -n "$gomod" ] && go_ver=$(awk '/^go [0-9.]+/ {print $2; exit}' "$gomod" 2>/dev/null)
fi

# --- Rust version from rust-toolchain / Cargo.toml ---
rust_ver=""
if [ -n "$cwd" ]; then
  tc=$(find_up "$cwd" "rust-toolchain.toml")
  [ -z "$tc" ] && tc=$(find_up "$cwd" "rust-toolchain")
  if [ -n "$tc" ]; then
    rust_ver=$(grep -E '^channel' "$tc" 2>/dev/null | sed -nE 's/.*"([^"]+)".*/\1/p' | head -n1)
    [ -z "$rust_ver" ] && rust_ver=$(head -n1 "$tc" 2>/dev/null | tr -d ' \t\r\n"')
  fi
  if [ -z "$rust_ver" ]; then
    cargo=$(find_up "$cwd" "Cargo.toml")
    [ -n "$cargo" ] && rust_ver="rs"
  fi
fi

# --- React version from package.json ---
react_ver=""
if [ -n "$cwd" ]; then
  pkg=$(find_up "$cwd" "package.json")
  if [ -n "$pkg" ]; then
    react_ver=$(jq -r '(.dependencies.react // .devDependencies.react // empty) | sub("[\\^~]"; "")' "$pkg" 2>/dev/null)
  fi
fi

# --- Tailwind presence ---
tailwind=""
if [ -n "$cwd" ]; then
  for f in tailwind.config.js tailwind.config.ts tailwind.config.mjs tailwind.config.cjs; do
    tw=$(find_up "$cwd" "$f")
    [ -n "$tw" ] && { tailwind="1"; break; }
  done
fi

# --- direnv loaded (set by direnv in every shell it manages) ---
direnv_active=""
[ -n "$DIRENV_DIR" ] && direnv_active="1"

# --- dotenv file presence ---
dotenv=""
if [ -n "$cwd" ]; then
  for f in .env .env.local .env.development .env.development.local; do
    ef=$(find_up "$cwd" "$f")
    [ -n "$ef" ] && { dotenv="1"; break; }
  done
fi

# --- MCP count from ~/.claude.json (user-scope MCP config) ---
mcp_count=""
if [ -f "$HOME/.claude.json" ]; then
  mcp_count=$(jq -r '(.mcpServers // {}) | length' "$HOME/.claude.json" 2>/dev/null)
fi

# --- Assemble line 1 ---
SEP="${C_OVERLAY}┊${RESET}"

line1="${C_SAPPHIRE}${BOLD}󰉋 ${short_dir}${RESET}"

if [ -n "$git_branch" ]; then
  line1+=" ${SEP} ${C_MAUVE}${BOLD}󰘬 ${git_branch}${RESET}"
  [ "$mod" -gt 0 ]       && line1+=" ${C_PEACH}✱${mod}${RESET}"
  [ "$staged" -gt 0 ]    && line1+=" ${C_GREEN}+${staged}${RESET}"
  [ "$untracked" -gt 0 ] && line1+=" ${C_SUBTEXT}?${untracked}${RESET}"
  [ "$ahead" -gt 0 ]     && line1+=" ${C_TEAL}⇡${ahead}${RESET}"
  [ "$behind" -gt 0 ]    && line1+=" ${C_RED}⇣${behind}${RESET}"
fi

[ -n "$jira" ]          && line1+=" ${SEP} ${C_LAVENDER}${BOLD}󰯄 ${jira}${RESET}"

# Infra group (terraform + aws)
infra_parts=""
[ -n "$tf_ws" ]         && infra_parts+=" ${C_YELLOW}󱁢 ${tf_ws}${RESET}"
[ -n "$aws_info" ]      && infra_parts+=" ${C_YELLOW}󰸏 ${aws_info}${RESET}"
[ -n "$infra_parts" ]   && line1+=" ${SEP}${infra_parts}"

# Runtime versions group
rt_parts=""
[ -n "$dotnet_ver" ]    && rt_parts+=" ${C_GREEN}󰪮 ${dotnet_ver}${RESET}"
[ -n "$node_ver" ]      && rt_parts+=" ${C_GREEN} ${node_ver}${RESET}"
[ -n "$py_ver" ]        && rt_parts+=" ${C_GREEN} ${py_ver}${RESET}"
[ -n "$go_ver" ]        && rt_parts+=" ${C_GREEN} ${go_ver}${RESET}"
[ -n "$rust_ver" ]      && rt_parts+=" ${C_GREEN} ${rust_ver}${RESET}"
[ -n "$react_ver" ]     && rt_parts+=" ${C_GREEN} ${react_ver}${RESET}"
[ -n "$tailwind" ]      && rt_parts+=" ${C_GREEN}󱏿${RESET}"
[ -n "$rt_parts" ]      && line1+=" ${SEP}${rt_parts}"

# Env indicators group
env_parts=""
[ -n "$direnv_active" ] && env_parts+=" ${C_TEAL}${RESET}"
[ -n "$dotenv" ]        && env_parts+=" ${C_TEAL}󰙨 .env${RESET}"
[ -n "$env_parts" ]     && line1+=" ${SEP}${env_parts}"

# --- Assemble line 2 ---
line2="${C_SKY}${BOLD}󰚩 ${model}${RESET}"

if [ -n "$remaining" ]; then
  pct=$(printf '%.0f' "$remaining")
  if   [ "$pct" -le 20 ]; then clr="$C_RED"
  elif [ "$pct" -le 50 ]; then clr="$C_YELLOW"
  else                         clr="$C_GREEN"; fi
  line2+=" ${SEP} ${clr}󰍛 ${pct}%${RESET}"
fi

[ -n "$mcp_count" ] && [ "$mcp_count" -gt 0 ] && line2+=" ${SEP} ${C_TEAL}󰢮 ${mcp_count}${RESET}"
[ -n "$vim_mode" ]                            && line2+=" ${SEP} ${C_MAUVE} ${vim_mode}${RESET}"
[ -n "$session_name" ]                        && line2+=" ${SEP} ${C_SUBTEXT}󰆧 ${session_name}${RESET}"

# --- Output (printf %b interprets the \033 escapes in the variables) ---
printf '%b\n' "$line1"
printf '%b\n' "$line2"
