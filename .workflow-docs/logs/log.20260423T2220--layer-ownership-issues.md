---
date-created: 2026-04-23T22:22:01
---

Short answer: this exact bug is fixed, but the bug class is not impossible yet.

What is now true:
- The major ownership boundary is much healthier than before. `LineageAxis` now really owns screen embedding, camera direction, screen-axis decoration, and shared annotation layout. `Layers` mostly consume that owner data instead of inventing their own screen policy.
- The specific regression you saw is fixed because [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:1644) now explicitly forwards the axis-owned `lineage_orientation` into the inner `LineagePlot`, and we added tests for the axis-owned path in [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl:141) and the example-style path in [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl:516).
- The non-mutating `lineageplot(...; axis = (...))` path is in better shape too, because it constructs a `LineageAxis` and then goes through the same `lineageplot!(::LineageAxis, ...)` adapter.

What is still structurally risky:
- `lineage_orientation` still exists on more than one surface: it is a `LineageAxis` attribute and also a `LineagePlot` recipe attribute. That duplication exists for a reason, because plain `Axis` plotting still needs plot-owned orientation, but it means there is still an adapter seam.
- So if future screen-owning semantics are added or changed and they are accepted on both the axis surface and the plot surface, the same class of bug can recur unless that reconciliation is handled deliberately.
- In other words: I think we fixed the important ownership issue, but not the deeper fact that some semantics are still represented twice and therefore must be synchronized correctly.

How to avoid this happening again:
- Code practice: move the `LineageAxis` -> `LineagePlot` reconciliation into one named helper, something like `_resolved_lineageaxis_plot_kwargs(...)` or a small normalized policy struct. Right now the merge is still open-coded in one method. It is correct now, but a helper would make future additions much safer.
- Verification practice: whenever a public semantic can be supplied from multiple entry surfaces, require tests for each supported surface. For this package that means at least:
  - axis constructor only
  - `lineageplot!(lax, ...; kw...)`
  - non-mutating `lineageplot(...; axis = (...))`
  - plain `Axis` path if supported there
- Example practice: if a public example is the clearest artifact for a behavior, keep an integration test aligned with that exact example shape. This regression slipped through partly because the integration smoke had drifted away from the real `lineageplot_ex2.jl` panel.
- Governance: the repo already says the right general things in [STYLE-architecture.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/STYLE-architecture.md:36) and [STYLE-verification.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/STYLE-verification.md:27), but I do think one more explicit rule would help.

The rule I would add:
- In `STYLE-architecture.md`: “If a public semantic can be supplied from more than one API surface, one canonical owner must normalize it once and forward the resolved value downstream explicitly. Consumers must not infer independent defaults for the same semantic.”
- In `STYLE-verification.md`: “If a public semantic is available from multiple entry surfaces, verification must include at least one regression per supported surface. Testing only one surface is insufficient.”

So my answer to your two big questions is:
- `(1)` Mostly yes: the important ownership defects have been repaired.
- `(2)` Not fully future-proof yet: the remaining risk is cross-surface semantic duplication, and the best prevention is a combination of a single normalization helper plus an explicit multi-surface verification rule in governance.

If you want, I can make those governance-document edits now and add the helper refactor as a small hardening pass.