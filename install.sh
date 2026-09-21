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
        git-delta lazygit gh gitleaks yazi direnv just lazydocker bottom mise vivid
        tldr jq yq htop ncdu httpie tree shellcheck tokei hyperfine difftastic
        atuin pinentry-mac 1password-cli television
        ruff golangci-lint pnpm fastfetch mods node
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
        neovim tmux fzf ripgrep fd-find bat zoxide git curl wget unzip
        tldr jq yq htop ncdu httpie tree shellcheck pinentry-curses gnupg
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

    # Pnpm (Fast Node package manager)
    if ! command_exists pnpm; then
        info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
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

    # Lazydocker
    if ! command_exists lazydocker; then
        info "Installing lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi

    # Vivid (LS_COLORS generator)
    if ! command_exists vivid; then
        info "Installing vivid..."
        local vivid_ver
        vivid_ver=$(curl -sL https://api.github.com/repos/sharkdp/vivid/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        local arch_vivid="amd64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_vivid="arm64"; fi
        curl -sLo /tmp/vivid.deb "https://github.com/sharkdp/vivid/releases/download/${vivid_ver}/vivid_${vivid_ver#v}_${arch_vivid}.deb"
        sudo dpkg -i /tmp/vivid.deb
        rm -f /tmp/vivid.deb
    fi

    # Mods (AI for piping)
    if ! command_exists mods; then
        info "Installing mods..."
        local mods_ver
        mods_ver=$(curl -sL https://api.github.com/repos/charmbracelet/mods/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        local arch_mods="amd64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_mods="arm64"; fi
        curl -sLo /tmp/mods.deb "https://github.com/charmbracelet/mods/releases/download/${mods_ver}/mods_${mods_ver#v}_${arch_mods}.deb"
        sudo dpkg -i /tmp/mods.deb
        rm -f /tmp/mods.deb
    fi

    # Fastfetch (System info)
    if ! command_exists fastfetch; then
        info "Installing fastfetch..."
        local ff_ver
        ff_ver=$(curl -sL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        local arch_ff="linux-amd64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_ff="linux-aarch64"; fi
        curl -sLo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${ff_ver}/fastfetch-${arch_ff}.deb"
        sudo dpkg -i /tmp/fastfetch.deb
        rm -f /tmp/fastfetch.deb
    fi

    # Create compatibility symlinks for Ubuntu's renamed binaries
    mkdir -p "$HOME/.local/bin"
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
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Yazi — from GitHub releases
    if ! command_exists yazi; then
        info "Installing yazi..."
        local yazi_ver
        yazi_ver=$(curl -sL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        local arch_yazi="x86_64-unknown-linux-gnu"
        if [ "$(uname -m)" = "aarch64" ]; then arch_yazi="aarch64-unknown-linux-gnu"; fi
        curl -sLo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${yazi_ver}/yazi-${arch_yazi}.zip"
        unzip -qo /tmp/yazi.zip -d /tmp
        sudo mv /tmp/yazi-${arch_yazi}/yazi /usr/local/bin/
        sudo mv /tmp/yazi-${arch_yazi}/ya /usr/local/bin/
        rm -rf /tmp/yazi.zip /tmp/yazi-${arch_yazi}
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

    # Delta — from GitHub releases
    if ! command_exists delta; then
        info "Installing delta..."
        local delta_ver
        delta_ver=$(curl -sL https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        local arch
        arch=$(dpkg --print-architecture)
        curl -sLo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${delta_ver}/git-delta_${delta_ver}_${arch}.deb"
        sudo dpkg -i /tmp/delta.deb
        rm -f /tmp/delta.deb
    fi

    # Lazygit — from GitHub releases
    if ! command_exists lazygit; then
        info "Installing lazygit..."
        local lg_ver
        lg_ver=$(curl -sL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
        local arch_lg="Linux_x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_lg="Linux_arm64"; fi
        curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${lg_ver}/lazygit_${lg_ver}_${arch_lg}.tar.gz"
        tar xzf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo mv /tmp/lazygit /usr/local/bin/lazygit
        rm -f /tmp/lazygit.tar.gz
    fi

    # yq — from GitHub releases
    if ! command_exists yq; then
        info "Installing yq..."
        local arch_yq="amd64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_yq="arm64"; fi
        curl -sLo /tmp/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch_yq}"
        chmod +x /tmp/yq && sudo mv /tmp/yq /usr/local/bin/yq
    fi

    # tokei — from GitHub releases
    if ! command_exists tokei; then
        info "Installing tokei..."
        local arch_tokei="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_tokei="aarch64"; fi
        local tokei_ver
        tokei_ver=$(curl -sL https://api.github.com/repos/XAMPPRocky/tokei/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/tokei.tar.gz "https://github.com/XAMPPRocky/tokei/releases/download/${tokei_ver}/tokei-${arch_tokei}-unknown-linux-gnu.tar.gz"
        tar xzf /tmp/tokei.tar.gz -C /tmp tokei
        sudo mv /tmp/tokei /usr/local/bin/tokei
        rm -f /tmp/tokei.tar.gz
    fi

    # hyperfine — from GitHub releases
    if ! command_exists hyperfine; then
        info "Installing hyperfine..."
        local arch_hf="amd64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_hf="arm64"; fi
        local hf_ver
        hf_ver=$(curl -sL https://api.github.com/repos/sharkdp/hyperfine/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/hyperfine.deb "https://github.com/sharkdp/hyperfine/releases/download/${hf_ver}/hyperfine_${hf_ver#v}_${arch_hf}.deb"
        sudo dpkg -i /tmp/hyperfine.deb
        rm -f /tmp/hyperfine.deb
    fi

    # difftastic — from GitHub releases
    if ! command_exists difft; then
        info "Installing difftastic..."
        local arch_dft="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_dft="aarch64"; fi
        local dft_ver
        dft_ver=$(curl -sL https://api.github.com/repos/Wilfred/difftastic/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/difft.tar.gz "https://github.com/Wilfred/difftastic/releases/download/${dft_ver}/difft-${arch_dft}-unknown-linux-gnu.tar.gz"
        tar xzf /tmp/difft.tar.gz -C /tmp
        sudo mv /tmp/difft /usr/local/bin/difft
        rm -f /tmp/difft.tar.gz
    fi

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

    # gitleaks — from GitHub releases
    if ! command_exists gitleaks; then
        info "Installing gitleaks..."
        local arch_gl="x64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_gl="arm64"; fi
        local gl_ver
        gl_ver=$(curl -sL https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
        curl -sLo /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v${gl_ver}/gitleaks_${gl_ver}_linux_${arch_gl}.tar.gz"
        tar xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
        sudo mv /tmp/gitleaks /usr/local/bin/gitleaks
        rm -f /tmp/gitleaks.tar.gz
    fi

    # atuin — official installer
    if ! command_exists atuin; then
        info "Installing atuin..."
        curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh -s -- --no-modify-path
    fi

    # mise — official installer
    if ! command_exists mise; then
        info "Installing mise..."
        curl -sS https://mise.run | sh
    fi

    # 1Password CLI — official apt repo
    if ! command_exists op; then
        info "Installing 1Password CLI..."
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq 1password-cli
    fi

    # yazi — from GitHub releases
    if ! command_exists yazi; then
        info "Installing yazi..."
        local arch_yz="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_yz="aarch64"; fi
        local yz_ver
        yz_ver=$(curl -sL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${yz_ver}/yazi-${arch_yz}-unknown-linux-gnu.zip"
        unzip -qo /tmp/yazi.zip -d /tmp
        sudo mv /tmp/yazi-${arch_yz}-unknown-linux-gnu/yazi /tmp/yazi-${arch_yz}-unknown-linux-gnu/ya /usr/local/bin/
        rm -rf /tmp/yazi.zip /tmp/yazi-${arch_yz}-unknown-linux-gnu
    fi

    # television — from GitHub releases
    if ! command_exists tv; then
        info "Installing television..."
        local arch_tv="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_tv="aarch64"; fi
        local tv_ver
        tv_ver=$(curl -sL https://api.github.com/repos/alexpasmantier/television/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/tv.tar.gz "https://github.com/alexpasmantier/television/releases/download/${tv_ver}/television-${tv_ver}-${arch_tv}-unknown-linux-gnu.tar.gz"
        tar xzf /tmp/tv.tar.gz -C /tmp
        sudo mv /tmp/tv /usr/local/bin/tv
        rm -f /tmp/tv.tar.gz
    fi

    # bottom — from GitHub releases
    if ! command_exists btm; then
        info "Installing bottom..."
        local arch_bt="x86_64"
        if [ "$(uname -m)" = "aarch64" ]; then arch_bt="aarch64"; fi
        local bt_ver
        bt_ver=$(curl -sL https://api.github.com/repos/ClementTsang/bottom/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)
        curl -sLo /tmp/bottom.tar.gz "https://github.com/ClementTsang/bottom/releases/download/${bt_ver}/bottom_${arch_bt}-unknown-linux-gnu.tar.gz"
        tar xzf /tmp/bottom.tar.gz -C /tmp btm
        sudo mv /tmp/btm /usr/local/bin/btm
        rm -f /tmp/bottom.tar.gz
    fi

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

    # Create symlinks
    create_symlinks

    # Install plugin managers
    install_zinit
    install_tpm

    # Install extensions/plugins
    install_vscode_extensions
    install_nvim_plugins

    echo ""
    echo "========================================="
    success "Dotfiles installation complete!"
    echo "========================================="
    echo ""
    info "Backups (if any) are in: $BACKUP_DIR"
    info "Personal git config:     ~/.gitconfig.local"
    info "Local zsh overrides:     ~/.zshrc.local"
    info "Local tmux overrides:    ~/.tmux.local.conf"
    echo ""
    info "Run 'exec zsh' to reload your shell"
    info "In tmux, press Ctrl-a + I to install tmux plugins"
    echo ""
}

main "$@"
