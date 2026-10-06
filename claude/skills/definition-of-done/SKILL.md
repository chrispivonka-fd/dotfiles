---
name: definition-of-done
description: Verify an implementation against its spec, acceptance criteria, and repository-defined quality gates. Use before declaring feature or bug work complete, or when the user asks for final testing and evidence.
model: anthropic.claude-opus-5-5[1m]
---

# Definition of Done

Produce an evidence-backed go/no-go result. Verification does not grant
permission to commit, push, deploy, close tickets, or mutate external systems.
If this is a review-only request, report failures without fixing them. If
implementation is in scope, send code fixes to a focused implementation agent
using `anthropic.claude-sonnet-5[1m]`, then independently rerun the affected
gates on Opus. Do not let a repair silently weaken an acceptance criterion.

## Establish the contract

1. Identify the governing spec or tickets, their acceptance criteria, explicit
   out-of-scope items, and the Git fixed point for this change.
2. Inspect repository status before judging the diff. Separate pre-existing or
   unrelated work and preserve it.
3. Discover the repository's actual quality gates from its agent instructions,
   contributor docs, task runner, package manifests, and CI configuration. Do
   not invent commands or apply a generic stack checklist blindly.

## Verify behavior and design

- Map every acceptance criterion to observable evidence: an automated test,
  a manual check at a public interface, or a concrete artifact.
- Require evidence that each new behavior was false at the fixed point: reuse
  recorded TDD red output, or reproduce the check in a clean fixed-point
  worktree when feasible. A test that already passed at base is not proof of a
  newly delivered criterion. If safe reproduction is infeasible, mark this
  explicitly as an evidence gap rather than inventing a pass.
- Verify behavior at the highest pre-agreed seam. Do not substitute internal
  assertions, mocked implementation details, or code inspection for behavior.
- Confirm the delivered modules retain small, clear interfaces with useful
  depth. Tests and callers should consume those interfaces rather than reach
  into implementations or create new pass-through layers.
- Treat a criterion as unverified when its evidence cannot be produced. State
  the exact blocker; never infer a pass.

## Run applicable gates

Run narrow checks for fast feedback first, then every applicable
repository-defined completion gate. These commonly include formatting, lint,
type checking, unit/integration/end-to-end tests, build or packaging, and
security checks, but only when the repository defines or the change warrants
them. Run the full relevant test suite once at the end when feasible.

Record the exact command, result, and meaningful failure for each gate. A
skipped, unavailable, flaky, or permission-blocked gate is not a pass. Ask
before any check that needs new authority or causes external side effects,
using Claude Code's `AskUserQuestion` tool so the Opus turn remains active. If
it is unavailable, stop and require `/definition-of-done` to be re-invoked
with that authority decision.

## Review the whole change

Review from the fixed point through the current working state, including
committed, staged, unstaged, and relevant untracked files. Check both:

- **Spec:** missing, partial, incorrect, or unrequested behavior.
- **Standards:** repository conventions, interface quality, maintainability,
  and regressions.

Use the `code-review` skill when available, but make the comparison scope
explicit so uncommitted work is not omitted, and pass the exact governing spec
or ticket reference rather than making review rediscover it. Resolve in-scope
findings, rerun their focused tests, then rerun any completion gates they could
affect.

## Report the verdict

Report:

- each acceptance criterion, its evidence, and pass/fail state;
- each quality gate and its result;
- review findings and their resolution;
- skipped checks, residual risks, and unrelated dirty files.

Declare **done** only when every acceptance criterion is verified, applicable
gates pass, and no unresolved material review finding remains. Otherwise
declare **not done** and give the smallest concrete next step.
