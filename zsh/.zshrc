# =============================================================================
# .zshrc — modern zsh configuration
# =============================================================================

# --- Resolve dotfiles directory (follow symlink to find repo) ----------------
if [ -L "$HOME/.zshrc" ]; then
  DOTFILES_DIR="$(cd "$(dirname "$(readlink "$HOME/.zshrc")")/.." && pwd)"
else
  DOTFILES_DIR="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
fi
export DOTFILES_DIR

# --- Early essentials --------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Set LS_COLORS using vivid (no built-in GitHub Dark theme; one-dark is the closest
# bundled match — eza's exact GitHub Dark colors below take precedence for `ls`/`ll`/etc.)
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate one-dark)"
fi

# --- Homebrew (macOS) --------------------------------------------------------
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Homebrew's versioned PostgreSQL formula is keg-only.
if [ -d "${HOMEBREW_PREFIX}/opt/postgresql@18/bin" ]; then
  export PATH="${HOMEBREW_PREFIX}/opt/postgresql@18/bin:$PATH"
fi

# --- History -----------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # timestamps in history
setopt HIST_EXPIRE_DUPS_FIRST    # expire dupes first when trimming
setopt HIST_IGNORE_DUPS          # no consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate
setopt HIST_IGNORE_SPACE         # commands starting with space not saved
setopt HIST_FIND_NO_DUPS         # no dupes in search results
setopt HIST_SAVE_NO_DUPS         # no dupes written to file
setopt SHARE_HISTORY             # share history across sessions (implies INC_APPEND_HISTORY)

# --- Shell options -----------------------------------------------------------
setopt AUTO_CD                   # cd by typing directory name
setopt AUTO_PUSHD                # pushd on every cd
setopt PUSHD_IGNORE_DUPS         # no duplicate dirs in stack
setopt PUSHD_SILENT              # don't print stack after pushd
setopt CORRECT                   # command spelling correction
setopt INTERACTIVE_COMMENTS      # allow # comments in interactive shell
setopt NO_BEEP                   # silence

# --- Zinit plugin manager ----------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Completion definitions must load before compinit runs
zinit light zsh-users/zsh-completions

# --- Zinit: Load OMZ essentials (snippets) -----------------------------------
zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/key-bindings.zsh

# --- Zinit: Defer non-critical plugins for snappy startup --------------------
zinit light romkatv/zsh-defer

# fzf-tab: fuzzy tab-completion menu (must load before autosuggestions/syntax-highlighting)
if [ -d "$ZINIT_HOME" ]; then
  zinit light Aloxaf/fzf-tab
  zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --group-directories-first -1 --color=always $realpath 2>/dev/null'
  zstyle ':fzf-tab:*' switch-group ',' '.'

  zinit light zsh-users/zsh-autosuggestions
  zinit light zdharma-continuum/fast-syntax-highlighting  # must be last
fi

zinit wait"0" lucid for \
  atinit"zicompinit; zicdreplay" \
    zsh-users/zsh-completions \
  blockf \
    zsh-users/zsh-autosuggestions \
  atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-history-substring-search \
  Aloxaf/fzf-tab \
  zdharma-continuum/fast-syntax-highlighting

# --- Completion system settings (after zinit) -------------------------------
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# --- Key bindings (substring search) -----------------------------------------
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
# Support for zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- FZF integration ---------------------------------------------------------
if command -v fzf &>/dev/null; then
  # GitHub Dark — https://github.com/projekt0n/github-nvim-theme
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline \
--color=bg+:#161b22,bg:#0d1117,spinner:#58a6ff,hl:#ff7b72 \
--color=fg:#e6edf3,header:#ff7b72,info:#bc8cff,pointer:#58a6ff \
--color=marker:#3fb950,fg+:#e6edf3,prompt:#58a6ff,hl+:#ffa198 \
--color=selected-bg:#30363d \
--color=border:#30363d,label:#e6edf3"

  # Use fd for file finding if available
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Source Homebrew's fzf keybindings.
  # Only when attached to a real TTY: fzf's scripts snapshot/restore all
  # shell options (including the internal `zle` option), which zsh refuses
  # to set explicitly outside a real terminal and prints a harmless but
  # noisy "can't change option: zle" error.
  if [ -t 1 ]; then
    if [ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh" ]; then
      source "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
      source "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"
    fi
  fi
fi

# --- Eza colors (GitHub Dark) ------------------------------------------------
if command -v eza &>/dev/null; then
  export EZA_COLORS="di=38;2;88;166;255:ex=38;2;63;185;80:ln=38;2;57;197;207:\
pi=38;2;210;153;34:so=38;2;188;140;255:bd=38;2;240;136;62:cd=38;2;240;136;62:\
or=38;2;255;123;114:uu=38;2;63;185;80:un=38;2;255;123;114:gu=38;2;63;185;80:\
gn=38;2;255;123;114:da=38;2;57;197;207"
fi

# --- Zoxide (smarter cd) ----------------------------------------------------
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# --- Atuin (searchable shell history, local-only) -----------------------------
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# --- Mise (per-project runtime version manager) ------------------------------
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# --- Direnv (Project environment variables) ----------------------------------
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# --- 1Password local development environment ---------------------------------
[ -f "$DOTFILES_DIR/zsh/1password.zsh" ] && source "$DOTFILES_DIR/zsh/1password.zsh"

# --- Ripgrep config ----------------------------------------------------------
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# --- Aliases -----------------------------------------------------------------
[ -f "$DOTFILES_DIR/zsh/aliases.zsh" ] && source "$DOTFILES_DIR/zsh/aliases.zsh"

# --- Starship prompt (must be last) ------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"

# --- Local overrides (not tracked in git) ------------------------------------
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
