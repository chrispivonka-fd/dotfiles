# dotfiles

Modern developer environment configuration for macOS and Ubuntu/Debian.

## Install

```bash
git clone https://github.com/YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

**New to these tools?** Check out the [Modern CLI Mastery Guide](GUIDE.md) for tips and shortcuts!

## The install script:
1. Detects your OS (macOS or Ubuntu/Debian)
2. Installs all tools via Homebrew or apt
3. Installs Nerd Fonts (MesloLGS, JetBrains Mono, Fira Code)
4. Extracts your existing git identity to `~/.gitconfig.local`
5. Backs up existing dotfiles to `~/.dotfiles_backup/`
6. Creates symlinks from `~` to the repo, including global git hooks and the `tmux-sessionizer` script
7. Installs zinit (zsh plugins), TPM (tmux plugins), and lazy.nvim (neovim plugins)

Safe to run multiple times (idempotent).

> **iTerm2 font setup:** Go to Settings > Profiles > Text > Font and select "MesloLGS Nerd Font" for icons to render.

---

## What's Included

| Config | Description |
|--------|-------------|
| **zsh** | zinit, autosuggestions, syntax highlighting, fzf-tab fuzzy completion, atuin history, mise runtimes |
| **git** | Delta pager (GitHub Dark), useful aliases, histogram diffs, auto-rebase, rerere, SSH commit signing via 1Password, global hooks (secret/large-file/conflict-marker/whitespace guards, force-push protection) |
| **starship** | Fast prompt with GitHub Dark theme, git status, language versions |
| **tmux** | Mouse, true color, vim keys, TPM, session persistence, fuzzy project sessionizer, GitHub Dark status bar |
| **neovim** | lazy.nvim, LSP, telescope, treesitter, github-theme (GitHub Dark) |
| **bat** | GitHub Dark theme, line numbers + change markers |
| **lazygit** | GitHub Dark theme, delta as the diff pager |
| **editorconfig** | Consistent formatting across editors |
| **ripgrep** | Smart defaults for code search |

Every themed tool (starship, neovim, bat, delta, fzf, lazygit, tmux, eza) uses the same **GitHub Dark** palette for a consistent look end to end.

## Tools Installed

### Modern CLI Replacements

| Classic | Modern | Purpose |
|---------|--------|---------|
| `ls` | [eza](https://github.com/eza-community/eza) | File listing with icons, git status, GitHub Dark colors |
| `cat` | [bat](https://github.com/sharkdp/bat) | Syntax-highlighted file viewing |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast recursive code search |
| `find` | [fd](https://github.com/sharkdp/fd) | Fast, user-friendly file finding |
| `cd` | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart directory jumping (learns your habits) |
| `diff` | [delta](https://github.com/dandavison/delta) | Beautiful side-by-side git diffs |
| `top` | [htop](https://github.com/htop-dev/htop) | Interactive process viewer |
| `du` | [ncdu](https://dev.yorhel.nl/ncdu) | Interactive disk usage analyzer |
| `curl` | [httpie](https://httpie.io/) | Human-friendly HTTP client |

### Dev & Productivity Tools

| Tool | Purpose | Quick Example |
|------|---------|---------------|
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for everything | `Ctrl+R` to search history |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git | `lg` to launch |
| [starship](https://starship.rs/) | Cross-shell prompt | Automatic -- shows git, languages |
| [jq](https://jqlang.github.io/jq/) | JSON processor | `curl api \| jq '.data'` |
| [yq](https://github.com/mikefarah/yq) | YAML/TOML processor | `yq '.key' file.yaml` |
| [tldr](https://tldr.sh/) | Simplified man pages | `tldr tar` |
| [tree](https://linux.die.net/man/1/tree) | Directory tree view | `tree -L 2` |
| [shellcheck](https://www.shellcheck.net/) | Shell script linter | `shellcheck script.sh` |
| [tokei](https://github.com/XAMPPRocky/tokei) | Code statistics | `tokei` in any repo |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Command benchmarking | `hyperfine 'cmd1' 'cmd2'` |
| [difftastic](https://difftastic.wilfred.me.uk/) | Syntax-aware structural diffs | `difft file1 file2` |
| [gh](https://cli.github.com/) | GitHub CLI | `gh pr create` |
| [atuin](https://atuin.sh/) | Searchable shell history (SQLite, local-only) | `Ctrl+R` fuzzy history search |
| [mise](https://mise.jdx.dev/) | Per-project runtime version manager | `mise use node@22` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanner, wired into global pre-commit + pre-push hooks | Blocks commits/pushes containing keys/tokens |
| [1Password CLI](https://developer.1password.com/docs/cli/) | SSH agent + secrets from the terminal | `op signin` |
| [yazi](https://github.com/sxyazi/yazi) | Terminal file manager with image previews | `y` (cd's your shell to wherever you exit) |
| [television](https://github.com/alexpasmantier/television) | Fast fuzzy finder — installed but not wired into aliases; fzf already covers this and is more stable for ad-hoc piping | `tv files` |
| [bottom](https://github.com/ClementTsang/bottom) | Modern graphing process viewer | `top` (aliased, replaces htop) |

---

## Cheatsheets

### Shell Aliases

#### File Listing (eza)
```
ls        File list with icons
ll        Long list with git status
la        All files including hidden
lt        Tree view (2 levels)
lt3       Tree view (3 levels)
lS        Sort by size (largest first)
lm        Sort by modified date
```

#### Git
```
gs        git status
gss       git status -s (short)
ga        git add
gaa       git add --all
gap       git add -p (interactive)
gc        git commit
gcm MSG   git commit -m MSG
gca       git commit --amend
gcan      git commit --amend --no-edit
gd        git diff
gds       git diff --staged
gdw       git diff --word-diff
gl        git log (short, graph, 20 lines)
gla       git log --all
glp       git log (pretty, with author + date)
gp        git push
gpf       git push --force-with-lease
gpl       git pull
gplr      git pull --rebase
gb        git branch
gba       git branch -a (all)
gbd       git branch -d (delete)
gco       git checkout
gcb       git checkout -b (new branch)
gsw       git switch
gswc      git switch -c (new branch)
gst       git stash
gstp      git stash pop
gstl      git stash list
gf        git fetch --all --prune
grb       git rebase
grbi      git rebase -i
grbc      git rebase --continue
grba      git rebase --abort
gcp       git cherry-pick
gbl       git blame
gwip      Stage all + commit "WIP"
gunwip    Undo last WIP commit
gtags     List tags (newest first)
gclean    Remove untracked files
lg        lazygit
ghpr      gh pr create
ghprv     gh pr view --web
ghprs     gh pr status
ghis      gh issue list
leakscan  Manually scan the working tree for secrets (gitleaks)
```

#### Git Hooks

Global (`core.hooksPath = ~/.githooks`), so they apply to **every repo** on this machine, not just this one. Every check can be skipped for a single command with `--no-verify` if it's a false positive.

| Hook | What it blocks |
|------|-----------------|
| `pre-commit` | Secrets (gitleaks), files over 5MB, credential-shaped filenames (`.env`, `*.pem`, `id_rsa`, ...), unresolved merge-conflict markers, trailing whitespace |
| `commit-msg` | Obvious secrets/tokens pasted into the commit message itself |
| `pre-push` | Force-pushes that rewrite `main`/`master`, secrets in outgoing commits |
| `post-merge` | Nothing — just reminds you to reinstall deps when a manifest (`package.json`, `Gemfile.lock`, etc.) changed in the pull |

#### Docker
```
d         docker
dc        docker compose
dcu       docker compose up -d
dcd       docker compose down
dcr       docker compose restart
dcl       docker compose logs -f
dcb       docker compose build
dps       docker ps
dpsa      docker ps -a
di        docker images
dex       docker exec -it
dl        docker logs -f
dprune    docker system prune -af
dvol      docker volume ls
```

#### Python
```
py        python3
pip       pip3
venv      python3 -m venv
activate  Source .venv or venv activate
pipreq    pip freeze > requirements.txt
```

#### Node/JS
```
ni        npm install
nr        npm run
nrd       npm run dev
nrb       npm run build
nrt       npm run test
nrl       npm run lint
```

#### Networking
```
myip      Public IP address
localip   Local/LAN IP address
ports     Show listening ports
ping      Ping (5 packets)
headers   Fetch HTTP headers
flush     Flush DNS cache (macOS)
```

#### Utilities
```
path      Print $PATH one per line
reload    Reload .zshrc
cls / c   Clear terminal
h         History
hg TERM   Search history for TERM
j         List background jobs
weather   Current weather
week      Current week number
timestamp Unix timestamp
uuid      Generate a UUID
json      Pretty-print JSON (pipe into it)
serve     Start HTTP server on :8000
sha256    SHA-256 checksum
sizeof    Size of file/directory
count     Count files in current dir
ext       File extension statistics
urlencode Encode a URL string
urldecode Decode a URL string
clip      Copy to clipboard
paste     Paste from clipboard
```

#### Process Management
```
psg TERM  Search running processes
memhogs   Top 10 memory consumers
cpuhogs   Top 10 CPU consumers
```

#### Compression
```
targz     Create .tar.gz archive
untargz   Extract .tar.gz archive
tarls     List .tar.gz contents
```

#### Config Editing
```
zshrc     Edit ~/.zshrc
gitconf   Edit ~/.gitconfig
aliases   Edit aliases.zsh + auto-reload
tmuxconf  Edit ~/.tmux.conf
vimrc     Edit nvim config
```

#### Safety
```
rm        Prompts before delete (rm -i)
cp        Prompts before overwrite (cp -i)
mv        Prompts before overwrite (mv -i)
```

---

### FZF (Fuzzy Finder)

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | Search files (insert path) |
| `Alt+C` | Search directories (cd into it) |
| `**<Tab>` | Fuzzy completion (e.g., `vim **<Tab>`) |
| `<Tab>` | fzf-tab fuzzy menu for any completion (cd, kill, git checkout, etc.) |

---

### Atuin (Shell History)

Local-only — sync and update checks are disabled in `~/.config/atuin/config.toml`. Never run `atuin register`/`atuin login` on this machine or history starts leaving it.

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Fuzzy search history (atuin) |
| `↑` / `↓` | Normal zsh history search (unchanged, atuin doesn't take over the arrow keys) |

---

### Mise (Runtime Versions)

| Command | Action |
|---------|--------|
| `mu node@22` (`mise use`) | Pin Node 22 for the current project (writes `mise.toml`) |
| `mi` (`mise install`) | Install versions pinned in `mise.toml`/`.tool-versions` |
| `mr <task>` (`mise run`) | Run a task defined in `mise.toml` |
| `mise ls` | List installed runtime versions |
| `mise doctor` | Diagnose activation/shims issues |

---

### Zoxide (Smart cd)

| Command | Action |
|---------|--------|
| `z foo` | Jump to most-used dir matching "foo" |
| `z foo bar` | Jump to dir matching "foo" and "bar" |
| `zi` | Interactive selection with fzf |
| `z -` | Go back to previous directory |

---

### Tmux (prefix = Ctrl-a)

#### Sessions
| Key | Action |
|-----|--------|
| `tmux` | Start new session |
| `tmux new -s name` | Named session |
| `tmux ls` | List sessions |
| `tmux a -t name` | Attach to session |
| `prefix + d` | Detach |
| `prefix + $` | Rename session |
| `prefix + f` | Fuzzy-jump between `~/GitHub` projects (creates/switches session via `tmux-sessionizer`; override the search paths with `TMUX_SESSIONIZER_PATHS="~/GitHub ~/work"`) |
| `ts` (shell alias) | Same sessionizer, usable from outside tmux too — starts/attaches a session |

#### Windows
| Key | Action |
|-----|--------|
| `prefix + c` | New window |
| `prefix + ,` | Rename window |
| `prefix + n/p` | Next/prev window |
| `prefix + 0-9` | Switch to window # |
| `prefix + &` | Close window |

#### Panes
| Key | Action |
|-----|--------|
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + z` | Toggle pane zoom |
| `prefix + x` | Close pane |

#### Copy Mode (vi keys)
| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy selection |
| `q` | Exit copy mode |

#### Plugins
| Key | Action |
|-----|--------|
| `prefix + I` | Install plugins (TPM) |
| `prefix + U` | Update plugins |
| `prefix + Ctrl-s` | Save session (resurrect) |
| `prefix + Ctrl-r` | Restore session (resurrect) |

---

### Neovim (leader = Space)

#### Navigation
| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Move between splits |
| `Shift+h / Shift+l` | Prev/next buffer |
| `<leader>bd` | Delete buffer |
| `<leader>e` | Toggle file explorer |
| `<leader>E` | Reveal current file in explorer |

#### Finding (Telescope)
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search in files) |
| `<leader>fb` | Open buffers |
| `<leader>fh` | Help tags |
| `<leader>fr` | Recent files |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | Git status |
| `<leader>fc` | Git commits |
| `<leader>ft` | Find TODOs |
| `<leader>/` | Search in current buffer |

#### LSP (when attached)
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>D` | Type definition |
| `<leader>ds` | Document symbols |
| `[d` / `]d` | Prev/next diagnostic |
| `<leader>d` | Show diagnostic float |

#### Git (Gitsigns)
| Key | Action |
|-----|--------|
| `]h` / `[h` | Next/prev hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hS` | Stage entire buffer |
| `<leader>hu` | Undo stage hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| `<leader>hd` | Diff this |
| `<leader>tb` | Toggle inline blame |

#### Editing
| Key | Action |
|-----|--------|
| `gcc` | Toggle line comment |
| `gc` (visual) | Toggle block comment |
| `ys{motion}{char}` | Add surround (e.g., `ysiw"`) |
| `ds{char}` | Delete surround |
| `cs{old}{new}` | Change surround |
| `<` / `>` (visual) | Indent (keeps selection) |
| `Alt+j` / `Alt+k` | Move line up/down |
| `Ctrl+Space` | Treesitter incremental select |
| `jk` | Exit insert mode |

#### Text Objects (Treesitter)
| Key | Action |
|-----|--------|
| `af` / `if` | Around/inside function |
| `ac` / `ic` | Around/inside class |
| `aa` / `ia` | Around/inside argument |
| `]f` / `[f` | Next/prev function |
| `]c` / `[c` | Next/prev class |

#### Other
| Key | Action |
|-----|--------|
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>Q` | Force quit all |
| `<leader>a` | Select all |
| `Ctrl+d/u` | Scroll down/up (centered) |
| `Esc` | Clear search highlight |

---

### Tool Quick Reference

#### jq (JSON)
```bash
cat data.json | jq '.'                # Pretty-print
cat data.json | jq '.key'             # Extract key
cat data.json | jq '.items[0]'        # First array element
cat data.json | jq '.items | length'  # Array length
cat data.json | jq '.[] | .name'      # Map over array
curl -s api | jq -r '.data.url'       # Raw output (no quotes)
```

#### yq (YAML)
```bash
yq '.key' file.yaml                   # Extract key
yq '.items[0].name' file.yaml         # Nested access
yq -i '.key = "value"' file.yaml      # Edit in place
yq eval-all 'select(.kind == "Pod")' *.yaml  # Filter
```

#### httpie
```bash
http GET example.com/api              # GET request
http POST example.com/api key=value   # POST JSON
http -f POST example.com form=data    # POST form
http -d example.com/file.zip          # Download
http --headers example.com            # Headers only
```

#### ripgrep (rg)
```bash
rg pattern                            # Search recursively
rg -i pattern                         # Case-insensitive
rg -l pattern                         # Files only (no content)
rg -t py pattern                      # Only Python files
rg -g '*.js' pattern                  # Glob filter
rg --replace 'new' 'old'             # Preview replacements
rg -C 3 pattern                       # 3 lines context
```

#### fd
```bash
fd pattern                            # Find files matching pattern
fd -e py                              # Find by extension
fd -t d                               # Directories only
fd -t f -x chmod 644                  # Execute on results
fd -H pattern                         # Include hidden files
fd pattern /path                      # Search specific path
```

#### hyperfine
```bash
hyperfine 'command1' 'command2'       # Compare two commands
hyperfine --warmup 3 'command'        # With warmup runs
hyperfine -N 'fast command'           # Disable shell wrapping
```

#### tldr
```bash
tldr tar                              # Quick examples for tar
tldr git-rebase                       # Git subcommands use dashes
tldr --update                         # Update local cache
```

---

## Repo Structure

```
dotfiles/
├── install.sh              # Bootstrap + install script (macOS & Linux)
├── bin/
│   ├── tmux-sessionizer    # -> ~/.local/bin/tmux-sessionizer
│   └── op-ssh-sign         # -> ~/.local/bin/op-ssh-sign (portable 1Password signing shim)
├── zsh/
│   ├── .zshrc              # -> ~/.zshrc
│   └── aliases.zsh         # Sourced from .zshrc
├── git/
│   ├── .gitconfig          # -> ~/.gitconfig
│   ├── .gitignore_global   # -> ~/.gitignore_global
│   └── hooks/              # -> ~/.githooks (core.hooksPath, applies to every repo)
│       ├── pre-commit      # gitleaks, large-file guard, secret-filename guard,
│       │                   # conflict-marker guard, whitespace check
│       ├── commit-msg      # blocks obvious secrets/tokens pasted into the message
│       ├── pre-push        # blocks force-push to main/master, gitleaks scan
│       └── post-merge      # reminds you to reinstall deps after a manifest changes
├── starship/
│   └── starship.toml       # -> ~/.config/starship.toml
├── tmux/
│   └── .tmux.conf          # -> ~/.tmux.conf
├── nvim/                   # -> ~/.config/nvim (directory symlink)
│   ├── init.lua
│   └── lua/
│       ├── options.lua
│       ├── keymaps.lua
│       ├── lazy-bootstrap.lua
│       └── plugins/
│           ├── telescope.lua
│           ├── treesitter.lua
│           ├── lsp.lua
│           ├── ui.lua
│           └── editor.lua
├── editorconfig/
│   └── .editorconfig       # -> ~/.editorconfig
└── ripgrep/
    └── .ripgreprc           # -> ~/.ripgreprc
```

## Local Overrides

Personal and machine-specific settings are kept in `.local` files (gitignored):

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Git identity (name, email, signing key, credential helper) |
| `~/.zshrc.local` | Private exports, API keys, custom PATH |
| `~/.tmux.local.conf` | Machine-specific tmux settings |

Created automatically by `install.sh` on first run.
