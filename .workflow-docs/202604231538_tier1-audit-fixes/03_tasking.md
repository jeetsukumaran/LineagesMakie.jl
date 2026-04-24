# Tasking index for LineagesMakie.jl tier 1 audit fixes

Parent PRD:
`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

Parent tranche file:
`.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`

This directory now has three tasking states:

- completed tranche tasking files archived under `completed_tranches/`
- one still-pending original tranche tasking file
- one new immediate-action tranche tasking file for owner-normalization
  hardening discovered after Tranches 1 and 2 were completed

## Completed tranche tasking files

- Tranche 1: `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-01--tasking.md`
- Tranche 2: `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-02--tasking.md`

## Active tranche tasking files

- Tranche 3: `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-03--tasking.md`
  This remains the render-level readability and proof-surface tranche. It is
  not folded into the immediate-action tranche below because it addresses a
  different defect class.

## Immediate-action tranche tasking files

- IA20260423-01: `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-IA20260423-01--tasking.md`
  Recommended as a single immediate-action tranche. Splitting it further would
  separate the owner-normalization repair from the multi-surface verification
  that proves the repair is actually robust.

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
  verification obligations from the PRD, tranche documents, audit logs, and
  updated governance documents.
