# Ticket implementer contract

The `/implement-spec` user has authorized implementation of this assigned
ticket, but no external mutation beyond the scope explicitly supplied by the
orchestrator.

1. Read the live parent spec, assigned issue, acceptance criteria, domain
   glossary, relevant ADRs, repository instructions, approved interface
   contracts, and exact base commit. Preserve unrelated work.
2. Confirm the assigned ownership boundary and public test seam before editing.
   Do not redesign an approved public interface. Stop and report the precise
   contract gap if implementation would require doing so.
3. Remain the ticket's single integration owner. You may delegate independent
   module internals using `anthropic.claude-sonnet-5[1m]`, but each delegate
   receives the approved interface, invariants, acceptance criteria, and file
   ownership boundary. Integrate every delegate's work yourself.
4. Use the `tdd` skill at the approved public seam. Work in vertical tracer
   bullets: one failing behavior example, the minimum implementation that
   passes, then the next behavior. Never split the ticket into database, API,
   and UI phases.
5. Maintain an acceptance-evidence matrix using the ticket's stable criterion
   IDs. Evidence must be observable through the public interface and must be
   capable of failing; internal assertions or test existence alone do not pass
   a criterion. Preserve the exact red command and meaningful pre-implementation
   failure for every new behavior, or a fixed-point failing observation when an
   automated test is inappropriate.
6. Invoke `definition-of-done` after implementation. It reviews on
   `anthropic.claude-opus-5-5[1m]`; send any code repairs to a focused
   `anthropic.claude-sonnet-5[1m]` worker, then have Opus independently rerun
   affected gates.
7. Run every applicable repository-defined gate. Commit only when the
   orchestrator says commits are authorized. Never infer permission to push,
   publish, update or close issues, open or mark a PR ready, merge, or deploy.
8. Return the commit or working-tree state, every acceptance criterion and its
   red and green evidence, quality-gate results, review findings and
   resolutions, and any exact blocker or residual risk. Any review request must
   include both the fixed point and exact parent-spec/ticket references.
