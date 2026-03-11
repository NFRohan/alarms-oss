# Performance Workflow

## Summary

NeoAlarm now has a repeatable Android performance toolchain in-repo:

- Macrobenchmark for cold-start timing on a real device
- Perfetto capture scripts for manual trace collection
- a dependency-audit script to prove where unexpected Android background work comes from

This workflow exists because one-off `adb` checks are useful, but they are not enough once performance work becomes part of the engineering bar.

## What Exists

### Macrobenchmark Module

Location:

- `android/benchmark`

Purpose:

- measure repeatable real-device cold startup
- emit machine-readable benchmark metrics
- emit per-iteration Perfetto traces

Current benchmark:

- `StartupBenchmark.coldStartup`

Run it with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/android/run_macrobenchmark.ps1
```

Outputs land under:

- `build/benchmark/reports/androidTests/connected/benchmark`
- `build/benchmark/outputs/connected_android_test_additional_output/benchmark/connected/<device>`

Important output files:

- `dev.neoalarm.app.benchmark-benchmarkData.json`
- `additionaltestoutput.benchmark.message_*.txt`
- `StartupBenchmark_coldStartup_iterXXX_*.perfetto-trace`

### Perfetto Capture Script

Location:

- `scripts/android/capture_perfetto.ps1`
- `scripts/android/perfetto/startup_trace.pbtxt`

Purpose:

- capture a targeted manual trace outside Macrobenchmark
- launch NeoAlarm during the trace window when needed
- pull the trace into a local ignored artifacts directory

Run it with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/android/capture_perfetto.ps1 -LaunchNeoAlarm
```

Default output:

- `.artifacts/android-performance/neoalarm-startup.perfetto-trace`

### Dependency Audit Script

Location:

- `scripts/android/audit_datatransport.ps1`

Purpose:

- prove the source of the `com.google.android.datatransport.runtime` jobs seen on device
- record the exact Gradle dependency chain instead of relying on guesswork

Run it with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/android/audit_datatransport.ps1
```

Default output:

- `.artifacts/android-performance/datatransport-audit.txt`

## Current Real-Device Baseline

On the connected Samsung `SM-G990U1` running Android `16` on March 11, 2026, the current Macrobenchmark cold-start results were:

- `timeToInitialDisplayMs`: min `517.3`, median `581.8`, max `646.5`
- `timeToFullDisplayMs`: min `517.3`, median `581.8`, max `646.5`

The benchmark emitted ten Perfetto traces into:

- `build/benchmark/outputs/connected_android_test_additional_output/benchmark/connected/SM-G990U1 - 16`

## Why The App Has A `benchmark` Build Type

The benchmark flow uses a dedicated app `benchmark` build type rather than pointing directly at the normal `release` variant.

That build type is intentionally:

- release-like in behavior and compilation mode
- debug-signed so local devices can install it reliably
- not minified
- not shrink-resources

The non-minified choice is deliberate.

The project already validates the real minified `release` APK separately. For Macrobenchmark, the synthetic `benchmark` build type was hitting Flutter-plugin and R8 edge cases that were unrelated to the runtime behavior we actually wanted to measure. Keeping the benchmark build type release-like but shrinker-free gives us a stable benchmarking target without weakening the shipped release pipeline.

That means the performance workflow has two distinct responsibilities:

- Macrobenchmark for repeatable timing and trace generation
- minified release install testing for ship-mode regression detection

## Why `profileinstaller` Is Pinned Explicitly

The target app now declares:

- `androidx.profileinstaller:profileinstaller:1.4.1`

Reason:

- the device benchmark runs on Android `16` / API `36`
- the older transitive `profileinstaller` version brought in through Flutter was too old for the benchmark tooling on modern Android

Pinning a current version makes the benchmark infrastructure explicit and keeps the target app compatible with the current Macrobenchmark requirements.

The shipped app manifest does not stay globally `profileable`.

Instead:

- the dedicated `benchmark` target manifest carries `android:profileable="shell=true"`
- the normal app manifest stays free of that shell-profiling hook

That keeps the benchmarking surface available without broadening the production manifest more than necessary.

## DataTransport Audit Result

The on-device background jobs attributed to `com.google.android.datatransport.runtime` are not coming from Flutter state management or from the alarm engine.

They come from the QR stack:

- `com.google.mlkit:barcode-scanning:17.3.0`
- `com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1`
- `com.google.android.datatransport:transport-runtime:2.2.6`
- `com.google.android.datatransport:transport-backend-cct:2.3.3`

This means the QR mission currently carries a small dependency-level background-work cost.

Current decision:

- accept the cost for now because the QR mission is a core feature and the observed jobs are small

Future mitigation options if this cost becomes unacceptable:

- replace the QR stack with a lighter decoder stack
- move QR/vision work behind an optional flavor or module boundary
- keep the core alarm build free of ML Kit entirely and ship QR as an advanced variant

## How To Use This In Practice

For a normal performance investigation:

1. Run the Macrobenchmark script and inspect the JSON plus generated traces.
2. Capture a manual Perfetto trace for the specific scenario you care about.
3. Compare the traces before and after the code change.
4. If unexpected background work appears, rerun the dependency audit script before blaming app logic.

For release readiness:

1. Run the Macrobenchmark flow.
2. Build and install the minified release APK.
3. Smoke-test the real release artifact separately.

The benchmark build and the shipped release build answer different questions. Both matter.
