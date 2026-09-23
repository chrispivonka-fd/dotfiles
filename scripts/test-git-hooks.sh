#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK_DIR="$ROOT_DIR/git/hooks"
TEMP_BASE="${TMPDIR:-/tmp}"
TEST_ROOT="$(mktemp -d "$TEMP_BASE/dotfiles-hook-tests.XXXXXX")"
LOCAL_HOOK_DIR="$TEST_ROOT/local-hooks"
MESSAGE_FILE="$TEST_ROOT/COMMIT_EDITMSG"
failures=0
tests=0

cleanup() {
    case "$TEST_ROOT" in
        "$TEMP_BASE"/dotfiles-hook-tests.*) rm -rf -- "$TEST_ROOT" ;;
        *) printf 'refusing to remove unexpected test path: %s\n' "$TEST_ROOT" >&2 ;;
    esac
}
trap cleanup EXIT

export DOTFILES_LOCAL_HOOK_DIR="$LOCAL_HOOK_DIR"
mkdir -p "$LOCAL_HOOK_DIR"

pass() { printf 'ok %d - %s\n' "$tests" "$1"; }
fail() { printf 'not ok %d - %s\n' "$tests" "$1"; failures=$((failures + 1)); }

expect_message_pass() {
    local label="$1"
    local message="$2"
    tests=$((tests + 1))
    printf '%s\n' "$message" > "$MESSAGE_FILE"
    if "$HOOK_DIR/commit-msg" "$MESSAGE_FILE" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}

expect_message_fail() {
    local label="$1"
    local message="$2"
    tests=$((tests + 1))
    printf '%s\n' "$message" > "$MESSAGE_FILE"
    if "$HOOK_DIR/commit-msg" "$MESSAGE_FILE" >/dev/null 2>&1; then fail "$label"; else pass "$label"; fi
}

expect_command_pass() {
    local label="$1"
    shift
    tests=$((tests + 1))
    if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}

expect_command_fail() {
    local label="$1"
    shift
    tests=$((tests + 1))
    if "$@" >/dev/null 2>&1; then fail "$label"; else pass "$label"; fi
}

expect_message_pass "simple Conventional Commit" "feat: add hook validation"
expect_message_pass "scoped Conventional Commit" "fix(parser): reject empty input"
expect_message_pass "breaking Conventional Commit" "feat(api)!: remove legacy endpoint"
expect_message_pass "body separated by blank line" $'docs: explain hooks\n\nDocument the supported commit types.'
expect_message_pass "Git merge message" "Merge branch 'feature'"
expect_message_pass "Git revert message" 'Revert "feat: experimental change"'
expect_message_pass "autosquash message" "fixup! feat: add hook validation"
expect_message_fail "unknown commit type" "feature: invalid type"
expect_message_fail "missing description" "fix:"
expect_message_fail "uppercase type" "FIX: incorrect case"
expect_message_fail "invalid scope" "feat(Billing): incorrect scope"
expect_message_fail "body without blank separator" $'docs: explain hooks\nBody starts too soon.'
fake_aws_key="AKIA""ABCDEFGHIJKLMNOP"
expect_message_fail "secret in commit message" "fix: rotate $fake_aws_key"

printf '%s\n' '#!/usr/bin/env bash' 'exit 42' > "$LOCAL_HOOK_DIR/commit-msg"
chmod +x "$LOCAL_HOOK_DIR/commit-msg"
expect_message_fail "local commit-msg extension is invoked" "chore: exercise local hook"
rm -f "$LOCAL_HOOK_DIR/commit-msg"

REPO_DIR="$TEST_ROOT/repository"
git init -q -b main "$REPO_DIR"
cd "$REPO_DIR"
git config user.name "Hook Tests"
git config user.email "hooks@example.com"
printf 'baseline\n' > baseline.txt
git add baseline.txt
git -c core.hooksPath=/dev/null commit -q -m "chore: initialize hook tests"
base_sha="$(git rev-parse HEAD)"

printf 'safe change\n' > safe.txt
git add safe.txt
expect_command_pass "safe staged content" "$HOOK_DIR/pre-commit"
git -c core.hooksPath=/dev/null commit -q -m "test: add safe fixture"
tip_sha="$(git rev-parse HEAD)"

printf 'trailing whitespace  \n' > whitespace.txt
git add whitespace.txt
expect_command_fail "trailing whitespace is blocked" "$HOOK_DIR/pre-commit"
git restore -q --staged whitespace.txt
rm -f whitespace.txt

printf 'placeholder=true\n' > .env.example
git add .env.example
expect_command_pass "sanitized environment example is allowed" "$HOOK_DIR/pre-commit"
git restore -q --staged .env.example
rm -f .env.example

printf 'placeholder=true\n' > .env
git add -f .env
expect_command_fail "credential-shaped filename is blocked" "$HOOK_DIR/pre-commit"
git restore -q --staged .env
rm -f .env

printf '<<<<<<< ours\n=======\n>>>>>>> theirs\n' > conflict.txt
git add conflict.txt
expect_command_fail "conflict markers are blocked" "$HOOK_DIR/pre-commit"
git restore -q --staged conflict.txt
rm -f conflict.txt

dd if=/dev/zero of=large.bin bs=1048576 count=6 2>/dev/null
git add large.bin
expect_command_fail "files larger than 5 MiB are blocked" "$HOOK_DIR/pre-commit"
git restore -q --staged large.bin
rm -f large.bin

expect_push_pass() {
    local label="$1"
    local update="$2"
    tests=$((tests + 1))
    if printf '%s\n' "$update" | "$HOOK_DIR/pre-push" origin test >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}

expect_push_fail() {
    local label="$1"
    local update="$2"
    tests=$((tests + 1))
    if printf '%s\n' "$update" | "$HOOK_DIR/pre-push" origin test >/dev/null 2>&1; then fail "$label"; else pass "$label"; fi
}

zero="0000000000000000000000000000000000000000"
expect_push_pass "fast-forward push to main" "refs/heads/main $tip_sha refs/heads/main $base_sha"
expect_push_fail "history rewrite of main is blocked" "refs/heads/main $base_sha refs/heads/main $tip_sha"
expect_push_fail "deletion of main is blocked" "(delete) $zero refs/heads/main $tip_sha"

# The generated hook must evaluate remote_ref when it runs, not during setup.
# shellcheck disable=SC2016
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'read -r _ _ remote_ref _' \
    '[ "$remote_ref" = "refs/heads/feature" ]' > "$LOCAL_HOOK_DIR/pre-push"
chmod +x "$LOCAL_HOOK_DIR/pre-push"
expect_push_pass "local pre-push extension receives ref input" "refs/heads/feature $tip_sha refs/heads/feature $zero"
rm -f "$LOCAL_HOOK_DIR/pre-push"

if [ "$failures" -ne 0 ]; then
    printf '%d of %d hook tests failed\n' "$failures" "$tests" >&2
    exit 1
fi

printf 'all %d hook tests passed\n' "$tests"
