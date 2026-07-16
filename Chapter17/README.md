# Chapter 17 — Visitor Pattern: From GoF to Production Compilers

The 23 examples in [`src/`](src/) walk through the Visitor pattern and its many C++
refinements. This note connects them to where visitors matter most in practice —
**compilers and JIT compilers** — and to the most instructive industrial
counter-example: **LLVM/MLIR**, a 20-million-line compiler codebase that
deliberately avoids the classic visitor, yet re-implements its *idea* three
different ways. Reading the chapter's variants side by side with LLVM's choices
shows *why* each refinement exists.

---

## 1. The problem: double dispatch over a heterogeneous tree

A compiler's central data structure is an AST (abstract syntax tree): a tree of
nodes of *different concrete types* (`NumberExpr`, `BinaryExpr`, `CallExpr`, …)
held through a common base pointer (`Expr*`). The compiler must run **many
different operations** over that one tree:

- type checking
- constant folding / optimization
- pretty printing
- code generation (in a JIT: emitting IR or machine code directly)

Each operation must do something different per node type. The behavior depends
on **two** runtime facts — *which operation* and *which node type* — but C++
virtual functions dispatch on only one receiver. That is the **double dispatch**
problem, and it is the problem every file in this chapter is solving.

The naive fix is a virtual method per operation on every node
(`node->typecheck()`, `node->codegen()`, …). The LLVM *Kaleidoscope* tutorial
does exactly this with a virtual `codegen()`. It works, but it scatters each
pass's logic across every node class and forces an edit to every AST header for
each new pass. The Visitor pattern inverts this:

- nodes get one `accept(Visitor&)` method, forever;
- each pass becomes one self-contained class (`TypeChecker`, `CodeGenVisitor`)
  with a `visit(BinaryExpr&)`, `visit(NumberExpr&)`, … overload set;
- `accept()` calls `v.visit(*this)` on the concrete type — double dispatch
  resolved through two virtual calls.

In the **expression problem** framing: a data abstraction has two axes of
extension — new *types* and new *operations* — and mainstream languages let you
open only one axis at a time.

| | add a new **operation** | add a new **type** |
|---|---|---|
| virtual method per operation (OO style) | touch every node class 😖 | one new class 😊 |
| **Visitor** (per-pass class) | one new class 😊 | touch every visitor 😖 |

A compiler's node set is fixed by the language grammar while its pass set grows
forever — exactly the corner where Visitor shines. This is why visitors are the
standard AST API in **javac** (`TreeVisitor`), **Roslyn/C#**
(`CSharpSyntaxVisitor`), **Babel** (plugins *are* visitor objects), and
**ANTLR** (generates visitor scaffolding for every grammar). In a JIT there is
nothing extra: the codegen visitor's `visit` methods emit IR or machine code
instead of text, and a JIT often carries several such walkers (one to
interpret, one to compile).

---

## 2. The chapter's variants, one by one

| Files | Variant | Dispatch mechanism | The refinement it adds |
|---|---|---|---|
| — (the §1 baseline) | Virtual method per operation (no visitor) | 1× virtual call on the node | The starting point, not a refinement — simplest possible, but every new pass edits every node class |
| [`01`](src/01_visitor.cc)–[`03`](src/03_visitor.cc) | Classic GoF visitor | 2× virtual call (`accept` → `visit`) | Virtual `accept()` + virtual `visit()`; the baseline double dispatch |
| [`04_visitor_args`](src/04_visitor_args.cc), [`05_visitor_retval`](src/05_visitor_retval.cc) | Arguments & results | same, results carried as visitor state | `accept()`/`visit()` have fixed signatures, so per-call inputs and outputs must travel as visitor state (or via `dynamic_cast` tricks) |
| [`06_container_visitor`](src/06_container_visitor.cc), [`07_composite_visitor`](src/07_composite_visitor.cc) | Traversal integration | visitor- or structure-driven walk | Who walks the children — the visitor or the structure? (Both answers appear in real compilers) |
| [`08`](src/08_serialization_visitor.cc)/[`09`](src/09_serialization_visitor.cc), [`19`](src/19_serialize_visitor.cc)/[`20`](src/20_serialize_visitor.cc) | Serialization visitors | (application of the above) | A full *application*: one operation (save/load) packaged as one visitor class — the "pass = class" payoff |
| [`10`](src/10_acyclic_visitor.cc), [`15`](src/15_acyclic_visitor.cc)–[`17`](src/17_acyclic_visitor.cc) | **Acyclic visitor** | `dynamic_cast` capability probe | Breaks the "visitor base must list every node type" dependency cycle: each node gets its own tiny visitor interface, and `accept()` probes with `dynamic_cast` whether the arriving visitor implements it |
| [`11`](src/11_visitor_template.cc), [`12`](src/12_visitor_template.cc) | Template/CRTP visitor | CRTP-stamped `accept()`, dispatch moved toward compile time | `Visitable<T>` CRTP base stamps out `accept()`; removes per-node boilerplate |
| [`13`](src/13_visitor_lambda.cc), [`14`](src/14_visitor_lambda_tuple.cc) | Lambda visitor | inline per-type handlers | Build a visitor inline from lambdas, one per type — a throwaway pass without a named class |
| [`18_static_visitor`](src/18_static_visitor.cc) | Compile-time visitor | compile-time overload resolution, no virtual calls | Dispatch fully resolved at compile time; no `accept()` machinery at all |
| [`21`](src/21_visitor_variant.cc)–[`23`](src/23_visitor_variants.cc) | `std::variant` + `std::visit` | switch on a stored index tag | The closed type set becomes a *sum type*; the hidden variant index replaces the vtable, `std::visit` replaces `accept()` |

### How each variant maps onto real compiler infrastructure

This mapping is a **preview of §3 and §4**, placed here so each variant is tied
to its industrial counterpart while the variant is fresh. Read it once now for
orientation; the *mechanics* behind the right-hand side — LLVM's kind tags and
`isa<>`/`dyn_cast<>` casting, its CRTP visitors, `llvm::TypeSwitch`, and MLIR
interfaces — are unpacked in §3, and the constraint that shapes all of them
(LLVM builds with `-fno-rtti`, so `dynamic_cast` does not exist there) is
examined in §4.

The first half of the list needs no forward references — these variants appear
in real compilers essentially as the chapter presents them:

- **Virtual method per operation** (the §1 baseline) — the LLVM *Kaleidoscope*
  tutorial's virtual `codegen()` on every AST node; classic tree-walking
  interpreters (`node->eval()`). Fine for a tree with one or two consumers;
  every new pass edits every node class.
- **Classic GoF visitor** (`01`–`03`) — javac `TreeVisitor`, Roslyn
  `CSharpSyntaxVisitor`, Babel plugin objects, ANTLR-generated visitors.
  These are ecosystems with a spec-frozen node set and unbounded third-party
  passes — the visitor's sweet spot, and virtual double dispatch is idiomatic
  in those (mostly managed-language) codebases. Conspicuously, LLVM is *not*
  on this list — §3 explains why.
- **Traversal integration** (`06`–`07`) — Clang `RecursiveASTVisitor`, MLIR
  `Operation::walk()`. Both bundle "walk the children" together with per-node
  dispatch — the exact visitor-vs-structure question these two files pose.
- **Serialization visitors** (`08`–`09`, `19`–`20`) — the "one pass = one
  class holding its own state" shape of every compiler pass; e.g. the Toy
  tutorial's `MLIRGen` class owns the IR builder and symbol table exactly the
  way these files' visitors own their stream.

The second half is where §3 and §4 take over: each of these variants exists in
LLVM either *transformed by* the no-RTTI constraint or *because of* it:

- **Arguments & results** (`04`–`05`) — these files show the pain of the fixed
  `accept()`/`visit()` signature. LLVM's CRTP form (§3, consequence 2)
  dissolves that pain: `llvm::InstVisitor<SubClass, RetTy>` makes the result
  type a template parameter, and Toy's `mlirGen` overloads simply return
  `mlir::Value` / `LogicalResult` — natural signatures, because plain
  overloads replace the inherited virtual interface.
- **CRTP / static visitor** (`11`–`12`, `18`) — `llvm::InstVisitor`, Clang
  `StmtVisitor`/`TypeVisitor`, MLIR `AffineExprVisitor`. This is LLVM's
  *preferred* visitor form; §3 (consequence 2) shows how it keeps the
  pattern's organization while swapping the dispatch underneath for a
  kind-tag switch.
- **Lambda visitor** (`13`–`14`) — `llvm::TypeSwitch`, used e.g. for the MLIR
  Toy tutorial's AST dumper (§3, consequence 3). Same idea, but the per-type
  probe inside `.Case<T>()` is LLVM's `dyn_cast<>`, not RTTI.
- **`std::variant` + `std::visit`** (`21`–`23`) — LLVM's **kind-tag
  dispatch**: a `getKind()` enum + `switch`, with `isa<>`/`dyn_cast<>`
  implemented via per-class `classof()` predicates (§3, consequence 1; §4
  explains the machinery). A hand-rolled variant for objects that must live
  in pointer-linked trees — and the direct *replacement* for RTTI under
  `-fno-rtti`.
- **Acyclic visitor** (`10`, `15`–`17`) — the one variant LLVM **cannot use as
  written**: its engine is a `dynamic_cast` capability probe, and §4's
  `-fno-rtti` removes `dynamic_cast` from the language. Its *job* — "each
  node type opts in, no central handler list" — survives as **MLIR operation
  interfaces**, which re-found the same probe on explicit registration tables
  (§3, "And the acyclic visitor's job?").

The punchline of this mapping: the chapter enumerates the design space in
isolation; LLVM shows which points in that space survive contact with an
enormous codebase built under `-fno-rtti` (CRTP visitors, lambda type-switches,
kind tags) and which had to be **re-founded on different mechanics** (acyclic
visitor → interfaces).

Two of these deserve a closer look, because they are the two that industrial
compilers actually argue about.

### The acyclic visitor (10, 15–17): openness bought with RTTI

The classic visitor has a nasty coupling: the abstract `Visitor` base must
declare a `visit()` overload for **every** node type, so adding one node type
recompiles the world and touches every pass. The acyclic visitor
(Alexandrescu/Martin) fixes this by splitting the visitor interface per node
type (`CatVisitor`, `DogVisitor`, …) and letting `accept()` discover at runtime
— via `dynamic_cast` — whether the visitor that arrived cares about this node:

```cpp
void Cat::accept(PetVisitor& v) override {
    if (CatVisitor* cv = dynamic_cast<CatVisitor*>(&v))
        cv->visit(this);
    // else: this visitor doesn't handle cats — fall through / default
}
```

Now node types and passes are decoupled — but the engine of that decoupling is
**RTTI**, and a cross-cast (`PetVisitor*` → `CatVisitor*`, siblings in the
hierarchy) at that, which is the slowest form of `dynamic_cast`. Keep this
trade in mind for §3: it is the one variant in this chapter that LLVM *cannot*
use as written.

### The variant visitor (21–23): the kind tag made explicit

`std::variant<Cat, Dog, ...>` stores a small integer saying which alternative
is live; `std::visit` switches on it and calls the matching overload/lambda.
Notice what happened: **the type tag moved out of the vtable and into plain
data**, and dispatch became an ordinary switch. The set of alternatives is
closed and centrally listed — the same trade as the classic visitor's overload
list, but with value semantics, no inheritance, and no heap indirection.

Hold that thought: a hand-rolled version of exactly this mechanism is how LLVM
dispatches over its AST-like hierarchies.

---

## 3. Case study: why LLVM/MLIR avoids the classic visitor

LLVM builds with `-fno-rtti` (see §4), so `dynamic_cast` does not exist there.
Instead, every hierarchy carries a **kind tag** — a small enum returned by
`getKind()` — and LLVM's own casting machinery (`isa<>`, `dyn_cast<>`,
`cast<>`) works through a per-class `classof()` predicate that checks the tag.
Given that machinery, three consequences follow:

1. **The second virtual call of the visitor pattern is redundant.** If every
   object already carries a cheap integer identifying its concrete type,
   `switch (node->getKind())` resolves the dispatch in one comparison — no
   `accept()` in the nodes, no visitor base class. This is `std::visit`
   re-derived, for objects that must live in pointer-linked trees.

2. **The visitor *organization* survives as CRTP.** LLVM did not abandon the
   pattern's real value — one pass = one class, one handler per node type — it
   kept exactly that shape in `llvm::InstVisitor`, Clang's `StmtVisitor` and
   `RecursiveASTVisitor`, and MLIR's `AffineExprVisitor`, with the dispatch
   underneath being a compile-time kind-switch instead of virtual double
   dispatch. Zero runtime overhead, unhandled cases fall through to a default,
   and the node classes need no cooperation at all. These are this chapter's
   files `11`/`12`/`18`, industrialized.

3. **For throwaway passes, `llvm::TypeSwitch` is the lambda visitor.** One
   inline chain of `.Case<ConcreteType>(lambda)` handlers — this chapter's
   files `13`/`14`, minus the boilerplate:

   ```cpp
   llvm::TypeSwitch<ExprAST *>(expr)
       .Case<BinaryExprAST, CallExprAST, NumberExprAST /*...*/>(
           [&](auto *node) { this->dump(node); })
       .Default([&](ExprAST *) { llvm::errs() << "<unknown Expr>\n"; });
   ```

### And the acyclic visitor's job? Interfaces.

MLIR has a genuinely **open** set of node types: anyone can define a new
dialect with new operations, and a pass will routinely encounter ops it has
never heard of. No visitor variant with a closed handler list can serve that
world — and the acyclic visitor, the chapter's answer to openness, runs on the
`dynamic_cast` that `-fno-rtti` removed. MLIR's replacement is **operation
interfaces**: an op *registers* that it implements, say,
`ShapeInferenceOpInterface`, and a pass asks
`dyn_cast<ShapeInferenceOpInterface>(op)` — same capability-probe idea as
`10_acyclic_visitor.cc`, but the probe consults MLIR's registration tables
instead of RTTI, and (unlike `dynamic_cast`) it can succeed even though the
interface is **not a base class** of the op at all. `RewritePattern`s
complete the picture: a pass declares which ops it matches and ignores the
rest, which is the acyclic visitor's "fall through silently" semantics at
ecosystem scale.

### Concrete example: the MLIR Toy tutorial

The official MLIR *Toy* tutorial (a 7-chapter build-a-compiler walkthrough) is
a nice compressed tour of these choices:

- Its AST dumper dispatches with `llvm::TypeSwitch` — the **lambda visitor**.
- Its code generator, `MLIRGen`, is one class holding the IR builder and the
  symbol table — a **codegen visitor** in shape — but dispatches with a plain
  `switch (expr.getKind())` into overloaded `mlirGen(BinaryExprAST&)`,
  `mlirGen(CallExprAST&)`, … — the **variant/kind-tag** approach.
- No `accept()`, no visitor base class anywhere: the AST is tiny, has exactly
  two consumers, and is deliberately short-lived — after chapter 2 the program
  lives as MLIR, where **patterns and interfaces** take over the visitor's job.

Why not the classic visitor even there? Because the tutorial follows LLVM house
style (kind tags already exist for casting), the AST's node set is essentially
frozen (visitor's extensibility buys nothing), and building `accept()`
infrastructure for two consumers is ceremony that would obscure the actual
lesson.

---

## 4. `-fno-rtti`: what it is, and its trade-offs

Since it decides which half of this chapter is even *available* to LLVM, the
flag deserves a precise treatment.

**What RTTI is.** Run-Time Type Information is the C++ machinery behind
`dynamic_cast` and `typeid`. For every polymorphic class the compiler emits a
`std::type_info` object — including the mangled class-name string — and plants
a pointer to it in the vtable. `dynamic_cast<D*>(b)` then walks the inheritance
graph at runtime comparing `type_info` identities; across shared-library
boundaries some ABIs must fall back to *comparing the name strings*.

**What `-fno-rtti` does.** The compiler stops emitting `type_info` objects;
`dynamic_cast` and `typeid` become ill-formed (a `dynamic_cast` that could be
resolved statically is still allowed). Virtual functions and vtables are
**unaffected** — only the type-identification metadata disappears. It is a
different flag from `-fno-exceptions`, though the two usually travel together
(exception handling also consults type metadata to match `catch` clauses, so
codebases hunting the same overheads tend to disable both — LLVM does).

### Why a codebase turns it off (pros)

- **Binary size.** A `type_info` + name string per polymorphic class,
  replicated across hundreds of libraries, is real megabytes at LLVM scale.
  This was the original motivation.
- **Dispatch cost.** `dynamic_cast` is a runtime graph walk (worst case:
  string comparisons); the cross-cast the acyclic visitor needs is its most
  expensive form. LLVM's `isa<>`/`dyn_cast<>` via `classof()` is a
  constant-time integer comparison.
- **Works without vtables entirely** — the subtle big one. RTTI functions only
  on polymorphic objects (the vptr is how you *find* the `type_info`).
  Kind-tag casting needs only the tag field, so classes like MLIR's `Type`,
  `Attribute`, and operation handles can be lightweight **vtable-free value
  types** — no 8-byte vptr on each of millions of IR objects — and still
  support `dyn_cast`.
- **Richer cast semantics.** `classof()` is arbitrary code: a kind-*range*
  check (`K >= FirstBinaryOp && K <= LastBinaryOp`), a registry lookup, a
  trait query. RTTI can only ever answer "is-a via inheritance"; LLVM-style
  casting can answer "supports this interface" even when no inheritance
  relationship exists.

### The costs (cons)

- **Hand-maintained machinery.** The kind enum, `getKind()`, and every
  `classof()` are written by humans. A wrong `classof()` makes `cast<>`
  silently produce a bogus pointer — undefined behavior with no safety net.
- **Closed-hierarchy pressure.** A central kind enum means every new node type
  touches the enum and every exhaustive `switch`. (Compiler warnings on
  non-exhaustive enum switches recover much of the safety — the visitor
  pattern's "missing overload" compile error, approximated.)
- **Ecosystem friction.** Anything built on RTTI is unavailable: the acyclic
  visitor as written in this chapter, `boost::any`-style facilities, several
  serialization and dependency-injection frameworks. `std::any`'s `any_cast`
  is specified in terms of `typeid`, so its behavior under `-fno-rtti` is
  implementation-defined at best.
- **ABI mixing hazards.** Linking `-fno-rtti` code with RTTI-expecting code
  works only until someone `dynamic_cast`s or `typeid`s across the boundary —
  a classic source of baffling errors for LLVM *plugin* authors, whose builds
  must match LLVM's flags.

**One-line summary:** `-fno-rtti` trades a built-in, inheritance-only,
per-object-costly type-identification mechanism for a hand-rolled one that is
smaller, faster, works on vtable-free objects, and answers richer questions —
at the price of maintaining it yourself and forgoing every library and pattern
(acyclic visitor included) that assumed the built-in one exists.

---

## 5. Choosing a variant — a field guide

- **One or two operations, ever** (a small interpreter, a config-tree
  evaluator): skip the pattern — a virtual method per operation
  (Kaleidoscope-style `codegen()`) is simpler than any visitor and fine at
  that scale.
- **Node set frozen by a spec, passes written by strangers** (language
  tooling APIs): classic visitor (`01`–`05`) — its rigidity *is* the API
  stability guarantee.
- **You control everything and want zero overhead**: CRTP/static visitor
  (`11`, `12`, `18`) — the LLVM `InstVisitor` shape.
- **Throwaway or single-use pass**: lambda visitor (`13`, `14`) or
  `llvm::TypeSwitch`; don't build a class hierarchy for one dump function.
- **Closed set of value types, no inheritance needed**: `std::variant` +
  `std::visit` (`21`–`23`); if the objects must live in pointer-linked graphs,
  the hand-rolled kind tag is the same design.
- **Open, plugin-extensible type set**: acyclic visitor (`10`, `15`–`17`) if
  RTTI is available — otherwise you need an explicit capability registry, i.e.
  you will end up reinventing MLIR interfaces.

The pattern's dispatch *mechanism* is negotiable — virtual double dispatch,
CRTP, `switch` on a tag, `std::visit`, registry lookup. The pattern's
*organization* — one operation, one place, one handler per type it cares about
— is the part every serious codebase keeps.

---

## Further reading

- [MLIR Toy tutorial](https://mlir.llvm.org/docs/Tutorials/Toy/) — the
  worked example referenced in §3 (see also its chapter on
  [interfaces](https://mlir.llvm.org/docs/Tutorials/Toy/Ch-4/)).
- [LLVM Programmer's Manual — `isa<>`, `cast<>`, `dyn_cast<>`](https://llvm.org/docs/ProgrammersManual.html#the-isa-cast-and-dyn-cast-templates)
- [How to set up LLVM-style RTTI](https://llvm.org/docs/HowToSetUpLLVMStyleRTTI.html)
- [LLVM Coding Standards — RTTI and exceptions are off](https://llvm.org/docs/CodingStandards.html#do-not-use-rtti-or-exceptions)
- [MLIR Interfaces](https://mlir.llvm.org/docs/Interfaces/)
- Robert C. Martin, *Acyclic Visitor* (the original paper behind files
  `10`/`15`–`17`).
