# Documentation Strategy

## Purpose

This repository should be readable by experienced engineers without requiring oral history from the original author. The documentation system exists to explain:

- what the system does
- why it is shaped that way
- where behavior is expected to live
- how contributors can extend it without breaking alarm reliability

## Documentation Standards

- Every important implementation choice must have a discoverable explanation.
- Narrative architecture docs explain system intent and boundaries.
- ADRs record specific high-impact decisions and their tradeoffs.
- Contributor docs define engineering expectations and review bars.
- Documentation should name constraints directly, especially Android platform constraints and OEM behavior risks.
- Documentation should prefer explicit invariants over broad aspirations.

## Documentation Taxonomy

### `README.md`

Use for project orientation:

- what the project is
- core principles
- where to go next

### `docs/architecture/engineering-story.md`

Use for the engineering narrative:

- why the app is Android-first
- why alarm-critical behavior is native
- why the system is local-first
- why the mission system is modular
- why specific tradeoffs were chosen for v1

This is the "story" future contributors should read before diving into code.

### `docs/architecture/overview.md`

Use for stable technical structure:

- subsystem boundaries
- data flow
- runtime responsibilities
- failure and recovery model
- public interfaces and extension points

### `docs/adr/*.md`

Use for decisions that should not be buried inside code review history:

- native vs Flutter ownership boundaries
- storage technology choices
- camera and analyzer pipeline choices
- scheduling semantics
- mission plugin contract changes
- permission strategy changes

### `docs/contributing/*.md`

Use for engineering process:

- coding standards
- testing expectations
- documentation update rules
- review expectations

## Update Rules

The same change set that modifies behavior should modify the relevant documentation.

Documentation updates are required when a change affects:

- alarm scheduling semantics
- ringing behavior or recovery behavior
- permissions or policy assumptions
- storage model or persisted state
- mission APIs or mission capability requirements
- extension points used by contributors
- user-visible guarantees described in docs

## Definition Of Done For Senior-Level Documentation

A change is not complete until:

- a new contributor can understand where the behavior lives
- a reviewer can see why the implementation approach was chosen
- the key invariants are written down
- relevant tradeoffs and non-goals are explicit
- tests and docs tell the same story

## Writing Style

- Prefer precise claims over marketing language.
- State constraints before presenting solutions.
- Separate stable architecture from point-in-time implementation details.
- Use ADRs for decisions; do not overload architecture docs with chronological debate.
- Keep examples minimal and realistic.
- Document extension seams as first-class API surfaces.

## Review Rule

If a pull request changes architecture and the reviewer cannot answer "why is it built this way?" from the repository alone, the documentation is incomplete.
