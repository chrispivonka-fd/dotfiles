#!/usr/bin/env python3
"""
Security Reminder Hook for Claude Code

PreToolUse hook that checks Edit/Write/MultiEdit operations for security
anti-patterns and emits a structured warning before the tool runs.

Ported via alirezarezvani/claude-skills' security-guidance skill (MIT),
originally from David Dworken's (Anthropic) security-guidance plugin:
  https://github.com/alirezarezvani/aeo-box/blob/main/.claude/plugins/security-guidance/

The 12-pattern table covers eval/exec/os.system/subprocess-shell-true,
GitHub Actions injection, XSS, pickle, SQL string building, unsafe YAML,
and related hazards. A specific file/rule/content combination blocks once per
session so the warning can be acknowledged without permanently preventing a
reviewed edit. New content and additional matching rules are still evaluated.

Wired as a standalone PreToolUse hook in this repo's optional
.claude/settings-automode.json profile. Setup exposes the tracked hooks at
~/.claude/hooks; the command also resolves them next to the symlinked settings
file during migration, so the dotfiles checkout may live anywhere.

Complements (not duplicates) this repo's other two hooks: scan-written-file.sh
(gitleaks — secrets only) and the official security-guidance@claude-plugins-official
plugin (LLM diff review — real API cost). This one is instant, local,
zero-cost pattern matching for a different bug class (injection/XSS/unsafe
deserialization), firing on every Edit/Write/MultiEdit.
"""

import json
import os
import random
import sys
from datetime import datetime
from hashlib import sha256
from pathlib import Path

# Debug log location (moved to ~/.claude/ for persistence)
DEBUG_LOG_FILE = str(Path.home() / ".claude" / "security-warnings-log.txt")
os.umask(0o077)


def debug_log(message):
    """Append debug message to log file with timestamp."""
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        Path(DEBUG_LOG_FILE).parent.mkdir(parents=True, exist_ok=True)
        with open(DEBUG_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {message}\n")
    except Exception:  # nosec B110 - diagnostics must never interrupt the hook
        # Silently ignore logging errors to avoid disrupting the hook
        pass


# ─────────────────────────────────────────────────────────────────────
# Security patterns (verbatim from upstream — David Dworken @ Anthropic)
# ─────────────────────────────────────────────────────────────────────

SECURITY_PATTERNS = [
    {
        "ruleName": "github_actions_workflow",
        "path_check": lambda path: ".github/workflows/" in path
        and (path.endswith(".yml") or path.endswith(".yaml")),
        "reminder": """You are editing a GitHub Actions workflow file. Be aware of these security risks:

1. **Command Injection**: Never use untrusted input (like issue titles, PR descriptions, commit messages) directly in run: commands without proper escaping
2. **Use environment variables**: Instead of ${{ github.event.issue.title }}, use env: with proper quoting
3. **Review the guide**: https://github.blog/security/vulnerability-research/how-to-catch-github-actions-workflow-injections-before-attackers-do/

Example of UNSAFE pattern to avoid:
run: echo "${{ github.event.issue.title }}"

Example of SAFE pattern:
env:
  TITLE: ${{ github.event.issue.title }}
run: echo "$TITLE"

Other risky inputs to be careful with:
- github.event.issue.body
- github.event.pull_request.title
- github.event.pull_request.body
- github.event.comment.body
- github.event.review.body
- github.event.review_comment.body
- github.event.pages.*.page_name
- github.event.commits.*.message
- github.event.head_commit.message
- github.event.head_commit.author.email
- github.event.head_commit.author.name
- github.event.commits.*.author.email
- github.event.commits.*.author.name
- github.event.pull_request.head.ref
- github.event.pull_request.head.label
- github.event.pull_request.head.repo.default_branch
- github.head_ref""",
    },
    {
        "ruleName": "child_process_exec",
        "substrings": ["child_process.exec", "exec(", "execSync("],
        "reminder": """⚠️ Security Warning: Using child_process.exec() can lead to command injection vulnerabilities.

Instead of:
  exec(`command ${userInput}`)

Use:
  execFile('command', [userInput])  // Node built-in; no shell

execFile (or spawn with shell:false):
- Prevents shell injection
- Handles arguments as a list (no interpolation)
- Recommended whenever you don't actually need shell features

Only use exec() if you absolutely need shell features AND the input is guaranteed to be safe (e.g., from a hardcoded allowlist).""",
    },
    {
        "ruleName": "new_function_injection",
        "substrings": ["new Function"],
        "reminder": "⚠️ Security Warning: Using new Function() with dynamic strings can lead to code injection vulnerabilities. Consider alternative approaches that don't evaluate arbitrary code. Only use new Function() if you truly need to evaluate arbitrary dynamic code.",
    },
    {
        "ruleName": "eval_injection",
        "substrings": ["eval("],
        "reminder": "⚠️ Security Warning: eval() executes arbitrary code and is a major security risk. Consider using JSON.parse() for data parsing or alternative design patterns that don't require code evaluation. Only use eval() if you truly need to evaluate arbitrary code.",
    },
    {
        "ruleName": "react_dangerously_set_html",
        "substrings": ["dangerouslySetInnerHTML"],
        "reminder": "⚠️ Security Warning: dangerouslySetInnerHTML can lead to XSS vulnerabilities if used with untrusted content. Ensure all content is properly sanitized using an HTML sanitizer library like DOMPurify, or use safe alternatives.",
    },
    {
        "ruleName": "document_write_xss",
        "substrings": ["document.write"],
        "reminder": "⚠️ Security Warning: document.write() can be exploited for XSS attacks and has performance issues. Use DOM manipulation methods like createElement() and appendChild() instead.",
    },
    {
        "ruleName": "innerHTML_xss",
        "substrings": [".innerHTML =", ".innerHTML="],
        "reminder": "⚠️ Security Warning: Setting innerHTML with untrusted content can lead to XSS vulnerabilities. Use textContent for plain text or safe DOM methods for HTML content. If you need HTML support, consider using an HTML sanitizer library such as DOMPurify.",
    },
    {
        "ruleName": "pickle_deserialization",
        "substrings": ["pickle"],
        "reminder": "⚠️ Security Warning: Using pickle with untrusted content can lead to arbitrary code execution. Consider using JSON or other safe serialization formats instead. Only use pickle if it is explicitly needed or requested by the user.",
    },
    {
        "ruleName": "os_system_injection",
        "substrings": ["os.system", "from os import system"],
        "reminder": "⚠️ Security Warning: This code appears to use os.system. This should only be used with static arguments and never with arguments that could be user-controlled.",
    },
    {
        "ruleName": "subprocess_shell_true",
        "substrings": ["shell=True", "shell = True"],
        "reminder": "⚠️ Security Warning: subprocess with shell=True can lead to command injection. Pass args as a list instead and omit shell=True (the default). Only use shell=True for static commands without user input.",
    },
    {
        "ruleName": "sql_format_string",
        "substrings": [
            ".format(",
            'f"SELECT',
            "f'SELECT",
            'f"INSERT',
            "f'INSERT",
            'f"UPDATE',
            "f'UPDATE",
            'f"DELETE',
            "f'DELETE",
        ],
        "reminder": "⚠️ Security Warning: Building SQL queries with .format() or f-strings can lead to SQL injection. Use parameterized queries (cursor.execute(sql, params)) or an ORM. Only inline values if they come from a trusted, validated source.",
    },
    {
        "ruleName": "yaml_unsafe_load",
        "substrings": ["yaml.load(", "yaml.unsafe_load"],
        "reminder": "⚠️ Security Warning: yaml.load() without Loader= or yaml.unsafe_load() can execute arbitrary code. Use yaml.safe_load() instead, which only parses standard YAML types.",
    },
]


def get_state_file(session_id):
    """Get session-specific state file path."""
    # Session IDs are external hook input. Hash them so they can never inject a
    # path separator or escape ~/.claude through traversal.
    safe_session_id = sha256(str(session_id).encode("utf-8")).hexdigest()[:32]
    return os.path.expanduser(
        f"~/.claude/security_warnings_state_{safe_session_id}.json"
    )


def cleanup_old_state_files():
    """Remove state files older than 30 days."""
    try:
        state_dir = os.path.expanduser("~/.claude")
        if not os.path.exists(state_dir):
            return

        current_time = datetime.now().timestamp()
        thirty_days_ago = current_time - (30 * 24 * 60 * 60)

        for filename in os.listdir(state_dir):
            if filename.startswith("security_warnings_state_") and filename.endswith(
                ".json"
            ):
                file_path = os.path.join(state_dir, filename)
                try:
                    file_mtime = os.path.getmtime(file_path)
                    if file_mtime < thirty_days_ago:
                        os.remove(file_path)
                except OSError:
                    pass
    except Exception:  # nosec B110 - best-effort cleanup must not block edits
        pass


def load_state(session_id):
    """Load the state of shown warnings from file."""
    state_file = get_state_file(session_id)
    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                return set(json.load(f))
        except (json.JSONDecodeError, IOError):
            return set()
    return set()


def save_state(session_id, shown_warnings):
    """Save the state of shown warnings to file."""
    state_file = get_state_file(session_id)
    try:
        os.makedirs(os.path.dirname(state_file), exist_ok=True)
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump(list(shown_warnings), f)
    except IOError as e:
        debug_log(f"Failed to save state file: {e}")


def check_patterns(file_path, content):
    """Return every security rule/reminder matched by the path or content."""
    normalized_path = file_path.lstrip("/")
    matches = []

    for pattern in SECURITY_PATTERNS:
        if "path_check" in pattern and pattern["path_check"](normalized_path):
            matches.append((pattern["ruleName"], pattern["reminder"]))
            continue

        if "substrings" in pattern and content:
            if any(substring in content for substring in pattern["substrings"]):
                matches.append((pattern["ruleName"], pattern["reminder"]))

    return matches


def extract_content_from_input(tool_name, tool_input):
    """Extract the content that will be written/edited."""
    if tool_name == "Write":
        return tool_input.get("content", "")
    elif tool_name == "Edit":
        return tool_input.get("new_string", "")
    elif tool_name == "MultiEdit":
        edits = tool_input.get("edits", [])
        if edits:
            return " ".join(edit.get("new_string", "") for edit in edits)
        return ""
    return ""


def main():
    """Main hook function."""
    # Check if security reminders are enabled
    if os.environ.get("ENABLE_SECURITY_REMINDER", "1") == "0":
        sys.exit(0)

    # Periodically clean up old state files (10% chance per run)
    if random.random() < 0.1:  # nosec B311 - sampling is not security-sensitive
        cleanup_old_state_files()

    # Read hook input from stdin
    try:
        input_data = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        debug_log(f"JSON decode error: {e}")
        sys.exit(0)

    session_id = input_data.get("session_id", "default")
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Only run on file-edit tools
    if tool_name not in ["Edit", "Write", "MultiEdit"]:
        sys.exit(0)

    file_path = tool_input.get("file_path", "")
    if not file_path:
        sys.exit(0)

    content = extract_content_from_input(tool_name, tool_input)

    matches = check_patterns(file_path, content)
    shown_warnings = load_state(session_id)
    content_fingerprint = sha256(content.encode("utf-8")).hexdigest()[:16]
    unseen_reminders = []

    for rule_name, reminder in matches:
        warning_key = f"{file_path}-{rule_name}-{content_fingerprint}"
        if warning_key in shown_warnings:
            continue
        shown_warnings.add(warning_key)
        unseen_reminders.append(reminder)

    if unseen_reminders:
        save_state(session_id, shown_warnings)
        print("\n\n---\n\n".join(unseen_reminders), file=sys.stderr)
        # Exit code 2 blocks this first attempt so the caller must acknowledge
        # the warnings. An identical retry in the same session is then allowed.
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
