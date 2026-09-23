#!/usr/bin/env bash
set -euo pipefail

# Idempotent bootstrap for the macOS work environment.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backups/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
SKIP_APPS=false
NO_UPDATE=false

info() { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
success() { printf '\033[1;32m[ok]\033[0m   %s\n' "$1"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$1"; }
error() { printf '\033[1;31m[err]\033[0m  %s\n' "$1" >&2; }

usage() {
  printf '%s\n' \
    "Usage: ./install.sh [--dry-run] [--skip-apps] [--no-update]" \
    "" \
    "  --dry-run    Print changes without applying them" \
    "  --skip-apps  Skip Homebrew casks and Mac App Store apps" \
    "  --no-update  Skip brew update"
}

run() {
  if $DRY_RUN; then
    printf '\033[1;36m[dry-run]\033[0m'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

manifest_entries() {
  sed \
    -e 's/[[:space:]]*#.*$//' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//' \
    -e '/^$/d' \
    "$1"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --skip-apps) SKIP_APPS=true ;;
      --no-update) NO_UPDATE=true ;;
      -h|--help) usage; exit 0 ;;
      *) error "Unknown option: $1"; usage; exit 2 ;;
    esac
    shift
  done
}

require_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    error "This work fork supports macOS only."
    exit 1
  fi
}

link_file() {
  local src="$1"
  local dst="$2"

  if ! $DRY_RUN && [ ! -e "$src" ] && [ ! -L "$src" ]; then
    error "Cannot link missing source: $src"
    exit 1
  fi

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    success "Already linked: $dst"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup_dst="$BACKUP_DIR${dst#"$HOME"}"
    run mkdir -p "$(dirname "$backup_dst")"
    run mv "$dst" "$backup_dst"
    warn "Backed up $dst to $backup_dst"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}

copy_local_template() {
  local src="$1"
  local dst="$2"
  local mode="$3"

  if [ -e "$dst" ]; then
    success "Local file already exists: $dst"
    return
  fi

  run mkdir -p "$(dirname "$dst")"
  run install -m "$mode" "$src" "$dst"
  warn "Created $dst from a sanitized template; review its placeholders."
}

setup_vscode_settings() {
  local shared_settings="$HOME/.config/dotfiles/vscode-settings.json"
  local stable_settings="$HOME/Library/Application Support/Code/User/settings.json"
  local insiders_settings="$HOME/Library/Application Support/Code - Insiders/User/settings.json"
  local backup_settings="$BACKUP_DIR/.config/dotfiles/vscode-settings.json"
  local rendered_settings
  local ripgrep_path

  ripgrep_path="$(brew --prefix ripgrep)/bin/rg"
  if ! $DRY_RUN && [ ! -x "$ripgrep_path" ]; then
    error "Homebrew ripgrep executable is unavailable: $ripgrep_path"
    exit 1
  fi

  if $DRY_RUN; then
    info "Would render shared VS Code settings with ripgrep at $ripgrep_path"
  else
    rendered_settings="$(mktemp)"
    sed -e "s|__DOTFILES_RIPGREP__|$ripgrep_path|" \
      "$DOTFILES_DIR/vscode/settings.json" > "$rendered_settings"

    if [ -e "$shared_settings" ] && ! cmp -s "$rendered_settings" "$shared_settings"; then
      mkdir -p "$(dirname "$backup_settings")"
      cp -p "$shared_settings" "$backup_settings"
      warn "Backed up $shared_settings to $backup_settings"
    fi

    mkdir -p "$(dirname "$shared_settings")"
    install -m 600 "$rendered_settings" "$shared_settings"
    rm -f "$rendered_settings"
  fi
  success "Rendered shared local VS Code settings: $shared_settings"

  link_file "$shared_settings" "$stable_settings"
  link_file "$shared_settings" "$insiders_settings"
}

install_homebrew() {
  if ! command_exists brew; then
    info "Installing Homebrew..."
    if $DRY_RUN; then
      info "Would download and run the official Homebrew installer."
      return
    fi

    local installer
    installer="$(mktemp)"
    curl -fsSLo "$installer" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    env NONINTERACTIVE=1 /bin/bash "$installer"
    rm -f "$installer"

    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  if ! $NO_UPDATE; then
    run brew update
  fi

  info "Installing Homebrew formulae..."
  while IFS= read -r package; do
    if ! brew list --formula "$package" >/dev/null 2>&1; then
      run brew install "$package"
    fi
  done < <(manifest_entries "$DOTFILES_DIR/packages/brew-formulae.txt")

  if $SKIP_APPS; then
    info "Skipping casks and Mac App Store apps."
    return
  fi

  info "Installing Homebrew casks..."
  while IFS= read -r package; do
    if ! brew list --cask "$package" >/dev/null 2>&1; then
      run brew install --cask "$package"
    fi
  done < <(manifest_entries "$DOTFILES_DIR/packages/brew-casks.txt")

  if ! command_exists mas; then
    warn "mas is unavailable; skipping Mac App Store apps."
    return
  fi

  while IFS= read -r app_id; do
    if ! mas list | awk '{print $1}' | grep -qx "$app_id"; then
      if ! run mas install "$app_id"; then
        warn "Could not install App Store app $app_id; sign in to the App Store and retry."
      fi
    fi
  done < <(manifest_entries "$DOTFILES_DIR/packages/mas-apps.txt")
}

setup_local_files() {
  copy_local_template "$DOTFILES_DIR/examples/gitconfig.local" "$HOME/.gitconfig.local" 600
  copy_local_template "$DOTFILES_DIR/examples/ssh-config.local" "$HOME/.ssh/config.local" 600
  copy_local_template "$DOTFILES_DIR/examples/tmux.conf.local" "$HOME/.tmux.conf.local" 600

  run mkdir -p "$HOME/.config/dotfiles/hooks.local"
  run chmod 700 "$HOME/.ssh" "$HOME/.config/dotfiles" "$HOME/.config/dotfiles/hooks.local"

  if [ ! -e "$HOME/.ssh/allowed_signers" ]; then
    run touch "$HOME/.ssh/allowed_signers"
    run chmod 600 "$HOME/.ssh/allowed_signers"
    warn "Created ~/.ssh/allowed_signers; add the public half of your 1Password signing key."
  fi
}

create_symlinks() {
  info "Linking managed configuration..."
  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link_file "$DOTFILES_DIR/git/hooks" "$HOME/.githooks"
  link_file "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
  link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
  link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  link_file "$DOTFILES_DIR/bat/config" "$HOME/.config/bat/config"
  link_file "$DOTFILES_DIR/bat/themes/GitHub Dark.tmTheme" "$HOME/.config/bat/themes/GitHub Dark.tmTheme"
  link_file "$DOTFILES_DIR/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  link_file "$DOTFILES_DIR/ripgrep/.ripgreprc" "$HOME/.ripgreprc"
  link_file "$DOTFILES_DIR/editorconfig/.editorconfig" "$HOME/.editorconfig"
  link_file "$DOTFILES_DIR/sqlfluff/.sqlfluff" "$HOME/.sqlfluff"
  link_file "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"
  link_file "$DOTFILES_DIR/atuin/config.toml" "$HOME/.config/atuin/config.toml"
  link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_file "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
  setup_vscode_settings
  link_file "$DOTFILES_DIR/bin/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
  link_file "$DOTFILES_DIR/bin/op-ssh-sign" "$HOME/.local/bin/op-ssh-sign"

  if [ -f "$DOTFILES_DIR/mise/mise.lock" ]; then
    link_file "$DOTFILES_DIR/mise/mise.lock" "$HOME/.config/mise/mise.lock"
  fi
  if [ -d "$DOTFILES_DIR/mise/.mise/locks" ]; then
    link_file "$DOTFILES_DIR/mise/.mise" "$HOME/.config/mise/.mise"
  fi
}

install_mise_tools() {
  if ! command_exists mise; then
    warn "mise is unavailable; skipping managed runtimes."
    return
  fi

  run mise trust -y "$HOME/.config/mise/config.toml"
  if [ -f "$DOTFILES_DIR/mise/mise.lock" ]; then
    # The lock pins every resolved version. Mise's dotnet-tool backend does
    # not emit artifact URLs, so strict --locked mode cannot install those
    # entries even though their versions are present in the lockfile.
    run mise install -y
  else
    warn "mise/mise.lock is not present; resolving tools without a lockfile."
    run mise install -y
  fi
}

install_gh_extensions() {
  if ! command_exists gh || ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI is not authenticated; skipping extensions."
    return
  fi

  while IFS= read -r extension; do
    if ! gh extension list | awk '{print $1}' | grep -qx "$extension"; then
      run gh extension install "$extension"
    fi
  done < <(manifest_entries "$DOTFILES_DIR/packages/gh-extensions.txt")
}

install_shell_and_editor_plugins() {
  local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ ! -d "$zinit_home" ]; then
    run mkdir -p "$(dirname "$zinit_home")"
    run git clone https://github.com/zdharma-continuum/zinit.git "$zinit_home"
  fi

  if [ ! -d "$tpm_dir" ]; then
    run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  if [ -x "$tpm_dir/bin/install_plugins" ]; then
    run "$tpm_dir/bin/install_plugins"
  fi

  if command_exists nvim; then
    run nvim --headless "+Lazy! restore" +qa
  fi

  if command_exists bat; then
    run bat cache --build
  fi
}

install_vscode_extensions() {
  local insiders_cli="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
  local -a labels=()
  local -a clis=()

  if command_exists code; then
    labels+=("stable")
    clis+=("$(command -v code)")
  fi
  if [ -x "$insiders_cli" ]; then
    labels+=("insiders")
    clis+=("$insiders_cli")
  fi

  if [ "${#clis[@]}" -eq 0 ]; then
    warn "VS Code CLIs are unavailable; skipping extensions."
    return
  fi

  local index label cli inventory extension extension_id installed_version
  for index in "${!clis[@]}"; do
    label="${labels[$index]}"
    cli="${clis[$index]}"
    inventory="$BACKUP_DIR/vscode-extensions-$label.txt"

    if $DRY_RUN; then
      info "Would back up the $label VS Code extension inventory to $inventory"
    else
      mkdir -p "$BACKUP_DIR"
      "$cli" --list-extensions --show-versions | sort > "$inventory"
    fi

    while IFS= read -r extension; do
      extension_id="${extension%%@*}"
      installed_version="$(
        "$cli" --list-extensions --show-versions |
          awk -F@ -v id="$extension_id" 'tolower($1) == tolower(id) { print $2; exit }'
      )"
      if [ "$installed_version" = "${extension#*@}" ]; then
        success "$label extension already pinned: $extension"
      else
        run "$cli" --install-extension "$extension" --force
      fi
    done < <(manifest_entries "$DOTFILES_DIR/vscode/extensions.txt")

    while IFS= read -r extension_id; do
      if ! manifest_entries "$DOTFILES_DIR/vscode/extensions.txt" |
        cut -d@ -f1 |
        grep -Fxiq "$extension_id"; then
        if "$cli" --list-extensions | grep -Fxiq "$extension_id"; then
          run "$cli" --uninstall-extension "$extension_id"
        fi
      fi
    done < <("$cli" --list-extensions | LC_ALL=C sort -r)
  done
}

main() {
  parse_args "$@"
  require_macos

  info "Bootstrapping the macOS work environment from $DOTFILES_DIR"
  install_homebrew
  setup_local_files
  create_symlinks
  install_mise_tools
  install_gh_extensions
  install_shell_and_editor_plugins
  install_vscode_extensions

  success "Bootstrap complete."
  info "Backups, if any, are in $BACKUP_DIR"
  info "Review the optional *.local files before use."
  info "Start Colima when needed with: colima start"
  info "Terminal.app and Warp appearance remain manual choices."
  info "Reload the shell with: exec zsh"
}

main "$@"
