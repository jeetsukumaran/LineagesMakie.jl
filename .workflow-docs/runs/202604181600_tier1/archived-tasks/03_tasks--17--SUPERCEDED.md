# Superseded tasking for Issue 17

Parent issue: Issue 17.
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Status

This tasking is superseded by
`.workflow-docs/202604181600_tier1/03_tasks--18.md`.
Do not implement the original Issue 17 instructions.

## Why it was superseded

Subsequent code review showed that the original tasking diagnosed the highlight
bug incorrectly.

- `CladeHighlightLayer` already uses the owning plot scene for
  `register_pixel_projection!` and `pixel_offset_to_data_delta`.
- The visible failure in `examples/lineageplot_ex2.png` comes from the
  degenerate-viewport fallback in `pixel_offset_to_data_delta` being
  interpreted as data-space padding and then clamped to `geom.boundingbox`.
- The corrected active tasking is
  `.workflow-docs/202604181600_tier1/03_tasks--18.md`, which targets that
  concrete fallback path and its missing tests.

## Active replacement

Use `.workflow-docs/202604181600_tier1/03_tasks--18.md` for the clade-highlight
fix.
Keep `.workflow-docs/202604181600_tier1/03_tasks--16.md` as the active
decoration-layout and annotation-placement tasking.
