#!/usr/bin/env bash

hook_info() { printf '  [dotfiles] %s\n' "$1"; }
hook_warn() { printf 'warning: %s\n' "$1" >&2; }
hook_error() { printf 'error: %s\n' "$1" >&2; }

run_local_hook() {
    local hook_name="$1"
    shift

    local local_dir="${DOTFILES_LOCAL_HOOK_DIR:-$HOME/.config/dotfiles/hooks.local}"
    local local_hook="$local_dir/$hook_name"
    if [ -x "$local_hook" ]; then
        "$local_hook" "$@"
    fi
}
