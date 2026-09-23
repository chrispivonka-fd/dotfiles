# Load the local 1Password Environment into every interactive zsh process.
# 1Password exposes the Environment as a mode-0600 FIFO at ~/.env, so resolved
# values are never stored in this repository or as plaintext on disk.

_dotfiles_load_onepassword_environment() {
  # Use predictable zsh semantics and disable inherited xtrace while values are
  # in memory so they cannot be written to a shell trace by accident.
  emulate -L zsh

  local -a names=(
    ANTHROPIC_AUTH_TOKEN
    ANTHROPIC_BASE_URL
    AWS_DEFAULT_REGION
    GITHUB_PERSONAL_ACCESS_TOKEN
    JIRA_API_TOKEN
    MDB_MCP_CONNECTION_STRING
    OPENAI_API_KEY
  )
  local name

  # Fail closed. This also prevents an inherited stale value from making a
  # missing 1Password entry look successful in a nested shell. Checking the
  # attributes first avoids zsh's fatal error when unsetting a readonly value.
  for name in "${names[@]}"; do
    if [[ "${(tP)name}" == *readonly* ]]; then
      print -u2 -- "1Password: cannot replace readonly variable $name"
      return 1
    fi
  done
  unset "${names[@]}"

  local environment_file="$HOME/.env"
  if [[ ! -p "$environment_file" || ! -O "$environment_file" ]]; then
    print -u2 -- "1Password: mounted local environment is unavailable at ~/.env"
    return 1
  fi

  if (( ! $+commands[op] )); then
    print -u2 -- "1Password: CLI is unavailable"
    return 1
  fi

  # The mounted Environment does not support simultaneous readers. Serialize
  # Warp tabs with an empty, non-secret lock file in macOS's per-user temp dir.
  local lock_directory="${TMPDIR:-/tmp}"
  local lock_file="${lock_directory%/}/dotfiles-1password-environment-${EUID}.lock"
  if ! (umask 077; : >> "$lock_file"); then
    print -u2 -- "1Password: could not create the environment lock"
    return 1
  fi

  if ! zmodload zsh/system 2>/dev/null; then
    print -u2 -- "1Password: zsh locking support is unavailable"
    return 1
  fi

  local lock_fd=''
  {
    if ! zsystem flock -t 30 -i 0.1 -f lock_fd "$lock_file"; then
      print -u2 -- "1Password: timed out waiting to load the local environment"
      return 1
    fi

    # Buffer the NUL-delimited protocol and apply nothing unless op completed
    # successfully with exactly one non-empty value for every expected name.
    local -A seen
    local -a pending
    local record key op_status=''
    local -i protocol_ok=1
    local -i allowed

    while IFS= read -r -d $'\0' record; do
      if [[ "$record" == __OP_STATUS__=<-> ]]; then
        [[ -z "$op_status" ]] || protocol_ok=0
        op_status="${record#*=}"
        continue
      fi

      if [[ "$record" != *=* ]]; then
        protocol_ok=0
        continue
      fi

      key="${record%%=*}"
      allowed=0
      for name in "${names[@]}"; do
        if [[ "$key" == "$name" ]]; then
          allowed=1
          break
        fi
      done

      if (( ! allowed )); then
        protocol_ok=0
        continue
      fi

      if (( ${+seen[$key]} )) || [[ -z "${record#*=}" ]]; then
        protocol_ok=0
        continue
      fi

      seen[$key]=1
      pending+=("$record")
    done < <(
      command op run \
        --no-masking \
        --env-file="$environment_file" \
        -- /bin/zsh -fc '
          for name in "$@"; do
            value="${(P)name}"
            [[ -n "$value" ]] || exit 64
            printf "%s\0" "$name=$value"
          done
        ' onepassword-environment-loader "${names[@]}" 2>/dev/null
      printf '%s\0' "__OP_STATUS__=$?"
    )

    if (( protocol_ok )) && [[ "$op_status" == 0 ]] &&
       (( ${#pending} == ${#names} )); then
      for record in "${pending[@]}"; do
        export "$record"
      done
    else
      print -u2 -- "1Password: local environment is incomplete or unavailable"
      return 1
    fi
  } always {
    if [[ -n "$lock_fd" ]]; then
      zsystem flock -u "$lock_fd" 2>/dev/null || true
    fi
  }
}

_dotfiles_load_onepassword_environment
unset -f _dotfiles_load_onepassword_environment
