---
name: implement-spec
description: "Automatically work an approved spec's ready-ticket frontier until the complete vertical-slice task graph satisfies its acceptance criteria."
disable-model-invocation: true
model: anthropic.claude-sonnet-5[1m]
---

# Implement Spec: automatic loop

This is the multi-ticket companion to `/implement`. Use
`/implement` for one ticket with one integration owner; use this skill
to keep advancing an approved spec's task graph until every slice and the whole
spec meet their definition of done.

The tickets are a dependency graph, not a sequence. The **ready frontier** is
every open ticket whose blockers are complete in the tracker or in this run's
verified-and-integrated completion ledger.

## Preconditions and authority

1. Read the entire approved parent spec, all child issues, blocking edges,
   linked ADRs, domain glossary, and repository instructions.
2. Confirm every affected module has an approved deep-module interface,
   invariants, dependency strategy, and public test seam. If an implementer
   would need to invent or materially change an interface, make no
   implementation edit: return to `/grill-with-docs` and `/to-spec` for Opus
   design work, then require a fresh `/implement-spec` invocation so the loop
   resumes on Sonnet.
3. Record the base commit and inspect the working tree. Preserve unrelated work
   and use isolated worktrees for implementation.
4. Use Claude Code's `AskUserQuestion` tool to confirm the requested execution
   scope inside this Sonnet turn. Local branches and worktrees are normal
   implementation mechanics; creating a draft PR, changing GitHub issue state,
   pushing, or marking a PR ready requires the user's request or existing
   workflow authorization. Never merge the final PR or deploy implicitly. If
   the tool is unavailable, stop and require the user to re-invoke
   `/implement-spec` with the scope decision.
5. Create a durable run-local ledger at
   `.scratch/<feature-slug>/implementation-ledger.md` with each ticket's base
   state, blockers, acceptance-evidence status, integration commit, and
   external issue state. Update it after every state transition and leave it
   uncommitted unless the user asks otherwise. Tracker state remains the source
   of truth at startup; verified and integrated ledger entries are the source
   of truth for unblocking later work in this run and after compaction.

## Automatic frontier loop

Repeat until every ticket is complete:

1. Recompute the ready frontier from tracker state, the run-local completion
   ledger, and blocking edges.
2. Dispatch one fresh implementer per ready ticket when their ownership does
   not overlap. For a tightly coupled frontier, serialize tickets rather than
   manufacture merge conflicts. Set every ticket implementer's model explicitly
   to `anthropic.claude-sonnet-5[1m]`; never inherit the orchestrator model. If
   the tracker has a configured `ready-for-agent` label and issue-state changes
   are authorized, remove it from tickets as they are claimed or dispatched.
3. Each ticket implementer owns integration for that vertical slice and works
   in its own branch/worktree. Do not tell it to invoke `/implement`, which is
   intentionally user-only. Instead, load
   [TICKET-IMPLEMENTER.md](TICKET-IMPLEMENTER.md) and include that complete
   contract in its delegation, plus live context pointers to the spec, issue,
   approved interfaces, ADRs, and prior commits rather than stale summaries.
4. Inside a ticket, the implementer may delegate independent module internals
   behind the approved contracts. Delegates cannot redesign public interfaces.
   The ticket implementer must integrate their work and prove the end-to-end
   slice through the agreed seam.
5. A ticket is complete only after `/definition-of-done` maps every
   acceptance criterion to passing evidence and all applicable repository gates
   pass. Tests alone do not close a ticket.
6. Integrate completed tickets into the spec branch one at a time. After each
   integration, run the focused cross-ticket checks affected by the merge.
   Record the integrated commit and evidence in the run-local ledger. Update or
   close the issue only when authorized and only with its evidence recorded;
   lack of external-mutation authority does not keep a verified, integrated
   blocker open inside the run.
7. Recompute the frontier immediately and dispatch newly unblocked tickets.
   If a configured `ready-for-agent` label exists and issue-state changes are
   authorized, apply it to newly unblocked tickets waiting for a worker and
   remove it when they are claimed. Continue without asking for routine
   progress decisions already settled by the spec.

If one ticket needs user input or external authority, keep working independent
frontier tickets. Stop the loop when no ticket changes state during a complete
frontier pass; report the exact blockers rather than retrying indefinitely. If
the turn ends for a blocker, require a fresh `/implement-spec` invocation with
the answer or authority decision before implementation resumes on Sonnet.

## Spec-level completion loop

When all child tickets appear complete:

1. Run `/definition-of-done` against the parent spec, verifying every
   spec-level acceptance criterion through the integrated public interfaces.
2. Run `/code-review` against the original base on both the Standards
   and Spec axes, passing the exact parent spec and child-ticket references.
3. Send material findings to one focused implementer using
   `anthropic.claude-sonnet-5[1m]`, then rerun affected tests, the full
   applicable quality-gate matrix, and the parent
   `/definition-of-done` check.
4. Repeat review and verification only while findings produce concrete
   progress. If the same blocker survives, stop and report it.
5. When authorized, update the draft PR with the acceptance-evidence summary
   and mark it ready. Do not merge it.

Clean up only worktrees and branches created by this run, and only after their
commits are safely integrated. Return the parent spec, PR (if any), completed
issues, ledger path, acceptance-evidence matrix, quality-gate results, and
residual risks.
