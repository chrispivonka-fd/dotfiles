#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles installer — works on macOS and Ubuntu/Debian
# Safe to run multiple times (idempotent)
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
info()    { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
success() { printf '\033[1;32m[ok]\033[0m   %s\n' "$1"; }
warn()    { printf '\033[1;33m[warn]\033[0m %s\n' "$1"; }
error()   { printf '\033[1;31m[err]\033[0m  %s\n' "$1"; }

command_exists() { command -v "$1" &>/dev/null; }

# Create a symlink, backing up any existing file
link_file() {
    local src="$1" dst="$2"

    # Already the correct symlink — skip
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        success "Already linked: $dst"
        return
    fi

    # Something exists at the destination — back it up
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
        warn "Backed up existing $dst → $BACKUP_DIR/"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    success "Linked: $dst → $src"
}

# -----------------------------------------------------------------------------
# Detect OS
# -----------------------------------------------------------------------------
detect_os() {
    case "$OSTYPE" in
        darwin*)  OS="macos" ;;
        linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian|pop|linuxmint|elementary) OS="debian" ;;
                    *) error "Unsupported Linux distro: $ID"; exit 1 ;;
                esac
            else
                error "Cannot detect Linux distribution"; exit 1
            fi
            ;;
        *) error "Unsupported OS: $OSTYPE"; exit 1 ;;
    esac
    info "Detected OS: $OS"
}

# -----------------------------------------------------------------------------
# Package installation — macOS
# -----------------------------------------------------------------------------
install_packages_macos() {
    # Install Homebrew if missing
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi

    local packages=(
        neovim tmux starship fzf ripgrep fd bat eza zoxide
        gh git-lfs direnv just mise
        tldr jq htop ncdu httpie tree shellcheck
        pinentry-mac 1password-cli
        ruff golangci-lint node
        awscli aws-vault terraform
    )

    info "Installing packages via Homebrew..."
    brew install "${packages[@]}" 2>/dev/null || true
    
    # Google Cloud SDK (cask)
    if ! command_exists gcloud; then
        info "Installing Google Cloud SDK..."
        brew install --cask google-cloud-sdk 2>/dev/null || true
    fi

    success "Homebrew packages installed"

    # delta, lazygit, lazydocker, yq, gitleaks, tree-sitter, yazi, bottom,
    # atuin, vivid are installed later via mise (see install_mise_tools) for
    # one consistent, checksum-verified path across both macOS and Linux —
    # see mise/config.toml.

    # Nerd Fonts (needed for icons in starship, neovim, eza, etc.)
    local fonts=(
        font-meslo-lg-nerd-font
        font-jetbrains-mono-nerd-font
        font-fira-code-nerd-font
    )
    info "Installing Nerd Fonts..."
    brew install --cask "${fonts[@]}" 2>/dev/null || true
    success "Nerd Fonts installed"

    # Claude Code (Anthropic CLI)
    if ! command_exists claude; then
        info "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null || true
    fi

    # Gemini CLI (Google AI CLI)
    if ! command_exists gemini; then
        info "Installing Gemini CLI..."
        npm install -g @google/gemini-cli 2>/dev/null || true
    fi

    # AWS CDK
    if ! command_exists cdk; then
        info "Installing AWS CDK..."
        npm install -g aws-cdk 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# Package installation — Debian/Ubuntu
# -----------------------------------------------------------------------------
install_packages_debian() {
    info "Updating apt package lists..."
    sudo apt-get update -qq

    # Core packages available in default repos
    local apt_packages=(
        neovim tmux fzf ripgrep fd-find bat zoxide git git-lfs curl wget unzip
        tldr jq htop ncdu httpie tree shellcheck pinentry-curses gnupg
        direnv nodejs npm terraform
    )
    info "Installing core packages via apt..."
    sudo apt-get install -y -qq "${apt_packages[@]}"

    # Just (Task runner)
    if ! command_exists just; then
        info "Installing just..."
        curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
    fi

    # Mise (Manager for dev tools/languages)
    if ! command_exists mise; then
        info "Installing mise..."
        curl https://mise.jdx.dev/install.sh | sh
    fi

    # Ruff (Python linter/formatter)
    if ! command_exists ruff; then
        info "Installing ruff..."
        curl -LsSf https://astral.sh/ruff/install.sh | sh
    fi

    # Claude Code (Anthropic CLI)
    if ! command_exists claude; then
        info "Installing Claude Code..."
        sudo npm install -g @anthropic-ai/claude-code 2>/dev/null || true
    fi

    # Gemini CLI (Google AI CLI)
    if ! command_exists gemini; then
        info "Installing Gemini CLI..."
        sudo npm install -g @google/gemini-cli 2>/dev/null || true
    fi

    # AWS CDK
    if ! command_exists cdk; then
        info "Installing AWS CDK..."
        sudo npm install -g aws-cdk 2>/dev/null || true
    fi

    # AWS CLI v2
    if ! command_exists aws; then
        info "Installing AWS CLI v2..."
        local arch_aws="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_aws="aarch64"; fi
        curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch_aws}.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install --update
        rm -rf aws awscliv2.zip
    fi

    # Google Cloud SDK
    if ! command_exists gcloud; then
        info "Installing Google Cloud SDK..."
        curl https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME/.local/share"
        # The installer adds to .zshrc, but we might want to handle it ourselves
    fi

    # Golangci-lint
    if ! command_exists golangci-lint; then
        info "Installing golangci-lint..."
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin
    fi

    # Create compatibility symlinks for Ubuntu's renamed binaries
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH" # so mise (installed below) is found later in this script
    if command_exists batcat && ! command_exists bat; then
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        success "Linked batcat → bat"
    fi
    if command_exists fdfind && ! command_exists fd; then
        ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        success "Linked fdfind → fd"
    fi

    # Starship — official installer
    if ! command_exists starship; then
        info "Installing starship..."
        curl --proto '=https' --tlsv1.2 -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Eza — from official repo
    if ! command_exists eza; then
        info "Installing eza..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq eza
    fi

    # delta, lazygit, lazydocker, yq, gitleaks, tree-sitter, yazi, bottom,
    # atuin, vivid are installed later via mise (see install_mise_tools) —
    # mise's aqua backend checksum-verifies these GitHub releases instead of
    # the hand-rolled curl+API pattern used elsewhere in this function.

    # GitHub CLI — official apt repo
    if ! command_exists gh; then
        info "Installing GitHub CLI..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh
    fi

    # mise — official installer
    if ! command_exists mise; then
        info "Installing mise..."
        curl --proto '=https' --tlsv1.2 -sS https://mise.run | sh
    fi

    # 1Password CLI — official apt repo
    if ! command_exists op; then
        info "Installing 1Password CLI..."
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq 1password-cli
    fi

    # AWS CLI v2 — official installer
    if ! command_exists aws; then
        info "Installing AWS CLI v2..."
        local arch_aws="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_aws="aarch64"; fi
        curl --proto '=https' --tlsv1.2 -fsSLo /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${arch_aws}.zip"
        unzip -qo /tmp/awscliv2.zip -d /tmp
        sudo /tmp/aws/install --update
        rm -rf /tmp/awscliv2.zip /tmp/aws
    fi

    # pnpm, bun, uv are installed later via mise (see install_mise_tools)

    # Nerd Fonts — download from GitHub releases
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    local nerd_fonts=("Meslo" "JetBrainsMono" "FiraCode")
    local nf_version
    nf_version=$(curl -sL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
    for font in "${nerd_fonts[@]}"; do
        if ! ls "$font_dir"/*"${font}"* &>/dev/null; then
            info "Installing Nerd Font: $font..."
            curl -sLo "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/${font}.zip"
            unzip -qo "/tmp/${font}.zip" -d "$font_dir"
            rm -f "/tmp/${font}.zip"
        fi
    done
    fc-cache -f "$font_dir" 2>/dev/null || true
    success "Nerd Fonts installed"

    success "All Debian/Ubuntu packages installed"
}

# -----------------------------------------------------------------------------
# Extract personal git config → ~/.gitconfig.local
# -----------------------------------------------------------------------------
setup_gitconfig_local() {
    if [ -f "$HOME/.gitconfig.local" ]; then
        info "~/.gitconfig.local already exists, skipping extraction"
        return
    fi

    info "Extracting personal git settings to ~/.gitconfig.local..."

    local name email signingkey gpgsign=""
    name=$(git config --global --get user.name 2>/dev/null || echo "")
    email=$(git config --global --get user.email 2>/dev/null || echo "")
    signingkey=$(git config --global --get user.signingkey 2>/dev/null || echo "")
    gpgsign=$(git config --global --get commit.gpgsign 2>/dev/null || echo "")

    cat > "$HOME/.gitconfig.local" <<EOF
# Personal git settings — not tracked in dotfiles repo
# Edit this file for machine-specific git configuration

[user]
    name = ${name}
    email = ${email}
EOF

    if [ -n "$signingkey" ]; then
        cat >> "$HOME/.gitconfig.local" <<EOF
    signingkey = ${signingkey}
EOF
    fi

    if [ -n "$gpgsign" ]; then
        cat >> "$HOME/.gitconfig.local" <<EOF

[commit]
    gpgsign = ${gpgsign}
EOF
    fi

    # OS-specific credential helper
    if [ "$OS" = "macos" ]; then
        cat >> "$HOME/.gitconfig.local" <<EOF

[credential]
    helper = osxkeychain
EOF
    else
        cat >> "$HOME/.gitconfig.local" <<EOF

[credential]
    helper = cache --timeout=86400
EOF
    fi

    success "Created ~/.gitconfig.local"
}

# -----------------------------------------------------------------------------
# Create ~/.zshrc.local stub
# -----------------------------------------------------------------------------
setup_zshrc_local() {
    if [ -f "$HOME/.zshrc.local" ]; then
        info "~/.zshrc.local already exists, skipping"
        return
    fi

    cat > "$HOME/.zshrc.local" <<'EOF'
# Local zsh overrides — not tracked in dotfiles repo
# Add machine-specific exports, PATH entries, API keys, etc.

# Example:
# export ANTHROPIC_API_KEY="sk-ant-..."
# export GEMINI_API_KEY="..."
# export OPENAI_API_KEY="sk-..."
# export PATH="$HOME/custom/bin:$PATH"
EOF

    success "Created ~/.zshrc.local"
}

# -----------------------------------------------------------------------------
# Create ~/.tmux.local.conf stub
# -----------------------------------------------------------------------------
setup_tmux_local() {
    if [ -f "$HOME/.tmux.local.conf" ]; then
        info "~/.tmux.local.conf already exists, skipping"
        return
    fi

    cat > "$HOME/.tmux.local.conf" <<'EOF'
# Local tmux overrides — not tracked in dotfiles repo
# Add machine-specific tmux settings here

# Example:
# set -g status-right '#[fg=white]#H  %H:%M  %d-%b '
EOF

    success "Created ~/.tmux.local.conf"
}

# -----------------------------------------------------------------------------
# Setup ~/.ssh/allowed_signers (required for SSH commit signing via 1Password)
# -----------------------------------------------------------------------------
setup_allowed_signers() {
    local allowed_signers="$HOME/.ssh/allowed_signers"
    if [ -f "$allowed_signers" ]; then
        info "~/.ssh/allowed_signers already exists, skipping"
        return
    fi

    mkdir -p "$HOME/.ssh"
    # Try to populate from existing gitconfig email + ssh public keys
    local email
    email=$(git config --global --get user.email 2>/dev/null || echo "")

    if [ -n "$email" ]; then
        local key_added=false
        for pub_key in "$HOME/.ssh/"*.pub; do
            [ -f "$pub_key" ] || continue
            echo "${email} $(cat "$pub_key")" >> "$allowed_signers"
            success "Added $(basename "$pub_key") to ~/.ssh/allowed_signers for $email"
            key_added=true
        done
        if ! $key_added; then
            # Create empty file so git doesn't error; user fills in manually
            touch "$allowed_signers"
            warn "No SSH public keys found. Add your signing key to ~/.ssh/allowed_signers:"
            warn "  echo \"$email \$(cat ~/.ssh/id_ed25519.pub)\" >> ~/.ssh/allowed_signers"
        fi
    else
        touch "$allowed_signers"
        warn "git user.email not set. Populate ~/.ssh/allowed_signers manually:"
        warn "  echo \"you@example.com \$(cat ~/.ssh/id_ed25519.pub)\" >> ~/.ssh/allowed_signers"
    fi

    chmod 600 "$allowed_signers"
}

# -----------------------------------------------------------------------------
# Symlink dotfiles
# -----------------------------------------------------------------------------
create_symlinks() {
    info "Creating symlinks..."

    link_file "$DOTFILES_DIR/zsh/.zshrc"                "$HOME/.zshrc"
    link_file "$DOTFILES_DIR/git/.gitconfig"            "$HOME/.gitconfig"
    link_file "$DOTFILES_DIR/git/.gitignore_global"     "$HOME/.gitignore_global"
    link_file "$DOTFILES_DIR/starship/starship.toml"    "$HOME/.config/starship.toml"
    link_file "$DOTFILES_DIR/tmux/.tmux.conf"           "$HOME/.tmux.conf"
    link_file "$DOTFILES_DIR/nvim"                      "$HOME/.config/nvim"
    link_file "$DOTFILES_DIR/editorconfig/.editorconfig" "$HOME/.editorconfig"
    link_file "$DOTFILES_DIR/ripgrep/.ripgreprc"        "$HOME/.ripgreprc"
    link_file "$DOTFILES_DIR/git/hooks"                 "$HOME/.githooks"
    link_file "$DOTFILES_DIR/bin/tmux-sessionizer"      "$HOME/.local/bin/tmux-sessionizer"
    link_file "$DOTFILES_DIR/bin/op-ssh-sign"           "$HOME/.local/bin/op-ssh-sign"
    link_file "$DOTFILES_DIR/yazi/yazi.toml"            "$HOME/.config/yazi/yazi.toml"
    link_file "$DOTFILES_DIR/mise/config.toml"          "$HOME/.config/mise/config.toml"

    link_file "$DOTFILES_DIR/bat/config"                "$HOME/.config/bat/config"
    mkdir -p "$HOME/.config/bat/themes"
    link_file "$DOTFILES_DIR/bat/themes/GitHub Dark.tmTheme" "$HOME/.config/bat/themes/GitHub Dark.tmTheme"

    # Rebuild bat theme cache
    if command_exists bat; then
        bat cache --build &>/dev/null || true
    fi

    # lazygit's and VS Code's config dirs differ by OS
    if [ "$OS" = "macos" ]; then
        link_file "$DOTFILES_DIR/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
        local vscode_dir="$HOME/Library/Application Support/Code/User"
    else
        link_file "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
        local vscode_dir="$HOME/.config/Code/User"
    fi
    mkdir -p "$vscode_dir"
    link_file "$DOTFILES_DIR/vscode/settings.json" "$vscode_dir/settings.json"

    success "All symlinks created"

    # Rebuild bat's theme cache so the custom "GitHub Dark" theme is picked up
    if command_exists bat; then
        bat cache --build &>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# Install CLI tools declared in mise/config.toml (delta, lazygit, lazydocker,
# yq, gitleaks, tree-sitter, yazi, bottom, atuin, vivid, pnpm, bun, uv, plus
# python/node/go). Runs after create_symlinks so mise picks up the symlinked
# ~/.config/mise/config.toml as its global config.
# -----------------------------------------------------------------------------
install_mise_tools() {
    if ! command_exists mise; then
        warn "mise not found, skipping mise-managed tool install"
        return
    fi

    info "Installing tools declared in mise/config.toml (checksum-verified)..."
    mise install -y
    success "mise tools installed"
}

# -----------------------------------------------------------------------------
# Install zinit (zsh plugin manager)
# -----------------------------------------------------------------------------
install_zinit() {
    local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    if [ -d "$zinit_home" ]; then
        success "zinit already installed"
        return
    fi

    info "Installing zinit..."
    mkdir -p "$(dirname "$zinit_home")"
    git clone https://github.com/zdharma-continuum/zinit.git "$zinit_home"
    success "zinit installed"
}

# -----------------------------------------------------------------------------
# Install TPM (tmux plugin manager)
# -----------------------------------------------------------------------------
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ -d "$tpm_dir" ]; then
        success "TPM already installed"
    else
        info "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    info "Installing tmux plugins declared in .tmux.conf..."
    "$tpm_dir/bin/install_plugins" &>/dev/null || true
    success "tmux plugins installed"
}

# -----------------------------------------------------------------------------
# Install neovim plugins
# -----------------------------------------------------------------------------
install_nvim_plugins() {
    if ! command_exists nvim; then
        warn "nvim not found, skipping plugin install"
        return
    fi

    info "Installing neovim plugins (this may produce compilation output)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    success "Neovim plugins installed"
}

# -----------------------------------------------------------------------------
# Install VS Code extensions
# -----------------------------------------------------------------------------
install_vscode_extensions() {
    if ! command_exists code; then
        warn "VS Code (code) command not found, skipping extension install"
        return
    fi

    info "Installing VS Code extensions..."
    while read -r extension; do
        if [ -n "$extension" ]; then
            code --install-extension "$extension" --force &>/dev/null || true
        fi
    done < "$DOTFILES_DIR/vscode/extensions.txt"
    success "VS Code extensions installed"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "========================================="
    echo "  Dotfiles Installer"
    echo "========================================="
    echo ""

    detect_os

    # Install packages
    if [ "$OS" = "macos" ]; then
        install_packages_macos
    else
        install_packages_debian
    fi

    # Setup local config files (before symlinking overwrites configs)
    setup_gitconfig_local
    setup_zshrc_local
    setup_tmux_local
    # Create symlinks (activates .gitconfig.local via the include directive)
    create_symlinks

    # Needs the symlinked ~/.gitconfig in place so user.email resolves
    setup_allowed_signers

    # Needs the symlinked ~/.config/mise/config.toml in place
    install_mise_tools

    # Install plugin managers
    install_zinit
    install_tpm

    # Install extensions/plugins
    install_vscode_extensions
    install_nvim_plugins

    # Apply macOS system defaults (opinionated; review macos/defaults.sh first —
    # it disables the Gatekeeper "downloaded from the internet" warning, among
    # other changes). Opt in explicitly rather than applying silently.
    if [ "$OS" = "macos" ] && [ -f "$DOTFILES_DIR/macos/defaults.sh" ]; then
        read -r -p "Apply macOS system defaults from macos/defaults.sh? [y/N] " apply_defaults
        if [[ "$apply_defaults" =~ ^[Yy]$ ]]; then
            info "Applying macOS system defaults..."
            bash "$DOTFILES_DIR/macos/defaults.sh"
        else
            info "Skipped macOS system defaults. Run macos/defaults.sh manually if you want them."
        fi
    fi

    echo ""
    echo "========================================="
    success "Dotfiles installation complete!"
    echo "========================================="
    echo ""
    info "Backups (if any) are in: $BACKUP_DIR"
    info "Personal git config:     ~/.gitconfig.local"
    info "Local zsh overrides:     ~/.zshrc.local"
    info "Local tmux overrides:    ~/.tmux.local.conf"
    info "SSH signing:             ~/.ssh/allowed_signers"
    echo ""
    info "Run 'exec zsh' to reload your shell"
    info "In tmux, press Ctrl-a + I to install tmux plugins"
    info "In nvim, run :MasonUpdate to refresh LSP servers"
    info "AWS: run 'aws configure' or 'aws sso login' to authenticate"
    info "mise: run 'mise install' to install global runtimes (python, node, go)"
    info "git: run 'git maintenance start' in large repos for background optimizations"
    echo ""
}

main "$@"
