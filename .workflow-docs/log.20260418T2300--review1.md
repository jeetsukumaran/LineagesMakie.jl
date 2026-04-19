
A1/ OK
A2/ OK
A3/ No
A4/ Use `rootvertex`
B1/ Use `edgelength`
B2/ Use `edgelength`
B3/ OK
B4/ OK

C1/ OK
C2/ Use `edgelength`
C3/ Use `vertexvalue` ; update the PRD
C4/ Use `fromvertex`
C5/ Use `tovertex` 

D1/ OK
D2/ OK
D3/ Use `color`
D4/ OK

E1/ EdgeLayer/edgelayer! ;
E2/ VertexLayer/vertexlayer!; 
E3/ LeafLayer/ leaflayer!
E4/ LeafLabelLayer / leaflabelayer!
E5/ VertexLabelLayer / vertexlabellayer!
E6/ OK
E7/ OK

F1/ `vertex_positions`; update PRD
F2/ `edge_paths`
F3/ `leaf_order` is canonical
F4/ 'boundingbox' is canonical
F5/ see below
F6/ see below

(1) As with my decision with "branch..." above, we are sticking to `edge..` for internal consistency. Semantically, while this package is centered on phylogenetics, it can be used to model other systems as well.  As such, and regardless, we prioritize terms, abstractions, conventions, and concepts in the mathematical domain, though either way, we have to be explicit about it for clarity. Regardless of semantic logic, it makes no sense to special case some parts of the API, worst of all worlds. 

(2) Following from this broader support concept, in this case we center the UI on what the plot is doing rather than domain specific term such :cladogram, :phylogram

However, I am not sure your alternatives capture the range well enough:

- values given in or otherwise derived from data (either, user supplied, or in the tree data, or with user supplied fallbacks/defaults)
   - these might apply to edge lengths directly; and the case of ":equal", if interpreted strictly as "all edge lengths being equal", is just special case of this. Note that this does not neccessarily give a cladogram?
   - but the user / client code may also provide values that give the  "node" (vertex) *ages* (coalescent trees), where age >= 0. Here leaf ages can be 0 (sampled in the present), but may also be > 0. Edge lengths are derived from age differences between parent and children.

- values not given in data; these need to be calculated/inferred for the drawing logic
  - user wants a "cladogram"/"(phylogentic) topology" plot in which all leaves line up; and 
        - internal vertices line up in depth first order
        - internal vertices line up in level first order
        - something else?  

If there are any issues, bring it up for discussion.

Otherwise:

(0) save the original table *AND* my responses to a document,`.workflow-docs/log.20260418T2301--vocabulary.md

(1) Add `age` to the list of terms, based on my further responses below

(2) Update the document, the PRD, etc. to cleanly reflect the vocabulary that we decided here. In each, add a note that we shall be using the controlled vocabulary file at `.workflow-docs/00-design/controlled-vocabulary.md` which remains the authoritative list. In BOTH, do provide a summary list of key prefererd terms, brief definition, and proscribed by understood alternates: vertex, edge, seedvertex, length, height, depth, ages etc

(3) Then write another document in the design folder -- a vocabulary that essentially reproduces this matrix, but organized purely lexxically by canonical term, and with the idea that it can grow (or maybe be revised) as we need more terms controlled.  
Add a note to that this list is not exhaustive nor is it final, but it absolutely needs my approval if it is to be amended or ignored. If any agent needs clarification on coining a new term, they must discuss it with me before implementing anything, and after the decision, if it is appropriate and I agree or ask for it, the list can be updated.



 