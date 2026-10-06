---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
disable-model-invocation: true
model: anthropic.claude-opus-5-5[1m]
---

Call the Skill tool for "grilling", "domain-modeling", and
"codebase-design".

Use grilling to settle the product and behavior decision tree while domain
modeling sharpens vocabulary and records only qualifying durable tradeoffs as
ADRs. Once behavior is settled, design the affected deep modules before ending
the session: agree their responsibilities, small consumable interfaces,
invariants, error modes, dependency adapters, and public test seams.

For a consequential new interface, use the Design It Twice pattern from the
codebase-design skill: delegate meaningfully different interface proposals
with `anthropic.claude-opus-5-5[1m]`, compare depth, locality, and seam
placement, and recommend one. Use Claude Code's `AskUserQuestion` tool to get
agreement without ending this Opus turn; if unavailable, stop and require the
user to re-invoke `/grill-with-docs` with their choice. Do not implement the
modules in this session. The agreed contracts feed `/to-spec`, which becomes
the PRD-style parent design document.
