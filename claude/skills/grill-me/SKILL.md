---
name: grill-me
description: A relentless interview to sharpen a plan or design.
disable-model-invocation: true
model: anthropic.claude-opus-5-5[1m]
---

For a software product or repository change, call the Skill tool for
"grilling" and "codebase-design". Read existing domain docs for vocabulary,
but do not create or edit domain docs or ADRs in this lightweight flow; use
`/grill-with-docs` when the user wants those artifacts maintained. Use the
interview to settle behavior and then agree the affected deep modules, their
small public interfaces, invariants, adapters, and test seams before handing
the result to `/to-spec`. For a consequential new interface, use the
`codebase-design/DESIGN-IT-TWICE.md` process with explicit Opus 5.5 delegates
and record the user's in-turn choice, without creating domain docs. For a
general plan or decision, call the Skill tool with "grilling" only.
