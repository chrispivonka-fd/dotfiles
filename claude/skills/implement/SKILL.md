---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
model: anthropic.claude-sonnet-5[1m]
---

# Implement one vertical slice

Implement one approved spec or ticket with a single integration owner.

## Prepare

1. Read the governing spec, ticket, acceptance criteria, domain glossary, and
   relevant ADRs. Record a fixed Git point and preserve unrelated work.
2. Confirm the module design before editing: responsibility, small consumable
   interface, invariants, error modes, dependency category, adapters, and the
   public seam used by callers and tests. The approved spec must already settle
   consequential interfaces. If it does not, make no test or code edit: return
   to `/grill-with-docs` and `/to-spec` for Opus design work, then require a
   fresh `/implement` invocation so implementation resumes on Sonnet.
3. Prefer a deep module that hides complexity and concentrates change. Do not
   expose internal seams merely to make implementation-level tests convenient.

## Implement

Remain the single integration owner for the ticket. Delegate independent module
implementations when that saves time, giving each implementer the agreed
interface, invariants, acceptance criteria, and ownership boundary. Delegates
implement behind the contract; they do not silently redesign it. The owner
integrates the modules and retains responsibility for end-to-end behavior.
Start every implementation delegate with the explicit model
`anthropic.claude-sonnet-5[1m]`; do not rely on the parent session's model or
the global subagent default.

Use /tdd at the pre-agreed public seams. Work one tracer-bullet cycle at a time:
one failing behavior test, the minimum implementation that passes it, then the
next slice. Run focused tests and type checking regularly. Do not split the
ticket into horizontal database/API/UI phases.

## Finish

Run /definition-of-done against every acceptance criterion and all applicable
repository quality gates. Send any code repair to a focused implementation
worker using `anthropic.claude-sonnet-5[1m]`, then have Opus rerun every
affected gate.

Use /code-review against the original fixed point, passing the exact governing
spec and ticket references and explicitly including the current working tree.
Send every material finding to a focused
`anthropic.claude-sonnet-5[1m]` implementation worker; then have Opus rerun
affected gates, /definition-of-done, and review. Only after the review and DoD
are clean: commit the verified state when the task authorizes commits, or leave
it uncommitted when it does not.

Do not infer permission to push, publish, close tickets, or deploy.
