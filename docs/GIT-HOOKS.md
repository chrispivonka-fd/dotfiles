# Git hooks

The installer links `git/hooks/` to `~/.githooks`, and the shared Git config
sets `core.hooksPath` to that directory. These hooks therefore apply to every
repository using the global configuration.

## Commit messages

Normal commit headers must follow this form:

```text
type(optional-scope): concise description
```

Breaking changes can add `!` before the colon:

```text
feat(api)!: remove the legacy endpoint
```

Allowed types:

| Type | Use it for |
| --- | --- |
| `build` | Build system or external dependency changes |
| `chore` | Maintenance that does not change product behavior |
| `ci` | CI/CD configuration and scripts |
| `docs` | Documentation-only changes |
| `feat` | New user-visible or API behavior |
| `fix` | A defect correction |
| `perf` | A measurable performance improvement |
| `refactor` | Internal restructuring without a feature or fix |
| `revert` | Reverting a previous change |
| `style` | Formatting-only changes with no behavioral effect |
| `test` | Tests or test infrastructure only |

Choose the type and scope that truthfully describe the staged change. The hook
can validate structure, but it cannot determine semantic accuracy for you.
Headers are limited to 100 characters, and a body must be separated from the
header by a blank line. Git-generated merge, revert, `fixup!`, `squash!`, and
`amend!` messages remain supported. Jira issue prefixes are not added.

Use `gcm` so a message is always explicit:

```sh
gcm "fix(auth): reject expired sessions"
```

## Checks

| Hook | Behavior |
| --- | --- |
| `pre-commit` | Scans staged content with Gitleaks; blocks files over 5 MiB, credential-shaped filenames, whitespace errors, and conflict markers |
| `commit-msg` | Enforces Conventional Commits and rejects recognizable secrets or 1Password references in messages |
| `pre-push` | Blocks deletion or history rewrites of `main`/`master` and scans outgoing commits with Gitleaks |
| `post-merge` | Prints focused restore/install reminders when ecosystem manifests or lockfiles changed |

`--no-verify` remains Git's emergency escape hatch. Use it only after reviewing
a known false positive; it intentionally bypasses shared checks.

## Private extensions

Optional executable hooks under `~/.config/dotfiles/hooks.local/` run after the
matching shared hook. Supported names are `pre-commit`, `commit-msg`,
`pre-push`, and `post-merge`. Arguments are forwarded unchanged, and the local
`pre-push` receives the same ref-update input as the shared hook.

These files are local and ignored, so they can contain company-specific checks
without exposing internal details in the public repository.

## Test the hooks

Run the self-contained test suite after changing hook behavior:

```sh
./scripts/test-git-hooks.sh
```
