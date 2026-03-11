# Engineering Standards

## Principle

This project should feel predictable to a senior engineer reading it for the first time. That requires explicit boundaries, disciplined change scope, and documentation that keeps pace with implementation.

## Reliability Rules

- Alarm delivery and ringing logic are reliability-critical. Treat them as systems code.
- Do not move alarm-critical behavior into Flutter for convenience.
- Prefer explicit failure handling over optimistic control flow.
- Persist enough state to recover an active ring session after process death.
- Treat OEM-specific Android behavior as a first-class testing concern.

## Boundary Rules

- Flutter owns UI composition, editor flows, and non-critical state presentation.
- Native Android owns scheduling, service lifecycle, wake behavior, and frame analysis.
- Missions extend through stable contracts. They should not reach into scheduler internals.
- Vision missions consume analyzer results, not arbitrary camera access from multiple layers.
- Startup-time Flutter code must be treated as direct-boot-sensitive. Do not add eager plugin initialization or unlocked-only assumptions to `main.dart` or root app bootstrap code without documenting and verifying them.

## Testing Expectations

- New scheduling or ringing behavior requires unit coverage for rules and integration coverage for bridge behavior.
- Changes that affect platform behavior should include an explicit manual test note if automation is not sufficient.
- Device-specific reliability claims should not be made without testing on more than one OEM family.

## Documentation Expectations

- Update docs in the same change that updates behavior.
- Add or revise an ADR for high-impact architecture changes.
- If a contributor would need code archaeology to understand a new boundary, the documentation is incomplete.
- Keep architecture docs stable and move one-off trade studies into ADRs.

## Review Expectations

- Review for invariants first, implementation style second.
- Reject changes that blur subsystem ownership without justification.
- Reject undocumented behavior changes in alarm scheduling, wake handling, permissions, persistence, or mission APIs.
- Prefer boring, explainable correctness over clever abstractions.

## Contribution Quality Bar

A contribution is ready when:

- the behavior is understandable
- the ownership boundary is obvious
- the tradeoffs are documented
- the tests match the stated guarantees
- a future contributor can extend it without guessing
