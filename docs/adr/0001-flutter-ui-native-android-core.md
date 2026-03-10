# ADR 0001: Flutter UI With Native Android Alarm Core

- Status: Accepted
- Date: 2026-03-11

## Context

The project is a Flutter app, but the product promise depends on Android-specific behavior:

- exact alarm scheduling
- wake-from-idle delivery
- foreground ringing
- lock-screen launch
- recovery after process death

Building those responsibilities primarily in Flutter would create avoidable failure modes and blur the boundary between presentation code and reliability-critical code.

## Decision

Use Flutter for UI, alarm editing, and mission presentation. Use native Android components in Kotlin for:

- exact scheduling
- alarm broadcasts
- foreground ringing service
- session persistence and recovery
- lock-screen/full-screen launch

The native layer is the source of truth for active ringing state.

## Consequences

- Alarm reliability is less dependent on Flutter runtime state.
- Android-specific implementation complexity is accepted early instead of hidden.
- Cross-platform portability is reduced, but system correctness improves.
- Contributors must understand both Flutter and Android boundaries, so documentation must make ownership explicit.

## Alternatives Considered

- Flutter-first alarm engine with plugin support
- Full native Android app with no Flutter shell

The Flutter-first approach weakens the reliability boundary. The full native approach reduces UI development velocity and makes later cross-platform reuse less practical.
