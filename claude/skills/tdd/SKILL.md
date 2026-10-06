---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
model: anthropic.claude-sonnet-5[1m]
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle: consult them before and during the loop, not after.

When exploring the codebase, read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

Also read the approved spec/ticket interface contracts and acceptance criteria.
If the module interface or seam is still undecided, stop and use
`codebase-design` before writing tests. Make no test or code edit in that path.
After the interface is approved, invoke `tdd` again to reapply Sonnet before
starting red/green work. TDD drives implementation behind an agreed interface;
it does not discover a public contract by accident.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is a place where behavior can vary. TDD tracer bullets and
acceptance evidence exercise the approved public seam, where behavior is
observable without reaching inside. Focused internal tests may cover complex
private invariants through an internal seam, but they never substitute for
public behavior evidence and must not force internals into the public
interface.

**Test only at pre-agreed seams.** Before writing any test, write down the
seams under test. An approved spec or interface contract is sufficient user
confirmation; do not pause again merely to reconfirm it. Ask only when the seam
is unresolved or implementation would materially change the approved contract.
No test is written at an unconfirmed seam. You can't test everything, so
agreeing the seams up front is how testing effort lands on the critical paths
and complex logic instead of every edge case.

When confirmation is genuinely missing, use Claude Code's `AskUserQuestion`
tool. If it is unavailable, stop and require a fresh `tdd` invocation with the
answer before any test or code edit.

Map each acceptance criterion to at least one observable example at an agreed
seam, without forcing a one-test-per-criterion shape when one behavior test
proves several criteria. Keep that map for `definition-of-done`; a green suite
does not by itself prove an unmapped criterion.

Record the red evidence for each new behavior: the test/example identifier,
exact command, and meaningful failure observed before the implementation. When
a criterion is not suited to an automated test, record its failing observation
against the fixed point instead. This evidence proves the ticket did not merely
adopt a check that already passed at base.

When the shape of that interface is itself in question (how deep the module is,
where the seam belongs, what the interface should expose), stop and invoke
`codebase-design` for Opus design work. Do not continue tests or implementation
in that turn. Once the contract is approved, invoke `tdd` again so work resumes
on Sonnet.

## Anti-patterns

- **Implementation-coupled evidence**: treats mocks of internal collaborators,
  private-method assertions, or side-channel checks as proof of accepted
  behavior. Focused internal invariant tests are allowed, but acceptance still
  passes only at the approved public seam. The tell: claimed behavior evidence
  breaks when internals are refactored but behavior has not changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see the `code-review` skill), not the red → green implementation cycle.
