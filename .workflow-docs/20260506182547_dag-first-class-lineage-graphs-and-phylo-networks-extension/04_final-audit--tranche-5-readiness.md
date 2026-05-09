# Audit report: DAG-first-class lineage graphs and `PhyloNetworks.jl` extension

Parent PRD: `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
Date: 2026-05-08
Files in scope: workflow chain plus the current implementation surfaces in `src/`, `ext/`, `test/`, `examples/`, `README.md`, `ROADMAP.md`, `docs/src/index.md`, `Project.toml`, and `test/Project.toml`

## Summary

The implementation is structurally close to the planned tranche-4 end state and is broadly ready to start tranche 5. The live package now has a DAG-capable core, an optional `PhyloNetworks.jl` extension, honest rooted full-network scope boundaries, and explicit tranche-5 work still missing in exactly the places the tranche file predicts: projected-tree or major-tree view modes and semidirected or unrooted display policy.

Tranche 5 is still the product-completion tranche for the planned Tier-3 network surface, but it is not sufficient by itself to declare the whole effort complete under the active authorities. A public vocabulary conflict already survives in the live API and docs, and one parent workflow artifact still carries stale tranche-4 verification and current-state claims that a fresh tranche-5 agent could misread unless they are corrected or explicitly superseded.

## Handoff integrity

The surviving handoff chain is mostly honest about the architecture boundary: the parent PRD, tranche file, README, docs, roadmap, code, tests, and example all agree that current direct `HybridNetwork` support is rooted full-network only and that projected-tree or major-tree view modes plus semidirected or unrooted policy remain deferred.

Two drift points survive:

1. The controlled vocabulary authority ratifies `node_coordinates` and `:node_coordinates`, while the live public API, docs, tests, design docs, and older workflow artifacts still use `nodecoordinates` and `:nodecoordinates`.
2. The tranche file still carries a stale tranche-4 environment rule and stale tranche-5 red-state prose that were later revalidated and corrected in the tranche-4 tasking, but were never folded back into the higher-level tranche artifact.

## Critical findings

None.

## High findings

### 1. The authoritative vocabulary and the live public explicit-coordinate API disagree

**Location**: `STYLE-vocabulary.md:679-680`, `STYLE-vocabulary.md:1227`, `STYLE-vocabulary.md:1279`, `src/Accessors.jl:26-27`, `src/Accessors.jl:43`, `src/Accessors.jl:50`, `src/Accessors.jl:65`, `src/Accessors.jl:83`, `README.md:241`, `README.md:324`

**Category**: Consistency

**Problem**: The ratified vocabulary requires `node_coordinates` and `:node_coordinates`, but the live API, docs, tests, design docs, and workflow chain still expose `nodecoordinates` and `:nodecoordinates`. This is no longer a wording nit: it is a public-contract conflict between the governing vocabulary and the implementation. Because the accessor name and `lineageunits` symbol are user-facing, fixing the conflict now requires either a vocabulary amendment or a compatibility-and-migration plan rather than a silent search-and-replace.

**Suggestion**: Resolve the conflict explicitly before calling the effort complete. Either ratify the existing public API in `STYLE-vocabulary.md`, or add compatibility aliases plus migration notes and then move the public contract to the ratified spelling. If tranche 5 is meant to deliver the full governed product, this item should be added to its lock set or handled in a short prerequisite remediation.

## Medium findings

### 1. The tranche file still carries stale verification and current-state instructions that conflict with the revalidated tranche-4 tasking

**Location**: `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md:799-805`, `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md:1003-1009`, `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md:1034-1036`, `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md:67-71`, `test/Project.toml:7`, `test/Project.toml:12`

**Category**: Architecture

**Problem**: The tranche file still says extension-absence verification must run in the checked-in `test/Project.toml` environment without `PhyloNetworks.jl` present there, but that environment now explicitly includes a local `PhyloNetworks.jl` source. The tranche-4 tasking already revalidated this and corrected the rule to use a temporary-project or subprocess absence probe instead. The tranche-5 handoff section in the tranche file also still frames the current red state as if docs and roadmap permit an adapter reading, which the live `README.md`, `ROADMAP.md`, and `docs/src/index.md` no longer do.

**Suggestion**: Refresh `02_tranches.md` or create tranche-5 tasking that explicitly supersedes these stale points in its handoff packet before implementation starts. The goal is not to reopen design, only to keep the parent artifact honest enough that a fresh tranche-5 agent does not inherit false failure modes or impossible verification instructions.

## Low findings

### 1. The docs build is green but still warns that `index.md` exceeds the configured Documenter size warning threshold

**Location**: `docs/src/index.md`

**Category**: Best practices

**Problem**: The current docs build completes successfully, but it emits a `size_threshold_warn` warning for the generated `index.html`. Repo style guidance already says Documenter pages should be broken up to stay within warning limits, so this is a small but real documentation-maintenance gap.

**Suggestion**: Fold some of the index-page material into one or more focused docs pages while tranche 5 is already touching docs, examples, and roadmap surfaces.

## No findings

- No critical or high architecture finding was found in the tranche-4 owner boundary itself. The code, docs, and example all honestly advertise rooted full-network scope only, and the live extension does not pretend to offer projected-tree, semidirected, or unrooted network behavior yet.
- No shadow-owner drift was found in the extension boundary. `Project.toml` keeps `PhyloNetworks.jl` in `[weakdeps]`, the extension lives in `ext/PhyloNetworksExt.jl`, and the direct entrypoint explicitly states that projected-tree and non-rooted policy remain deferred.
- The current tranche-5 gap is real and well-localized. The remaining missing product surface is the explicit network view-mode and display-policy layer described in `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md:940-969` and reflected in the current README, docs, and roadmap.

## Overall assessment

Are we ready for tranche 5: yes, conditionally. The implementation appears structurally ready to move into tranche 5 because tranche 4's rooted full-network foundation is present and honestly bounded, and the missing work still matches the tranche-5 contract rather than exposing a hidden tranche-2 or tranche-3 architecture hole.

Will tranche 5 deliver the product: it will deliver the planned Tier-3 network product only if it lands the explicit projected-tree or major-tree mode plus the required display-policy surface and closes with the required render-level proofs. It will not, by itself, make the whole effort cleanly complete under the current authorities unless the explicit-coordinate vocabulary conflict is also resolved and the stale tranche-file handoff points are corrected or superseded.

## Verification notes

- `julia --project=docs docs/make.jl` completed successfully during this audit, with one size-threshold warning on `docs/src/index.md`.
- `julia --project=test test/runtests.jl` was started as the canonical test gate but had not completed before the audit cutoff, so this report does not claim a full-suite green result.
