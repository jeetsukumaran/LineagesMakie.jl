---
date-created: 2026-04-22T23:15:15
date-updated: 2026-04-22T23:15:27
---

## Review focus

A suite of visualization bugs remaining after Tier 1 was feature complete and passing all tests took a considerable amount of effort and time to finally resolve. 
(For historical record: The agent contributing to this work was Claude, the agent reviewing this work is Codex; this was not a designed to be a cross-agent cross-check. Just opportunistic due to credit availability.)

## Coding agent behavior and performance

**Findings**
1. Location — [03_tasks--14.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--14.md:14), [03_tasks--15.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--15.md:14), [03_tasks--16.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--16.md:14). Severity — high. Pass — Pattern improvements. Description — the main root cause was design mis-scoping: a single cross-cutting layout/ownership problem was repeatedly treated as isolated recipe bugs. The tasking kept asserting “no architectural changes” even though Issue 16 itself described the real defect as “no decoration layout model” and “mixed data-scene vs decoration-scene annotations” at [03_tasks--16.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--16.md:101). That is why fixes kept landing in `LeafLabelLayer`, `CladeLabelLayer`, `_wire_x_axis!`, and `ScaleBarLayer` one symptom at a time, while collisions and clipping kept resurfacing. Fix — the current panel-owned model in [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:61), [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:389), and [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:1034) is the first fix at the right level.

2. Location — [03_tasks--14.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--14.md:35), [03_tasks--18.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--18.md:74), [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl:782). Severity — high. Pass — Logic errors. Description — the earlier clade-highlight “clamp to bounding box” fix was an actual anti-fix. Issue 14 diagnosed the degenerate-viewport fallback correctly, but its prescribed remedy was to clamp the bad rectangle. Issue 18 later spelled out why that was wrong: clamping hid the error and turned it into a plausible full-width, non-clade-local rectangle. Fix — the real fix is the current one in [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl:784): suppress padding while the viewport is degenerate, then recompute reactively from raw clade bounds. The newer tests at [test/test_Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Layers.jl:476) and [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl:555) finally specify the right behavior.

3. Location — [03_tasks--15.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--15.md:58), [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl:849), [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:610), [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl:1069), [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl:137). Severity — high. Pass — Bad practices. Description — there was also a real Makie API/model misunderstanding. The code originally treated decorations like ordinary plot content instead of panel-owned `blockscene` content, and the public API did not follow Makie’s normal bang/non-bang contract. Issue 15’s bracket fix was locally correct, but it only solved clipping for one layer. This session’s `lineageplot(...) -> FigureAxisPlot` change and the decoration-band work generalized the missing Makie semantics. Fix — the current split is the right one: `lineageplot(...)` creates context and returns a display-ready figure-like object, `lineageplot!(...)` mutates existing context, and `LineageAxis` owns panel decorations.

4. Location — [03_tasks--18.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--18.md:17), [test/test_Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Layers.jl:273), [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl:267). Severity — medium. Pass — Bad practices. Description — the tests were a major contributor. Earlier tests mostly asserted “renders”, “geometry exists”, or “stays within the bounding box”, which allowed green builds with visibly wrong PNGs. Even now, one residual weak point remains: [test/test_Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Layers.jl:273) still checks coexistence of leaf/clade label geometry, not literal rendered text-bbox non-overlap. Fix — keep the stronger locality/pixel tests we added, and if this area regresses again, add a rendered text-overlap assertion instead of another geometry-only proxy.

5. Location — [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl:1480), [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl:267). Severity — medium. Pass — Pattern improvements. Description — the junction gap was not a geometry bug; it was a missing rendering contract. Edges were continuous, but marker fill/stroke ordering was unspecified, so a white-filled internal marker could erase a branch intersection. This was not really “agent drift”; it was an unmodeled visual policy. Fix — the current two-pass marker render is a real fix for the reported styling and the new pixel regression is good. It is still a policy choice, though, so if marker styling becomes more flexible later, that contract should stay explicit rather than implicit in draw order.

**Assessment**
This was not mostly agent drift. The biggest causes were:
- design problems: no single owner for annotation/decor layout
- Makie contract misunderstanding: `blockscene` vs data scene, and non-bang plot semantics
- concrete logic bugs: especially the degenerate-viewport highlight fallback
- weak acceptance tests: green builds that didn’t encode the visible requirements

There was some drift, but it was mostly task-frame drift, not random agent wandering. The archived task files repeatedly narrowed the work to local, non-architectural edits, so an obedient agent could keep producing plausible partial fixes that still missed the system boundary. The later diagnoses were materially better, not because the earlier agents were clueless, but because they finally traced the whole example end-to-end and challenged the “local patch only” premise.

The follow-up diagnoses were mostly good:
- Issue 15 correctly identified the bracket clipping problem.
- Issue 16 correctly named the missing decoration layout model.
- Issue 18 correctly called out the highlight clamp as masking the real bug.
- This conversation’s review log correctly unified the remaining issues under shared ownership and rendering-contract failures.

The one clear non-fix/anti-fix was the old clade-highlight clamp. Most of the other earlier fixes were partial but directionally correct. The current batch is mostly real fixes, with one residual caveat: label-readability testing is still weaker than the underlying implementation now deserves.


### Workflow skills 

**High findings**
- [devflow-02 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-02--prd-to-issues/SKILL.md:24>) and [devflow-03 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-03--issue-to-tasks/SKILL.md:27>) bias too hard toward thin AFK slices and one-session tasks. That works well for ordinary feature work, but it is a bad default for graphics/layout/reactivity problems where several symptoms share one owner. In this case, that bias helped turn one cross-cutting defect into a series of local tickets. The archived tasking then amplified that by repeatedly asserting “no architectural changes are required” in [03_tasks--14.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--14.md:14>), [03_tasks--15.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--15.md:14>), and [03_tasks--16.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--16.md:14>).

- `devflow-03` is missing a mandatory “revalidate the issue diagnosis before implementing” checkpoint. That was the biggest process hole. The clearest anti-fix was the old highlight clamp: Issue 14 prescribed clamping a bad rectangle in [03_tasks--14.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--14.md:32>), while Issue 18 later correctly explained that clamping was masking the error in [03_tasks--18.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--18.md:107>). A good tasking skill should force that contradiction to surface before code is written.

- None of `devflow-01` to `03` require primary-source framework verification when the feature depends heavily on external library semantics. [devflow-01 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-01--write-a-prd/SKILL.md:20>) says “explore the codebase,” but not “read the upstream framework source/docs if the design depends on them.” For Makie-heavy work, that gap mattered. It likely contributed to the early confusion around `blockscene` vs data scene and around Makie-consistent `lineageplot(...)` behavior.

**Medium findings**
- This was not mainly user fuzziness. The PRD was actually pretty clear about the real architecture: the three-view model is explicit in [01_prd.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/01_prd.md:97>) and formalized again in [01_prd.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/01_prd.md:131>). So the bad architecture was not coming from a vague product statement. It was mostly introduced in the issue/task translation and then preserved in handoff.

- `devflow-01` is mostly good. Its strongest lines are actually the ones about deep modules in [devflow-01 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-01--write-a-prd/SKILL.md:88>). The problem is that it does not force the PRD to include a cross-cutting ownership map or an “architectural risks / do not patch locally” section. So a decent PRD can still hand off into issues that underspecify the shared owner.

- The “prefer AFK over HITL” rule in [devflow-02 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-02--prd-to-issues/SKILL.md:28>) likely made the workflow less willing to create an explicit architecture-review gate. That probably fed into [02_issues.md](</home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/.workflow-docs/202604181600_tier1/02_issues.md:7>), which declares all issues AFK.

**Attribution**
- User fuzziness: low.
- `devflow-01` agent / PRD step: low to medium. The PRD seems mostly sound.
- `devflow-02` agent / issue breakdown: medium to high. This is where the architecture got sliced into too many symptom-tickets.
- `devflow-03` agent / tasking step: high. This is where partial diagnoses became executable instructions.
- Handoff between agents: high. Fresh agents were not the mistake; the mistake was handing them documents that froze partial assumptions.

Your “fresh agent instead of parallel” instinct was reasonable. I don’t think parallelism would have helped here. The failure mode was not ordinary context drift. It was document drift: each fresh agent inherited a narrowed framing and then faithfully executed it.

**Were the later diagnoses better?**
Yes. Issue 16’s diagnosis was substantially better than 14/15, and the later audit/review work was better still. The problem was that the workflow had already accumulated local fixes, and there was no built-in requirement to stop, unify, and reframe the problem at the architecture level until this conversation.

**Would `devflow-05` / `06` have helped?**
- `devflow-05` probably would have helped a little, but not enough. It is diff/file oriented and would be better at catching local anti-fixes than systemic design drift.
- `devflow-06` likely would have helped a lot. Its wording is explicitly about cross-cutting, replicated, systemic problems in [devflow-06 SKILL.md](</home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/devflow-06--final-audit/SKILL.md:8>). That is almost exactly the failure mode here.

**How I’d rewrite them**
- `devflow-01`: add a mandatory `Cross-cutting architecture and ownership` section to the PRD.
  It should name which module owns layout, which owns rendering, which owns external framework contracts, and which bugs must never be solved by local patches.
- `devflow-01`: add a mandatory `Primary upstream references` section for framework-heavy work.
  If behavior depends on Makie, React, Rails, etc., the PRD agent must read primary source/docs and cite the files used.
- `devflow-02`: add an exception to tracer-bullet slicing.
  If multiple symptoms share one owner or one invariant, require a foundational architecture issue before user-facing slices.
- `devflow-02`: stop defaulting toward AFK when framework semantics or architecture are uncertain.
  In those cases, require HITL or at least an explicit review checkpoint.
- `devflow-03`: require Task 0: validate the issue diagnosis against current code, current output, and primary upstream references.
  If the diagnosis is wrong or incomplete, the agent must stop and rewrite the tasking or escalate.
- `devflow-03`: add a `shared-owner check`.
  If the issue touches multiple modules that all participate in one contract, the first task must establish or repair that contract, not patch each symptom separately.
- `devflow-03`: add tranche support as a first-class pattern.
  “One AI session” is good, but it should say to group work into small green tranches when the problem is architectural rather than purely local.
- `devflow-03`: require integration acceptance artifacts for visual/layout issues.
  Example renders and rendered-behavior assertions should be mandatory, not optional.
