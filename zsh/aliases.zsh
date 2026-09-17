# =============================================================================
# Aliases — modern CLI replacements & shortcuts
# =============================================================================

# --- Modern replacements (only activate if tool is installed) ----------------

# eza → ls
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
    alias lt3='eza --tree --level=3 --icons'
    alias lS='eza -la --icons --sort=size --reverse'
    alias lm='eza -la --icons --sort=modified'
fi

# bat → cat
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat --plain --paging=never'
    alias batl='bat --style=full'
elif command -v batcat &>/dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
    alias catp='batcat --plain --paging=never'
fi

# fd (handle Ubuntu's fdfind)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    alias fd='fdfind'
fi

# ripgrep → grep
command -v rg &>/dev/null && alias grep='rg'

# delta → diff
command -v delta &>/dev/null && alias diff='delta'

# --- Navigation --------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# --- Git aliases -------------------------------------------------------------
alias g='git'
alias gs='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
alias gd='git diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias glp='git log --pretty=format:"%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset" -20'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gf='git fetch --all --prune'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gcp='git cherry-pick'
alias gbl='git blame'
alias gclean='git clean -fd'
alias gwip='git add -A && git commit -m "WIP [skip ci]"'
alias gunwip='git log -1 --format="%s" | grep -q "WIP" && git reset HEAD~1'
alias gtags='git tag -l --sort=-version:refname'

# lazygit
command -v lazygit &>/dev/null && alias lg='lazygit'

# lazydocker
command -v lazydocker &>/dev/null && alias lzd='lazydocker'

# gh (GitHub CLI)
if command -v gh &>/dev/null; then
    alias ghpr='gh pr create'
    alias ghprv='gh pr view --web'
    alias ghprs='gh pr status'
    alias ghis='gh issue list'
fi

# gitleaks — manual scan of the working tree (the same check the hooks run)
command -v gitleaks &>/dev/null && alias leakscan='gitleaks detect --no-git --source . -v'

# --- Docker aliases ----------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dl='docker logs -f'
alias dprune='docker system prune -af'
alias dvol='docker volume ls'

# --- Dev tools ---------------------------------------------------------------
if command -v btm &>/dev/null; then
    alias top='btm'
elif command -v htop &>/dev/null; then
    alias top='htop'
fi
command -v ncdu &>/dev/null && alias du='ncdu --color dark'
command -v http &>/dev/null && alias https='http --default-scheme=https'
command -v difft &>/dev/null && alias ddiff='difft'

# tmux-sessionizer — usable outside tmux too (starts a session and attaches)
command -v tmux-sessionizer &>/dev/null && alias ts='tmux-sessionizer'

# mise (runtime version manager)
if command -v mise &>/dev/null; then
    alias mi='mise install'
    alias mu='mise use'
    alias mr='mise run'
fi

# yazi (terminal file manager) — cd's the shell to wherever you exit yazi in
if command -v yazi &>/dev/null; then
    function y() {
        local tmp
        tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
fi

# --- Python ------------------------------------------------------------------
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null || echo "No venv found"'
alias pipreq='pip freeze > requirements.txt'

# uv (fast Python package manager — preferred over pip for new projects)
if command -v uv &>/dev/null; then
    alias uvs='uv sync'
    alias uva='uv add'
    alias uvr='uv run'
    alias uvvenv='uv venv'
    alias uvpi='uv pip install'
fi

# --- Node/JS -----------------------------------------------------------------
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias nrl='npm run lint'

# pnpm (fast npm alternative)
if command -v pnpm &>/dev/null; then
    alias pn='pnpm'
    alias pni='pnpm install'
    alias pnr='pnpm run'
    alias pnd='pnpm run dev'
    alias pnb='pnpm run build'
    alias pnt='pnpm run test'
fi

# bun (JS runtime & package manager)
if command -v bun &>/dev/null; then
    alias bi='bun install'
    alias br='bun run'
    alias bd='bun run dev'
    alias bb='bun run build'
fi

# --- AWS ---------------------------------------------------------------------
if command -v aws &>/dev/null; then
    # Switch AWS profile interactively (requires fzf)
    awsp() {
        local profile
        profile=$(aws configure list-profiles 2>/dev/null | fzf --prompt="AWS Profile > " --height=40%) || return 1
        export AWS_PROFILE="$profile"
        echo "AWS_PROFILE set to: $AWS_PROFILE"
    }
    alias awsl='aws sso login'
    alias awsw='aws sts get-caller-identity'
    alias awsregion='echo "${AWS_DEFAULT_REGION:-not set}"'
    alias awsprofile='echo "${AWS_PROFILE:-default}"'
    alias awsls='aws configure list-profiles'
    alias awsec2='aws ec2 describe-instances --output table'
    alias awss3='aws s3 ls'
    alias awslogs='aws logs tail --follow'
fi

# --- Kubernetes --------------------------------------------------------------
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgpa='kubectl get pods -A'
    alias kgs='kubectl get services'
    alias kgn='kubectl get nodes'
    alias kgd='kubectl get deployments'
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'
    alias kdp='kubectl describe pod'
    alias kl='kubectl logs -f'
    alias kex='kubectl exec -it'
    alias kctx='kubectl config use-context'
    alias kns='kubectl config set-context --current --namespace'
    alias kctxls='kubectl config get-contexts'
fi
command -v k9s &>/dev/null && alias k9='k9s'

# --- Network & debugging -----------------------------------------------------
alias myip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk "{print \$1}"'
alias ports='lsof -i -P -n | command grep LISTEN'
alias ping='ping -c 5'
alias headers='curl -I'
alias flush='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder 2>/dev/null; echo "DNS flushed"'

# --- File operations ---------------------------------------------------------
alias mkdir='mkdir -pv'
alias md='mkdir -pv'
alias rd='rmdir'
alias sizeof='du -sh'
alias count='find . -type f | wc -l'
alias ext='find . -type f | sed "s/.*\.//" | sort | uniq -c | sort -rn | head -20'

# --- Common utilities --------------------------------------------------------
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'
alias cls='clear'
alias c='clear'
alias h='history'
alias hg='history | command grep'
alias j='jobs -l'
alias weather='curl -s "wttr.in?format=3"'
alias week='date +%V'
alias timestamp='date +%s'
alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))"'
alias json='jq .'
alias uuid='python3 -c "import uuid; print(uuid.uuid4())"'
alias serve='python3 -m http.server 8000'
alias sha256='shasum -a 256'

# --- Process management ------------------------------------------------------
alias psg='ps aux | command grep -v grep | command grep'
alias killport='kill -9 $(lsof -t -i)'  # usage: killport :3000
alias memhogs='ps aux | sort -rk 4 | head -10'
alias cpuhogs='ps aux | sort -rk 3 | head -10'

# --- Tar/compression --------------------------------------------------------
alias targz='tar -czvf'
alias untargz='tar -xzvf'
alias tarls='tar -tzvf'

# --- Safety nets -------------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Clipboard (cross-platform) ---------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
    alias clip='pbcopy'
    alias paste='pbpaste'
elif command -v xclip &>/dev/null; then
    alias clip='xclip -selection clipboard'
    alias paste='xclip -selection clipboard -o'
fi

# --- Quick edit configs ------------------------------------------------------
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias gitconf='${EDITOR:-nvim} ~/.gitconfig'
alias aliases='${EDITOR:-nvim} ${DOTFILES_DIR:-~/dotfiles}/zsh/aliases.zsh && reload'
alias tmuxconf='${EDITOR:-nvim} ~/.tmux.conf'
alias vimrc='${EDITOR:-nvim} ~/.config/nvim/init.lua'
