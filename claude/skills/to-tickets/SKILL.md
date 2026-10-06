---
name: to-tickets
description: Turn an approved spec into dependency-aware GitHub issues that are valuable, testable vertical slices with strong acceptance criteria; also supports the configured local tracker.
disable-model-invocation: true
model: anthropic.claude-sonnet-5[1m]
---

# To Tickets

Convert the approved parent spec into an implementation task graph. Each ticket
is an agile user story and a tracer-bullet vertical slice: independently
valuable where the dependency graph permits, end-to-end, demonstrable, small
enough for one fresh context, and testable through an approved interface.

If the issue tracker has not been configured, tell the user to run
`/setup-matt-pocock-skills`.

## 1. Load the source of truth

Read the full approved spec, its parent issue and comments, linked ADRs, domain
glossary, and approved module interfaces. Resolve references completely; do not
decompose a partial or still-open spec.

## 2. Draft vertical slices

Derive slices from user outcomes and journeys, not from technical layers.

- Each ticket delivers a narrow but complete behavior through every necessary
  layer and can be demonstrated or verified on its own.
- Keep tickets independent where practical, negotiable in implementation,
  valuable to an actor, estimable, small, and testable.
- Preserve approved module interfaces and seams. A ticket may delegate module
  internals, but it must integrate them into one observable slice; never create
  separate database/API/UI tickets for one behavior.
- Prefer existing deep modules. If prefactoring is required to make the change
  easy, create the smallest behavior-preserving enabling ticket first.
- Size each ticket for one fresh implementation context. Split by behavior,
  scenario, policy, or workflow step—not by file or architectural layer.

Give every ticket explicit blocking edges. A blocker is valid only when its
completed behavior or contract is genuinely required before the blocked ticket
can begin. Tickets with all blockers complete form the ready frontier.

For a truly wide mechanical refactor that cannot land green as vertical slices,
use expand-contract: add the new form, migrate callers in green batches, then
remove the old form after every migration. Do not use this exception for normal
feature work.

## 3. Write acceptance criteria that can fail

Every criterion must:

- describe observable behavior or a necessary quality constraint, not an
  implementation task;
- identify a concrete observation that would prove it false;
- be false at the ticket's base commit (or exercise a new case not previously
  guaranteed);
- be fully owned by this ticket rather than work deferred to another ticket;
- trace to a spec requirement or explicitly justified enabling outcome;
- be verifiable through the approved public seam.

Use Given/When/Then only when it makes the behavior clearer. Include the
expected evidence or verification method so `/definition-of-done` can
prove each criterion later. Reject tautologies, vague words such as "works" or
"properly," and criteria that merely say tests exist.

## 4. Review the backlog with the user

Present the proposed task graph before publishing. For every ticket show:

- outcome-oriented title and agile user story;
- end-to-end behavior delivered;
- approved interface contract(s) it consumes;
- acceptance criteria and their planned evidence;
- blocking tickets, if any.

Build a coverage matrix mapping every parent `SPEC-AC-*` to one or more ticket
acceptance criteria. A missing parent criterion blocks publication; overlap is
allowed only when each ticket owns a distinct observable part.

Use Claude Code's `AskUserQuestion` tool to ask whether the slices are valuable,
small enough, correctly blocked, and complete against the parent spec. Iterate
inside this Sonnet turn until the user approves the graph. If that tool is
unavailable, stop before publication and tell the user to invoke `/to-tickets`
again with their edits or approval so the model override is reapplied.

## 5. Publish approved issues

For GitHub, create one issue per ticket in dependency order and link each to the
parent spec using native sub-issue/blocking relationships when available;
otherwise put `Part of #<parent>` and a machine-readable
`Blocked by: #<n>, #<n>` line near the top of each child body (use
`Blocked by: None` for the ready frontier). Apply the configured
`ready-for-agent` label only to implementation tickets in the current ready
frontier, and only when the repository already defines that label or its
tracker docs explicitly configure it. Blocked tickets receive it later only
when they become unblocked and external issue updates are authorized. Do not
create an undeclared label as a side effect; without one, report the ready
frontier from dependency state. Do not close or relabel the parent spec.

For a local tracker, write one file per ticket under
`.scratch/<feature-slug>/issues/<NN>-<slug>.md` in dependency order. Prepend
`Status: open` and `Blocked by: NN, NN` machine-readable lines near the top;
use `Blocked by: None` when the ticket is initially ready.

<issue-template>

## Parent spec

<parent issue or local spec reference>

## User story

As a <specific actor>, I want <capability>, so that <valuable outcome>.

## What this slice delivers

The narrow end-to-end behavior made possible by this ticket.

## Interface contracts

The approved module interfaces and public test seam this slice consumes. Link
to the relevant spec section; do not repeat volatile implementation detail.

## Acceptance criteria

- [ ] **TICKET-AC-1:** <observable criterion>
  - Traces to: <SPEC-AC-n>, or <ENABLER-n: explicit behavior-preserving justification>
  - Fails when: <concrete falsifying observation>
  - Evidence: <test, manual public-interface check, or artifact>

## Blocked by

<issue references, or "None (ready frontier)">

## Out of scope

<adjacent behavior this ticket intentionally does not implement>

</issue-template>

After publication, return the parent reference, ordered child-issue references,
parent-criterion coverage matrix, blocking graph, and current ready frontier.
Do not begin implementation unless the user also requested it.
