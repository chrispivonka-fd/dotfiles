# Modern CLI Mastery Guide

This guide covers the "bleeding edge" tools included in these dotfiles and how to use them to supercharge your productivity.

---

## 1. Environment & Tools Management

### Mise (`mise`)
The modern replacement for `asdf`, `nvm`, `pyenv`, etc. It's written in Rust and is incredibly fast.
- **Install a language:** `mise use node@20` or `mise use python@3.11`
- **Global versions:** `mise use -g node@latest`
- **One-off execution:** `mise x node@18 -- node app.js`
- **Config:** Managed via `.mise.toml` in your project or `~/.config/mise/config.toml`.

### Direnv (`direnv`)
Automatically loads and unloads environment variables depending on your current directory.
- **Setup:** Create a `.envrc` file in any directory.
- **Allow:** Run `direnv allow` to authorize the directory.
- **Usage:** Put `export API_KEY=secret` in `.envrc`. It will be available when you `cd` in and disappear when you `cd` out.

### Just (`just`)
A modern command runner (replacement for `make`).
- **Setup:** Create a `justfile` in your project.
- **Run:** `j build` or `just test`.
- **List:** `j` or `just` lists all available recipes with descriptions.

---

## 2. Navigation & File Management

### Zoxide (`z`)
A smarter `cd` command. It remembers which directories you use most frequently.
- **Jump:** `z myproj` (jumps to the best match for "myproj").
- **Interactive:** `zi` (opens an fzf menu of your frequent directories).

### Yazi (`y`)
A blazing fast terminal file manager.
- **Open:** Type `y`.
- **Navigate:** Use `hjkl` or arrow keys.
- **Select:** `Space` to toggle selection.
- **Exit with CWD:** When you exit Yazi, your shell will `cd` to the last directory you were in inside Yazi.

### Eza (`ls`)
A modern `ls` with icons and git integration.
- **Icons:** Enabled by default in our aliases (`ls`, `ll`).
- **Git Status:** Shown in the `ll` alias.
- **Tree View:** `lt` (2 levels) or `lt3` (3 levels).

---

## 3. Search & Editing

### Ripgrep (`rg`)
The fastest way to search for text in files.
- **Basic:** `rg pattern`
- **Case-insensitive:** `rg -i pattern`
- **File types:** `rg -t py pattern` (search only Python files).
- **Config:** Customized via `~/.ripgreprc` (already symlinked).

### FZF (Fuzzy Finder)
- **History:** `Ctrl+R` (search through your command history).
- **Files:** `Ctrl+T` (fuzzy find a file and insert it into your command).
- **Dirs:** `Alt+C` (fuzzy find a directory and `cd` into it).
- **Tab Completion:** Type `cd **[TAB]` or `vim **[TAB]` to use fzf for completion.

### FZF-Tab
Our Zsh setup uses `fzf-tab`, which means **regular tab completion** now uses fzf.
- **Usage:** Type `cd [TAB]` and use arrow keys or fuzzy search to pick a directory. It even shows previews!

---

## 4. Git Workflow

### Lazygit (`lg`)
A beautiful terminal UI for git.
- **Open:** Type `lg`.
- **Status:** View staged/unstaged changes.
- **Committing:** `c` to commit, `A` to amend.
- **Push/Pull:** `P` and `p`.

### Delta (`diff`)
A syntax-highlighting pager for git.
- **Side-by-Side:** Enabled by default in our `.gitconfig`.
- **Line Numbers:** Enabled by default.

---

## 5. System Monitoring

### Bottom (`btm` / `top`)
A modern, graphical system monitor.
- **Open:** Type `top` (aliased to `btm`).
- **Basics:** `btm --basic` for a cleaner look (aliased to `btm`).
- **Navigation:** Use the mouse or keyboard to switch between CPU, Mem, Process views.

### Lazydocker (`ld`)
A terminal UI for Docker.
- **Open:** Type `ld`.
- **Manage:** Easily view logs, restart containers, and clean up images/volumes.

---

## 6. Neovim (The Editor)
Our config uses `Lazy.nvim` as the plugin manager and `Mason` for LSP/Tool management.
- **Leader Key:** `Space`
- **Files:** `<leader>ff`
- **Search:** `<leader>fg` (Live Grep)
- **Explorer:** `<leader>e`
- **LSP:** `gd` (Definition), `K` (Hover), `<leader>ca` (Code Action).

---

## 8. Language Workflows

### 🦀 Rust
- **Editor:** `rust-analyzer` is fully configured with `clippy` on save and inlay hints.
- **CLI Aliases:**
  - `c` -> `cargo`
  - `cn` -> `cargo nextest run` (modern, fast test runner)
  - `cw` -> `cargo watch`
  - `cl` -> `cargo clippy`
- **Formatting:** `rustfmt` runs automatically on save via `conform.nvim`.

### 🐹 Go
- **Editor:** `gopls` configured with `staticcheck` and `gofumpt`.
- **CLI Aliases:**
  - `g` -> `go`
  - `gt` -> `go test ./...`
  - `gmt` -> `go mod tidy`
- **Linting:** `golangci-lint` is installed and ready for CI or local use.

### 🐍 Python
- **Editor:** `basedpyright` for fast type checking and `ruff` for everything else.
- **CLI Aliases:**
  - `r` -> `ruff`
  - `rf` -> `ruff format`
  - `ra` -> `ruff check --fix`
- **Formatting:** `ruff` handles both linting and formatting instantly.

### 📦 Node & TypeScript
- **Editor:** `vtsls` (faster version of `tsserver`) with full inlay hints for types and parameters.
- **CLI Aliases:**
  - `p` -> `pnpm` (our preferred fast package manager)
  - `tsc` -> `npx tsc`
- **Formatting:** `prettier` or `prettierd` runs on save for all JS/TS/JSON/YAML/MD files.

---

## 10. AI Power Tools

### Claude Code (`claude`)
Anthropic's official CLI for high-performance engineering tasks.
- **Usage:** Run `claude` in any project to start an agentic session.
- **Features:** It can read files, run tests, and execute commands to solve complex tasks.

### Gemini CLI (`gemini`)
Google's interactive CLI for AI-assisted development (the tool you are using now!).
- **Usage:** Run `gemini` to start an interactive session.
- **Features:** Supports codebase awareness, tool usage, and seamless integration with Google's latest models.

### Mods (`ai`)
Perfect for piping AI results into other commands or files.
- **Usage:** `ls | ai "Which of these files are source code?"`
- **Formatting:** `cat data.json | ai "summarize this" --format markdown`

---

## 11. Cloud Infrastructure

### AWS
- **CLI:** `aws` (AWS CLI v2)
- **Vault:** `aws-vault` (Secure credential management)
- **Aliases:**
  - `awsl <profile>` -> `aws-vault exec <profile>`
  - `aws-who` -> Check current identity
  - `s3ls` -> List S3 buckets

### Google Cloud (GCP)
- **CLI:** `gcloud` (Google Cloud SDK)
- **Aliases:**
  - `gcpl` -> Auth login
  - `gcpp <id>` -> Set active project
  - `gcp-who` -> Check current account

> **Note:** Add your API keys to `~/.zshrc.local` to enable these tools.
