# 0010 Performance Tooling And QR Dependency Tradeoff

## Status

Accepted

## Context

By March 11, 2026, NeoAlarm had reached the point where ad hoc performance inspection was no longer enough.

We already had:

- source-level optimization work in the active-session and vision pipeline
- manual `adb` timing and memory checks
- release-build smoke validation

What we did not yet have was a repeatable in-repo performance workflow that contributors could run without reinventing the commands every time.

At the same time, the device audit exposed small recurring `com.google.android.datatransport.runtime` jobs while the app was idle. That raised an important question: was the alarm engine doing unexpected background work, or was the QR dependency stack responsible?

## Decision

The repository will carry an explicit Android performance toolchain:

- a Macrobenchmark module under `android/benchmark`
- a manual Perfetto capture script under `scripts/android`
- a dependency-audit script that proves where the DataTransport jobs come from

The target app will also pin:

- `androidx.profileinstaller:profileinstaller:1.4.1`

so the benchmark harness works correctly on the current Android test device.

The app will keep a dedicated `benchmark` build type that is:

- release-like
- non-debuggable
- debug-signed for local installation
- not minified
- not shrink-resources

The shell-profiling manifest hook (`android:profileable="shell=true"`) will live only in the benchmark target manifest, not in the shipped app manifest.

The repository will continue to validate the real minified `release` APK separately.

For the QR mission dependency tradeoff, the project accepts the current ML Kit barcode stack for now, even though it pulls in:

- `com.google.android.datatransport:transport-runtime`
- `com.google.android.datatransport:transport-backend-cct`

That dependency-level background work is documented and monitored rather than treated as a blocker at the current project stage.

## Consequences

Positive:

- contributors have a repeatable cold-start benchmark flow
- traces are produced automatically as part of the benchmark run
- manual trace capture is scripted instead of tribal knowledge
- dependency-origin questions can be answered from Gradle output rather than inference
- benchmark results on modern Android are stable because `profileinstaller` is explicit

Tradeoffs:

- the benchmark target does not perfectly match the minified release packaging pipeline
- the QR mission continues to carry a small dependency-level background-work cost
- the repository now has more Android-specific tooling to maintain

## Alternatives Considered

### Benchmark Only With Ad Hoc `adb` Commands

Rejected.

Useful for quick local checks, but too weak as a long-term contributor workflow.

### Benchmark The Exact Minified `release` Variant

Rejected for now.

The real release artifact is still validated separately, but the synthetic `benchmark` build type needs to stay stable for repeated local measurements. The benchmark-specific build variant was hitting avoidable plugin and shrinker instability.

### Remove ML Kit Immediately To Eliminate DataTransport

Rejected for now.

The QR mission is already implemented and working well. The observed DataTransport jobs are small, and there is not yet enough evidence to justify ripping out the scanner stack before the rest of the roadmap matures.
