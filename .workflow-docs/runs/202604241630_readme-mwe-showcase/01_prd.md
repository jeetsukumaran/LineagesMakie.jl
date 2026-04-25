---
date-created: 2026-04-24T17:12:30
---

# PRD: LineagesMakie.jl README and planned-capacities roadmap

## User statement

> We are going to be writing a comprehensive MWE-example rich README for
> LineagesMakie.jl that will showcase its features.
>
> Full documentation will be in docs/ but  README should be a self-contained
> document, enough to get new users started as well as quck recap/recipe of
> major features for previous users.
>
> The `design` folder should be read carefully to understand the big picture.
> The code base should be reviewed line-by-line to understand the current state
> of the code. The ./workflow-docs contains logs and notes and PRDs and tasking
> orders that went into the first phase. There is no need to provide full
> development noise like all of this in the readme directly, this is for your
> understanding though some of this may be useful to the end user  (.g., future
> tiers can be summarized and listed in a ROADMAP.md)

Follow-up decisions:

> 1/ do both
> 2/ those examples are good, but are too code-dense and not great for
> introduciton of features to someone not familiar with the code. The README MWE
> should be cleaner, simpler, and more illstrattive introductory, yet more
> compact as well. THe multiplane figure does not really show lineagemakie
> features by plotting them together, so 1 or 2 standalone mwe would deliver the
> same message more cleaninly in less space.
>
> FOr the data types , keep these clean and names generic, e.g. struct Node
>
> 3/
>
> Have subsections,
> e.g "General registry", with the standard Pkg.add etc but a disclaimer that
> the package is not registered yet so you have to install from GitHub
>
> Github development version
>
> Pkg.add((url = ....)
>
> 4/ yes
>
> 5/ planned capacities
>
> 6/ yes

## Problem statement

The current README is only a stub, while the package already contains a broad,
tested Tier 1 plotting surface: generic lineage graph accessors, rectangular and
circular layouts, all current `lineageunits` values, `LineageAxis`, Makie layer
recipes, annotations, scale bars, and Observable-aware composition. A new user
landing on the repository cannot learn the central ideas or copy a clean first
example from the README. A returning user also lacks a compact recipe page for
the major public features.

The existing examples demonstrate real capabilities, but they are too dense to
serve as the primary introduction. In particular, the multi-panel example proves
many features at once, but it does not teach the feature surface in a clean
sequence. The README needs smaller, standalone MWEs with generic data types,
then a compact tour of additional recipes.

The design and workflow history contain valuable architecture context, but most
of it is not end-user documentation. The README should not expose internal
development noise. Future capacities should be moved to a separate
`ROADMAP.md`, written as planned capacities rather than promises.

## Solution

Replace the stub README with a self-contained, example-rich introduction to
LineagesMakie.jl. The README will give new users a clean first plot, explain
the minimal input contract, show the core public plotting entrypoints, and
provide compact recipes for major Tier 1 features. It will preserve the full
documentation split by linking to the docs site for deeper material, while
still being useful without opening the docs.

The README will include one or two new standalone MWEs that are simpler than
the current example scripts. These MWEs will use generic, readable data types
such as `Node`, avoid project-internal vocabulary drift, and keep each example
focused on one teaching goal. Existing example images can remain available, but
the README should use the new MWE outputs where images are useful.

Add a `ROADMAP.md` that summarizes planned capacities in concise tiers. The
roadmap will be informed by `design/target-reference-capacities.md`, but it
will avoid implementation history and avoid implying that deferred capacities
are already available.

## User stories

1. As a new Julia user, I want the README to tell me what LineagesMakie.jl does
   in the first few paragraphs, so that I know whether it fits my plotting task.

2. As a new user, I want installation instructions for the General registry, so
   that I know the eventual standard installation path.

3. As a new user today, I want the README to state clearly that the package is
   not yet registered, so that I do not try a failing registry install and blame
   myself.

4. As a new user today, I want GitHub development-version installation
   instructions, so that I can install the package immediately.

5. As a user copying code into the Julia REPL, I want the first README MWE to
   use a simple `Node` type, so that I can understand the input structure
   without learning package internals first.

6. As a user with a custom Julia data type, I want the README to show the
   `children` accessor clearly, so that I can adapt my own object model.

7. As a user with AbstractTrees-compatible data, I want the README to show the
   AbstractTrees adapter path, so that I do not write unnecessary wrapper code.

8. As a user with edge lengths, I want a compact MWE showing `edgelength`, so
   that I can create a proportional rectangular lineage graph.

9. As a user with labels stored on nodes, I want the README to show `nodevalue`
   or label functions, so that I can label leaves without rewriting my data.

10. As a user evaluating the visual output, I want the README to embed or link
    generated images from the README MWEs, so that I can see what each example
    produces before running it.

11. As a user coming from Makie, I want the README to explain `lineageplot`
    versus `lineageplot!`, so that I know when to use the convenience path and
    when to compose inside an existing figure.

12. As a user building multi-panel figures, I want a short `LineageAxis` example,
    so that I can place lineage graph plots in a larger Makie layout.

13. As a user with ordinary `Axis` workflows, I want the README to state that
    `lineageplot!` can target a standard Makie axis, so that I can integrate
    with existing figure code when I do not need lineage-specific decorations.

14. As a user choosing process coordinates, I want a concise `lineageunits`
    table, so that I can pick `:edgelengths`, `:branchingtime`,
    `:coalescenceage`, `:nodedepths`, `:nodeheights`, `:nodelevels`,
    `:nodecoords`, or `:nodepos` correctly.

15. As a user without edge lengths, I want the README to explain the default
    clade graph behavior, so that I understand why the first plot still works.

16. As a user with missing or invalid edge lengths, I want the README to set the
    right expectations at a high level, so that I know when to look at the full
    docs for validation and failure modes.

17. As a user working with time direction, I want the README to explain
    `axis_polarity` and `display_polarity` without conflating them, so that I
    can reason about forward and backward process coordinates.

18. As a user choosing plot orientation, I want the README to show the supported
    `lineage_orientation` values, so that I do not guess at unsupported names.

19. As a user making vertical dendrogram-style displays, I want a compact recipe
    for `:top_to_bottom` or `:bottom_to_top`, so that I can use the current
    screen-axis API correctly.

20. As a user making radial plots, I want a compact radial recipe, so that I can
    switch from a rectangular plot without rewriting the data model.

21. As a user styling plots, I want examples of edge, node, leaf, and label
    styling, so that I can discover the namespaced layer keywords.

22. As a user annotating clades, I want compact examples of clade highlights and
    clade labels, so that I can mark meaningful subtrees.

23. As a user using physical or time-like units, I want a scale-bar example, so
    that I can show an interpretable reference length.

24. As a user who wants lower-level composition, I want a manual layer
    composition recipe, so that I can use geometry and layer recipes directly.

25. As a user building interactive or reactive Makie displays, I want an
    Observable recipe, so that I can see how the plot updates when the rootnode
    or attributes change.

26. As a user debugging layouts, I want the README to mention
    `LineageGraphGeometry` and `boundingbox`, so that I know what to inspect.

27. As a returning user, I want the README to serve as a quick recipe index, so
    that I can find keyword names without scanning source files.

28. As a documentation maintainer, I want README examples to be runnable and
    verified, so that the README does not drift from the public API.

29. As a documentation maintainer, I want the README to link to full docs rather
    than duplicating every detail, so that README and docs can coexist without
    becoming inconsistent.

30. As a documentation maintainer, I want future capacities listed in
    `ROADMAP.md`, so that README users see the current feature surface without
    confusing planned features for live features.

31. As a maintainer, I want the roadmap to use planned-capacity language, so
    that it does not create unsupported API promises.

32. As a maintainer, I want the README and roadmap to use the controlled
    vocabulary, so that they do not reintroduce stale `vertex` or `tip`
    terminology.

33. As a maintainer, I want the implementation to preserve the existing public
    API, so that a documentation pass does not become a hidden breaking change.

34. As a reviewer, I want verification to include the test suite, docs build,
    and README MWE execution, so that the release-facing documentation is
    proven at the right boundary.

35. As a reviewer, I want generated images checked visually or by render-level
    smoke tests, so that blank or overlapping outputs are not committed.

36. As a downstream task agent, I want the PRD to identify the upstream Makie
    and AbstractTrees contracts that matter, so that README examples preserve
    host-framework semantics.

37. As a downstream task agent, I want explicit out-of-scope boundaries, so that
    README work does not turn into a redesign of the plotting internals.

38. As a user reading the README on GitHub, I want headings and examples to be
    scannable, so that I can find the relevant recipe quickly.

39. As a user reading the README on a small screen, I want examples and images
    to remain compact, so that the README is usable outside a large desktop
    browser.

40. As a user comparing examples, I want one idea per MWE, so that the examples
    teach rather than compress many unrelated features into one figure.

## Implementation decisions

- The work covers both the README and a new planned-capacities roadmap.

- The README is a user-facing document, not a development-history document. It
  should be informed by design and workflow docs, but it should not include
  PRD/task/log noise.

- The README must be self-contained enough for first use and quick recall. It
  should link to full docs for exhaustive reference material.

- The existing examples remain useful, but they are not the main teaching
  examples for the README. The implementation should create one or two simpler
  standalone README-oriented MWEs and use those as the primary examples.

- README MWE data types must be generic and clean. Use names like `Node`, not
  package-specific or workflow-specific names.

- README examples should be compact, copy-paste runnable, and limited to current
  supported behavior. Avoid aspirational snippets unless explicitly placed in
  `ROADMAP.md`, and avoid presenting planned capacities as live API.

- Installation instructions must include a "General registry" subsection with
  the standard registry installation form and an explicit statement that the
  package is not registered yet. Installation instructions must also include a
  "GitHub development version" subsection using the repository URL.

- The README must show both high-level and mutating entrypoints: `lineageplot`
  for convenience and `lineageplot!` for composition into `LineageAxis` or an
  existing Makie axis.

- The README must teach the accessor-first input model before diving into
  styling. The minimum user mental model is: rootnode, `children`, optional
  accessors, and then plot.

- The README must include a concise feature tour covering layouts,
  `lineageunits`, orientation and polarity, labels, clade annotations, scale
  bars, manual layer composition, Observable reactivity, and geometry
  inspection.

- The README should prefer one or two focused standalone MWEs over a single
  multi-panel showcase. Additional features can be shown as compact recipes.

- Generated README images should come from the README-specific MWEs or a
  similarly simple script, not from the dense existing multi-panel example as
  the primary introduction.

- The roadmap should be concise and grouped as planned capacities. It should
  summarize near-term and later capacities from the design documents without
  reference-package comparison tables unless those comparisons are essential to
  understanding the capacity.

- No public API change is authorized by this PRD. If an implementation task
  discovers that a README goal cannot be documented honestly without a code
  change, it must stop and request user approval or a separate implementation
  PRD/tranche.

- No external breaking change is authorized. No compatibility shim, migration
  plan, or deprecation is expected because this is a documentation feature.

- The current working tree contains unrelated local modifications in source,
  tests, and design documents. Downstream implementation must preserve them and
  must not revert or overwrite user-owned changes.

## Module design

- **Name**: README overview
  **Responsibility**: Explain what LineagesMakie.jl is, who it is for, and why
  it exists in the Makie ecosystem.
  **Interface**: Repository visitors read a synopsis, core value proposition,
  badges, docs links, and a short statement that LineagesMakie.jl plots generic
  lineage graphs from Julia objects exposing children or the AbstractTrees
  interface.
  **Tested**: Yes, by review against current implementation and controlled
  vocabulary.

- **Name**: README installation section
  **Responsibility**: Give correct installation paths for current and future
  package states.
  **Interface**: Two subsections: "General registry" with the standard registry
  form and a clear not-yet-registered disclaimer, and "GitHub development
  version" with the repository URL installation form.
  **Tested**: Yes, by checking syntax during implementation and ensuring the
  package URL matches the repository remote.

- **Name**: README MWE examples
  **Responsibility**: Provide one or two simple, standalone, introductory
  examples that teach the input contract and key plotting outputs.
  **Interface**: Copy-paste runnable Julia snippets using a generic `Node`
  type, simple constructors, `lineagegraph_accessor` or `abstracttrees_accessor`,
  `lineageplot`, and compact styling or units examples. Outputs should be saved
  or embedded as README images where useful.
  **Tested**: Yes, by executing the MWE scripts or snippets in an appropriate
  Julia project and verifying generated images are nonblank and readable.

- **Name**: README feature recipes
  **Responsibility**: Provide a compact quick-reference tour of major Tier 1
  features without duplicating the full docs.
  **Interface**: Short subsections for input adapters, `lineageunits`,
  rectangular and radial layouts, orientations, polarity, labels, clade
  annotations, scale bars, manual layer composition, Observable reactivity, and
  geometry inspection.
  **Tested**: Yes, by running or mechanically validating all code snippets that
  are presented as runnable examples.

- **Name**: README image assets
  **Responsibility**: Supply visual outputs for the README examples.
  **Interface**: Generated PNGs or other GitHub-renderable images derived from
  the README-specific MWE scripts. Images should be compact and illustrative,
  with filenames and locations that make maintenance obvious.
  **Tested**: Yes, by regenerating the images and checking that rendered output
  is nonblank, correctly framed, and free from obvious text overlap.

- **Name**: Planned-capacities roadmap
  **Responsibility**: Summarize future LineagesMakie.jl capacities separately
  from the current README feature surface.
  **Interface**: A `ROADMAP.md` page grouped by planned capacity tiers or
  horizons, using clear planned-language and avoiding any claim that deferred
  features are available today.
  **Tested**: Yes, by review against design documents, current implementation,
  and controlled vocabulary.

- **Name**: Documentation verification workflow
  **Responsibility**: Ensure README and roadmap stay aligned with the live API.
  **Interface**: Test suite, docs build, README MWE execution, example
  regeneration where relevant, and rendered artifact review.
  **Tested**: Yes, by running the required commands and recording results in
  the implementation handoff.

## Cross-cutting ownership and invariants

- Current behavior is owned by the implementation and tests, not by old design
  aspirations. README examples must be verified against the live code.

- The README is the current public landing page; it must not advertise Tier 2+
  capacities as current features.

- `ROADMAP.md` owns planned capacities. README may link to it, but README must
  keep current features and future plans clearly separated.

- The accessor-first input contract is the core teaching invariant. All input
  examples should reinforce rootnode plus `children`, with optional accessors
  layered on top.

- The three-view model remains an important conceptual invariant:
  lineage graph-centric process coordinates, user-centric semantic
  interpretation, and plotting-centric screen orientation should remain
  distinct in prose and examples.

- `LineageAxis` owns lineage-specific screen embedding, polarity inference,
  axis/grid decorations, and panel-owned annotation layout. README prose should
  not imply that individual layers own those shared screen-axis policies.

- `Geometry` owns layout geometry and `LineageGraphGeometry`; README advanced
  recipes should present it as inspectable output, not as a screen-orientation
  owner.

- Manual layer composition examples must use public layer functions and
  precomputed geometry without relying on private internals.

- Observable examples must preserve Makie semantics. They should show reactive
  use in a minimal way and avoid suggesting bespoke non-Makie update mechanisms.

- Local patches would be unsafe if they paper over an unsupported example. If a
  desired README recipe fails, downstream work must diagnose whether the README
  should change or the code needs separately authorized work.

- No foundational code tranche is required for the documentation work as
  currently scoped. A foundational tranche would become necessary only if
  verified README examples expose a real public contract defect.

## Governance and controlled vocabulary

Downstream tranches and tasks must read the following governance documents
line by line before editing documentation or examples:

- `CONTRIBUTING.md`
- `STYLE-architecture.md`
- `STYLE-docs.md`
- `STYLE-git.md`
- `STYLE-julia.md`
- `STYLE-makie.md`
- `STYLE-upstream-contracts.md`
- `STYLE-verification.md`
- `STYLE-vocabulary.md`
- `STYLE-workflow-docs.md`

Additional project documents required for downstream reading:

- `design/design.md`
- `design/api-landscape.md`
- `design/requirements-landscape-gap.md`
- `design/lineageaxis-proposal.md`
- `design/target-reference-capacities.md`
- `.workflow-docs/runs/202604181600_tier1/01_prd.md`
- `.workflow-docs/runs/202604231538_tier1-audit-fixes/01_prd.md`
- `.workflow-docs/logs/log.20260422T1908--codex-review-report.md`
- `.workflow-docs/logs/log.20260422T2312--codex-audit-of-previous-agent-performance.md`
- `.workflow-docs/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
- `.workflow-docs/logs/log.20260423T2220--layer-ownership-issues.md`

Controlled vocabulary decisions:

- Use `lineage graph`, `LineageGraph`, and `lineagegraph` according to context.
- Use `node`, `nodes`, `rootnode`, `leaf`, and `leaves`.
- Use `edge`, `src`, `dst`, `children`, `edgelength`, `nodevalue`,
  `branchingtime`, `coalescenceage`, and `lineageunits`.
- Use `axis_polarity`, `display_polarity`, `lineage_orientation`,
  `process_coordinate`, `transverse_axis`, `leaf_spacing`, `leaf_order`,
  `node_positions`, `edge_shapes`, `boundingbox`, `color`, and `marker`.
- Use current `lineageunits` values exactly:
  `:edgelengths`, `:branchingtime`, `:coalescenceage`, `:nodedepths`,
  `:nodeheights`, `:nodelevels`, `:nodecoords`, and `:nodepos`.
- Use current `lineage_orientation` values exactly:
  `:left_to_right`, `:right_to_left`, `:bottom_to_top`, `:top_to_bottom`, and
  `:radial`.
- When discussing planned features, use "planned capacity" language rather than
  release promises.

Terms to avoid or constrain:

- Avoid `tip` as a synonym for `leaf`.
- Avoid `vertex` or `vertices` as generic public terminology. Older workflow
  docs use these terms historically; the README and roadmap must use current
  vocabulary.
- Avoid `root` as a noun when `rootnode` is intended.
- Avoid `branch length`, `edge_length`, `weight`, or `len` for the public
  `edgelength` concept.
- Avoid `node_value`; use `nodevalue`.
- Avoid unqualified `topology`; use the controlled clade-graph wording when the
  graph structure is the topic.
- Avoid `flip`, `invert`, `reverse axis`, and `vertical mode` when
  `display_polarity` or `lineage_orientation` is the precise concept.
- Avoid old package-name drift such as "PhyloMakie.jl".

## Primary upstream references

- Makie source: `Makie/src/figureplotting.jl`
  - Used to verify `plot!(ax::AbstractAxis, plot::AbstractPlot)` routing,
    `FigureAxisPlot` patterns, and axis reset expectations.

- Makie source: `Makie/src/makielayout/blocks.jl`
  - Used to verify `Makie.@Block` semantics and why `LineageAxis` participates
    as a custom block.

- Makie source: `Makie/src/makielayout/blocks/axis.jl`
  - Used to verify axis camera reversal patterns and screen-axis ownership
    constraints.

- Makie source: `Makie/src/makielayout/helpers.jl`
  - Used to verify `Makie.get_scene` behavior for Makie axis-like objects.

- Makie source: `Makie/src/camera/projection_math.jl`
  - Used to verify `project` and `to_world` behavior that underlies
    pixel/data coordinate transforms.

- GraphMakie source: `GraphMakie.jl/src/recipes.jl`
  - Used as a primary reference for ComputeGraph recipe patterns involving
    viewport and projection registration.

- AbstractTrees docs: `AbstractTrees.jl/docs/src/index.md`
  - Used to verify the AbstractTrees interface, especially that trees define
    `children` and that the fallback treats objects as single-node trees.

- AbstractTrees source: `AbstractTrees.jl/src/base.jl`
  - Used to verify `children`, `nodevalue`, and default fallback behavior.

- LineagesMakie.jl source, examples, tests, design docs, and workflow docs
  - Used as the primary source for the package's current public surface and
    implementation state.

## Testing decisions

- All README examples presented as runnable must actually run.

- README-specific MWE scripts or snippets should be executed in the examples or
  documentation environment chosen by the implementation tranche.

- Generated README images must be regenerated from the source examples and
  checked for nonblank output, framing, and obvious label overlap.

- The full package test suite must pass before documentation work is considered
  complete. During PRD discovery, `julia --project=test test/runtests.jl`
  passed with 748 tests in 13m10.9s.

- If the README or docs cross-linking changes the docs build surface, run the
  docs build.

- If examples are added under the examples project, run those examples with the
  examples project.

- If README snippets are copied from example scripts, the source script should
  be treated as the maintainable verified artifact, and snippets should stay in
  sync with it.

- A good README test checks the public documentation contract, not internal
  implementation variables. Examples should fail if public API names drift.

- A good roadmap review checks that every listed capacity is either current and
  correctly labeled, or planned and clearly separated from current behavior.

- Prior test references in the current codebase:
  - Accessor tests for `lineagegraph_accessor`, `abstracttrees_accessor`,
    `children`, `leaves`, and cycle/shared-node failure behavior.
  - Geometry tests for all `lineageunits`, defaults, bounding boxes, rectangular
    and circular layouts, and failure modes.
  - Layer tests for labels, clade highlights, clade labels, scale bars, and
    annotation layout.
  - LineageAxis tests for orientations, polarity, axes, grid, and annotation
    measurements.
  - Integration tests for `lineageplot`, `lineageplot!`, all current
    `lineageunits`, supported orientations, Observable reactivity, and
    render-level smoke checks.

Recommended acceptance checks for the implementation tranche:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl` if docs links or docs pages are touched
- `julia --project=examples <readme-mwe-script>` for each README MWE script
- `julia --project=examples examples/lineageplot_ex1.jl` and
  `julia --project=examples examples/lineageplot_ex2.jl` if existing example
  images or links are changed
- Manual or scripted inspection of README-generated images for nonblank,
  correctly framed output

## Out of scope

- Changing the public plotting API.
- Redesigning `LineageAxis`, layout geometry, recipes, or coordinate transforms.
- Fixing unrelated source or test changes already present in the working tree.
- Rewriting the full documentation site.
- Replacing the existing examples unless a later implementation task is
  explicitly authorized to do so.
- Claiming planned capacities as current features.
- Adding new Tier 2+ plotting features as part of README work.
- Adding file I/O or package adapters outside the current public surface.
- Registering the package in the General registry.
- Creating broad reference-package comparison tables in the roadmap.

## Open questions

1. **Exact README image location**
   **Owner**: Implementation tranche.
   **Suggested resolution**: Choose a maintainable location consistent with the
   existing repository layout, then keep scripts and generated images together
   or clearly cross-linked.

2. **Whether README snippets should be doctested or only script-verified**
   **Owner**: Implementation tranche.
   **Suggested resolution**: Prefer script-verified snippets for image-producing
   examples unless the documentation tooling already supports reliable README
   doctesting.

3. **Exact installation wording after registration**
   **Owner**: Maintainer.
   **Suggested resolution**: Keep current README wording explicit that the
   package is not yet registered. When registration happens, update the
   disclaimer rather than leaving both states ambiguous.

4. **Final breadth of the advanced recipe tour**
   **Owner**: Implementation tranche.
   **Suggested resolution**: Include every major feature requested by the user,
   but keep advanced recipes short and link to docs for exhaustive keyword
   details.

## Further notes

- Discovery included line-by-line inspection of the current `LineagesMakie.jl`
  source modules, current examples, tests, docs stub, design docs, workflow
  PRDs, and audit logs.

- Discovery found the README is currently a stub despite the implementation and
  tests covering a substantial Tier 1 feature surface.

- Discovery found the working tree already has local modifications in source,
  tests, and design documents. Downstream edits must preserve those changes.

- The current implementation supports more than the original Tier 1 PRD
  described in a few places. In particular, older workflow docs should be
  treated as historical when they conflict with the current implementation,
  tests, or controlled vocabulary.

- The roadmap should draw from `design/target-reference-capacities.md`, but it
  should be shorter, user-facing, and careful about current versus planned
  states.

- The README should make the package feel approachable without hiding its
  design strength: generic Julia inputs, Makie-native composition, controlled
  process-coordinate semantics, and layer-level composability.
