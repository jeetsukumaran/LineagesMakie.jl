# Tasking index for LineagesMakie.jl tier 1 audit fixes

Parent PRD:
`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

Parent tranche file:
`.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`

This directory now has two tasking states:

- completed tranche tasking files archived under `completed_tranches/`
- one still-pending tranche tasking file for the remaining render-level
  readability and proof-surface work

## Completed tranche tasking files

- Tranche 1:
  `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-01--tasking.md`
- Tranche 2:
  `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-02--tasking.md`
- Immediate action IA20260423-01:
  `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-IA20260423-01--tasking.md`

## Active tranche tasking file

- Tranche 3:
  `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-03--tasking.md`
  This remains the pending render-level readability and proof-surface tranche.
  It has been reviewed after the completed immediate-action tranche and updated
  to inherit the current owner-normalized, multi-surface-verified baseline
  rather than the older pre-IA framing.

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
  verification obligations from the PRD, tranche documents, completed tranche
  tasking, audit logs, and updated governance documents.
