# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Delivery state is recorded as a `Status:` line near the top of each issue file: `open`, `in-progress`, `verified`, or `integrated`
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

For a parent spec, approval publishes the existing
`.scratch/<feature-slug>/spec.md` in place; do not create a duplicate. For a
child ticket, create its new file under
`.scratch/<feature-slug>/issues/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Delivery graph operations

Used by `/to-spec`, `/to-tickets`, and `/implement-spec`.

- **Parent spec**: `.scratch/<feature-slug>/spec.md`.
- **Child ticket**: `.scratch/<feature-slug>/issues/NN-<slug>.md`, numbered from `01`, with the vertical-slice story and acceptance criteria in the body.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every listed file is `integrated`.
- **Frontier**: scan the issue directory for files that are `open` and whose blockers are `integrated`; first by dependency order, then number.
- **Claim**: set `Status: in-progress` before work begins.
- **Complete**: append the acceptance-evidence matrix, set `Status: verified`, then set `Status: integrated` only after the ticket is integrated into the spec branch.
