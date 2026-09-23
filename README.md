# Work dotfiles

Public, macOS-only dotfiles for a work development machine. This fork shares
its roots with the personal dotfiles but is free to diverge where enterprise
requirements differ—most notably, it uses Colima instead of OrbStack.

The repository contains only portable configuration, placeholders, and tool
manifests. Internal hostnames, account names, project paths, private package
feeds, AWS profiles, credentials, and real 1Password references belong in
ignored local files.

## Bootstrap

Review the proposed changes first:

```sh
git clone git@github.com:chrispivonka-fd/dotfiles_.git ~/GitHub/dotfiles_
cd ~/GitHub/dotfiles_
./install.sh --dry-run
```

Then apply them:

```sh
./install.sh
exec zsh
```

Useful installer options:

```text
--dry-run    print changes without applying them
--skip-apps  skip Homebrew casks and Mac App Store apps
--no-update  skip brew update
```

Existing managed files are moved to a timestamped directory under
`~/.dotfiles-backups/` before symlinks are created. The installer is intended
to be safe to rerun. It does not start Colima or change Terminal.app/Warp
defaults automatically.

## Public versus local configuration

The installer creates these ignored files from sanitized examples when they
do not already exist:

| Local file | Purpose |
| --- | --- |
| `~/.zshrc.local` | Private paths, aliases, profile names, and environment setup |
| `~/.gitconfig.local` | Work identity and SSH signing public key |
| `~/.ssh/config.local` | Internal SSH hosts and connection details |
| `~/.tmux.conf.local` | Machine-specific tmux overrides |
| `~/.config/dotfiles/secrets.env` | 1Password references, never secret values |
| `~/.config/dotfiles/hooks.local/` | Private, optional hook extensions |

Long-lived secrets and SSH private keys belong in 1Password. A local secrets
file should contain references such as `op://VAULT/ITEM/FIELD`, not resolved
values. Inject them only into the process that needs them:

```sh
op run --env-file="$HOME/.config/dotfiles/secrets.env" -- your-command
```

AWS profiles and provider-native sessions remain local. This repository does
not render or track `~/.aws/config` or `~/.aws/credentials`.

## Tool ownership

Each package has one owner to avoid duplicate installations:

- Homebrew formulae: stable macOS command-line applications such as Colima,
  Docker CLI, Git, shell tools, database clients, linters, and scanners.
- Homebrew casks: GUI applications and vendor-native macOS tools.
- Mise: language runtimes, package managers, and portable developer CLIs,
  including the Tree-sitter CLI used to build Neovim parsers.
- Mac App Store: Xcode.
- Project repositories: project-specific runtime pins and tools such as
  CSharpier in a .NET tool manifest.

The declarative lists live under `packages/`; global runtime policy lives in
`mise/config.toml`.

## How to use Mise

Mise supplies the latest global fallback versions for interactive work. A
project's explicit version must win whenever the project has a requirement.

Typical workflow inside a project:

```sh
# Pin a runtime in the current repository and update its mise.toml.
mise use node@26
mise use python@3.15

# Terraform should match the version required by the remote workspace.
mise use terraform@1.14.0

# Install everything selected by global and project configuration.
mise install

# See which config selected each active version.
mise current

# Run with Mise's environment without relying on shell activation.
mise exec -- terraform version
```

Global `latest` selectors are resolved through the committed Mise lockfile so
a normal install is repeatable. Refreshing that lockfile is the deliberate
upgrade step. Project `mise.toml` files should be committed to their own
repositories. Idiomatic files such as `.nvmrc`, `.python-version`, and
`.terraform-version` are also honored when present. The global policy waits
seven days before adopting newly released versions.

## Containers and databases

Colima provides the local container runtime:

```sh
colima start
docker version
colima stop
```

This repository intentionally has no active root devcontainer. Reusable
templates live under `templates/devcontainers/`:

- `base/` provides .NET 10, Node 26, Python 3.15, Terraform, AWS CLI, and
  GitHub CLI.
- `databases/compose.yaml` provides opt-in PostgreSQL, MongoDB, and Redis bound
  to localhost with disposable local credentials.

Copy only the pieces a project needs, then pin that project's versions.

## Daily entry points

- `gcm "type(scope): summary"` commits with an explicit message; the global Git
  hooks run shared safety checks.
- `lg` opens Lazygit and `ld` opens Lazydocker.
- `ts` opens the tmux project sessionizer.
- `Ctrl-R` uses Atuin's local-only searchable shell history.
- `awsp` selects an already-local AWS profile.
- `leakscan` scans the current working tree with Gitleaks.
- SQLFluff defaults to PostgreSQL; SQL Server projects should override the
  dialect to `tsql` in their project-local `.sqlfluff`.

Global hooks require accurate Conventional Commit headers and run staged-file,
secret, whitespace, large-file, and protected-branch checks. See
[`docs/GIT-HOOKS.md`](docs/GIT-HOOKS.md) for types, examples, local extensions,
and the test command.

Starship is the prompt; Zinit manages Zsh plugins. They serve different roles
and are intentionally used together.

Claude Code receives a deliberately small set of specialized work agents for
AWS, Terraform, containers, .NET, TypeScript/React/Next.js, Python, Go, Rust,
PostgreSQL, and MongoDB. The installer links only these public, provider-safe
prompts into `~/.claude/agents`.

## Terminal appearance

The GitHub Dark Terminal.app profile remains in `terminal/` as an optional
asset. Import it manually if desired. Choose a Nerd Font manually in Warp.
The installer never changes either terminal's defaults.
