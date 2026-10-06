# Curated Claude skills

This is a focused subset of
[mattpocock/skills](https://github.com/mattpocock/skills), reviewed and copied
from commit `c55ee46073ed923f86ce59a5eb3b6d895095d1b7`.
The copied material remains under Matt Pocock's MIT license; see
[`LICENSE.mattpocock`](LICENSE.mattpocock).

## Delivery flow

For software design:

`grill-with-docs` -> `to-spec` -> `to-tickets` ->
`implement` or `implement-spec` ->
`definition-of-done`

- `grill-with-docs` combines the `grilling` decision-tree
  interview with `domain-modeling`, updating domain language and
  offering ADRs only for durable architectural tradeoffs. `grill-me`
  remains the lightweight, non-documenting entry point.
- `to-spec` creates the PRD-style parent design document. It settles
  deep-module interfaces and public test seams before implementation.
- `to-tickets` publishes approved GitHub issues as valuable,
  dependency-aware vertical slices with falsifiable acceptance criteria.
- `implement` owns one ticket. It can delegate module internals behind
  approved interfaces while retaining integration ownership.
- `implement-spec` automatically advances the ready-ticket frontier
  until the full task graph is complete.
- `tdd` drives red/green tracer bullets through public interfaces;
  `codebase-design` supplies the depth, locality, seam, and adapter
  discipline.
- `definition-of-done` proves every acceptance criterion and
  repository-defined quality gate, then uses `code-review` for
  independent Standards and Spec review.

Run `setup-matt-pocock-skills` once per project so the workflow knows
the issue tracker and domain-document layout.

## Model routing

Opus 5.5 requires Claude Code 2.1.280 or newer; this dotfiles repo installs the
Homebrew `claude-code@latest` cask so the client model catalog stays compatible.

The workflow pins models at the skill boundary rather than depending on the
model selected for the surrounding Claude session:

| Work | Model |
| --- | --- |
| Grilling, domain/interface design, and `to-spec` | `anthropic.claude-opus-5-5[1m]` |
| `to-tickets`, `tdd`, and implementation | `anthropic.claude-sonnet-5[1m]` |
| `code-review` and `definition-of-done` | `anthropic.claude-opus-5-5[1m]` |

Interactive skills use Claude Code's question tool so their interviews and
approval cycles stay inside the turn where the skill model applies. If that
tool is unavailable and the turn ends, re-invoke the skill with the answer (or
switch the session with `/model`) because a skill model override is not
persistent across user turns.

Implementation and review skills also pass the full model ID when they spawn
sub-agents. A per-dispatch model takes precedence over the session model and
global sub-agent default. If an organization allowlist rejects a skill model,
or auto mode does not support it, the session model remains active; a rejected
sub-agent model may be substituted or inherited. Verify the active session
model and running workers with `/model` and `/tasks`, especially after swapping
settings profiles; sub-agent substitutions are shown there and may also warn.

## Local adaptations

Imported skills remain close to upstream, with targeted changes:

- `to-spec` drafts locally, distinguishes the PRD-style spec from
  ADRs, and makes interface design an explicit gate.
- `to-tickets` strengthens agile story and acceptance-criterion
  quality for GitHub issue generation.
- `implement` and `implement-spec` support single-ticket and
  automatic-loop implementation while preserving authorization boundaries.
- `code-review` includes uncommitted work and checks module depth and
  seam integrity.
- `definition-of-done` is local because upstream has no stable
  software completion-gate skill.

Do not bulk-update this directory. Review upstream changes against the pinned
revision and deliberately reapply these adaptations.
