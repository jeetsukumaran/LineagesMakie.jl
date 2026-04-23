# Tasking index for LineagesMakie.jl tier 1 audit fixes

Parent PRD:
`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

Parent tranche file:
`.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`

This directory uses tranche-specific tasking files.

## Available tranche tasking files

- Tranche 1: `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-01--tasking.md`
- Tranche 2: `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-02--tasking.md`
- Tranche 3: `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-03--tasking.md`

## Standing constraints

- Every tranche begins from a green state and ends in a green, policy-compliant
  state.
- No task may silently narrow the approved public contract in order to avoid
  implementing the target state.
- `Geometry.jl` remains process/transverse oriented unless the user later
  approves a broader redesign.
- Any task that discovers a necessary external breaking change must stop and
  escalate to the user before implementation continues.
- All downstream tasking must preserve the reading, vocabulary, upstream, and
  verification obligations from the PRD and tranche documents.
