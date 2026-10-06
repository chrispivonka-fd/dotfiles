---
name: to-spec
description: "Turn an already-grilled product idea into an approved PRD-style design spec and publish it as the parent issue: synthesize decisions, do not restart the interview."
disable-model-invocation: true
model: anthropic.claude-opus-5-5[1m]
---

# To Spec

Turn the settled conversation into the product-and-design source of truth. The
spec is the PRD equivalent: it defines the problem, outcomes, behavior, module
design, test seams, scope, and acceptance. It is not an ADR. ADRs record only
individual durable architectural decisions and should be linked from the spec.

The issue tracker and domain-doc layout must be configured. If they are not,
tell the user to run `/setup-matt-pocock-skills`.

## 1. Gather and verify context

Use the current conversation, repository, `CONTEXT.md`, and relevant
ADRs. Do not repeat the grilling interview. If a product or interface decision
required to write the spec is still genuinely unresolved, list that gap and
return to `/grill-with-docs` (or `/grill-me` when no domain
docs are wanted) rather than silently guessing.

## 2. Design interfaces before implementations

Use the `codebase-design` vocabulary and optimize for deep modules:
small interfaces with high leverage and strong locality.

For every module the change introduces or materially alters, settle:

- its domain responsibility and consumers;
- its public interface: entry points, inputs/outputs, invariants, ordering,
  errors, configuration, and important performance characteristics;
- what complexity remains hidden behind the seam;
- dependency categories and adapters, introducing a port only when at least
  two justified adapters make the seam real;
- the highest public seam through which callers and tests verify behavior.

For a consequential new interface, verify that the grilling record includes
the Design It Twice alternatives, comparison, recommendation, and explicit
user choice. Reuse that approved decision; do not spend another set of agents
or reopen the contract while synthesizing the spec. If the exercise is missing
or a new constraint invalidates it, return to `/grill-with-docs` for Opus
design work (or `/grill-me` for the non-documenting path), then require a fresh
`/to-spec` invocation. The approved interface contracts become constraints for
later module implementers.

## 3. Draft the spec locally

Write the draft to `.scratch/<feature-slug>/spec.md` so it can be
reviewed before any external mutation. Use domain language rather than current
file paths. Include code only when a small state machine, schema, or type shape
captures a settled decision more precisely than prose.

<spec-template>

# <Outcome-oriented title>

## Problem

The user problem, affected actors, current behavior, and why it matters.

## Outcomes and success

Stable IDs (`OUTCOME-1`, `OUTCOME-2`, ...), each followed by an observable
outcome and, where meaningful, measures that show the problem is solved.

## User journeys

The main happy path plus important alternate and failure paths.

## User stories

A complete but non-duplicative numbered set:

1. **US-1:** As a <specific actor>, I want <capability>, so that <valuable outcome>.

Stories describe user value, not layers, files, endpoints, or implementation
tasks.

## Functional behavior

Rules, state transitions, permissions, errors, edge cases, and interactions
that must remain true.

## Module and interface design

For each affected deep module: responsibility, consumers, public interface,
invariants, error modes, dependency/adapters, hidden complexity, and test seam.
State which module implementations can be delegated independently after these
contracts are approved.

## Testing decisions

The agreed public seams, prior art in the repository, critical examples, and
which behaviors require unit, integration, or end-to-end evidence. Tests verify
observable behavior and survive internal refactors.

## Quality, operations, and delivery constraints

Only the applicable measurable constraints and verification approach for
security/privacy, accessibility, reliability/performance, observability,
compatibility/migration, rollout/rollback, and external dependencies or risks.
Omit irrelevant categories instead of adding boilerplate. Any constraint
required for completion must be represented by a `SPEC-AC-*` criterion.

## Acceptance criteria

Stable IDs (`SPEC-AC-1`, `SPEC-AC-2`, ...), followed by observable conditions
for the whole spec. Each criterion must have a conceivable failing observation
and trace to at least one `OUTCOME-*` and `US-*` ID.

## Out of scope

Explicit exclusions and tempting adjacent work that must not enter the tickets.

## Decisions and ADRs

Important reversible decisions inline; links to any separate ADRs for choices
that are hard to reverse, surprising without context, and genuine trade-offs.

## Open questions

This must be empty before publication. If it is not, return to grilling.

</spec-template>

## 4. Approve and publish

Show the local draft and use Claude Code's `AskUserQuestion` tool to ask the
user to approve or edit it, keeping revisions inside this Opus turn. If that
tool is unavailable, stop before publication and tell the user to invoke
`/to-spec` again with their edits or approval so the model override is
reapplied. After approval, publish it as the parent issue in the configured
tracker. On GitHub, preserve the headings and stable acceptance-criterion IDs
in the issue body. Do not mark the parent as an implementation-ready ticket
and do not create child tickets yet; `/to-tickets` owns that decomposition.

Return both the local spec path and the published parent reference so later
skills have stable context pointers.
