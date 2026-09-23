# Devcontainer templates

These are opt-in project templates; this repository does not activate a
devcontainer for itself.

- Copy `base/.devcontainer` into a project for the standard work toolchain.
- Copy `databases/compose.yaml` into a project when PostgreSQL, MongoDB, or
  Redis is useful for local development.
- Pin Terraform in the project's `mise.toml` to the version required by that
  project's remote workspace rather than relying on the global fallback.

The database credentials are deliberately local-only placeholders. Bindings
are limited to localhost and must not be reused in shared environments.
