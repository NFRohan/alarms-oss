# 0006: Security Hardening And Release Pipeline

## Status

Accepted

## Context

The project is local-first and currently Android-only, but that does not make its security posture simple.

This app can:

- wake the screen
- present full-screen UI over the lock screen
- schedule privileged future work through exact alarms
- persist alarm definitions and mission state locally
- publish installable artifacts for other people to put on real devices

A security review identified four concerns that affect architecture rather than just implementation detail:

1. the exported launcher activity could trust a forgeable action string to enable alarm-style lock-screen behavior
2. app-private alarm and mission data could still leak through Android backup defaults
3. the exported reschedule receiver did not constrain caller intent tightly enough
4. release builds still depended on debug signing behavior

At the same time, the repository was ready for CI, but the CI model needed to include security checks and a controlled release path rather than only build verification.

## Decision

The project adopts the following policy:

### Full-Screen Alarm UI Is Authorized By Persisted Active Session State

The app must not trust an incoming activity action string as proof that alarm-only window flags should be enabled.

The lock-screen/full-screen alarm presentation is authorized only when persisted native session state says an alarm is active.

### Auto-Backup Is Disabled For MVP

Android auto-backup is disabled at the application level.

This keeps the MVP privacy posture aligned with the project's local-first promise while persistence still relies on app-private local storage.

### Exported Reschedule Paths Are Narrow And Defensive

The exported reschedule receiver only honors the expected system actions:

- boot completed
- package replaced
- time changed
- timezone changed

Reschedule attempts are treated as defensive maintenance work rather than trusted caller workflows. Failures should not become crash paths.

### Release Signing Is Local-File Driven With Debug Fallback

Gradle reads release signing material from a local `android/key.properties` file that is ignored by Git.

If the file does not exist, release builds fall back to the debug signing config so:

- local development remains simple
- CI can still build release artifacts
- the repo does not require embedded signing secrets

Real public release signing is expected to come from local developer setup or CI secrets materialized at build time.

### CI Includes Security Scanning And Tagged Release Publishing

GitHub Actions is part of the security posture, not just the build loop.

The repository now uses:

- build/test CI for analysis, tests, and APK artifacts
- CodeQL for SAST on Android code and workflow code
- dependency review on pull requests for dependency-risk changes
- a tagged release workflow that builds a release APK and publishes it to GitHub Releases

## Consequences

### Positive

- external callers cannot enable alarm-style lock-screen behavior just by forging an intent action
- local alarm and mission data no longer quietly participates in Android backup flows
- the exported reschedule surface is less permissive and less fragile
- release engineering now has an explicit path from local signing to CI signing
- security scanning becomes part of normal repository maintenance instead of an occasional manual event

### Negative

- disabling backup removes a convenience path for device migration until a deliberate import/export system exists
- release-mode builds without real signing material are still possible, but they are not suitable for public distribution
- CI complexity increases because security and release workflows are now first-class

## Alternatives Considered

### Keep Trusting The Internal Alarm Action

Rejected because action strings are not a strong enough trust boundary for an exported activity.

### Keep Android Backup Enabled And Document The Risk

Rejected for MVP because it conflicts with the current privacy posture and would be easy for contributors to forget.

### Require Signing Secrets For All Release Builds

Rejected because it would make CI and local verification unnecessarily fragile in early development.

### Postpone Security Scanning Until Public Launch

Rejected because the cost of wiring it in early is low compared with the cost of retrofitting it after the repository and release process have already grown.
