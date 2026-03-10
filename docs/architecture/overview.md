# Architecture Overview

## System Shape

The app is intentionally split into two execution domains:

- Flutter: user interface, alarm editing, mission configuration, non-critical state presentation
- Native Android: exact scheduling, alarm firing, ringing lifecycle, recovery, and camera analysis

This split exists because alarm correctness cannot depend on the Flutter isolate being alive when the device wakes from Doze or when the app process has been reclaimed.

## Core Subsystems

### Alarm Domain

Owns alarm definitions, repeat rules, snooze policy, mission configuration, and next-fire computation semantics.

### Android Alarm Engine

Owns:

- exact scheduling via `AlarmManager.setAlarmClock()`
- boot/time/timezone reschedule handling
- active ring session state
- foreground ringing service
- wake handling and lock-screen launch

### Mission Platform

Owns a stable mission contract so dismissal challenges can be added without rewriting the scheduler or alarm service.

Initial mission types:

- Math
- Steps
- QR

### Vision Pipeline

Owns camera preview and frame analysis for vision-based missions.

The pipeline is native-first:

- CameraX provides preview and image analysis
- analyzers consume frames
- Flutter receives analyzer results and mission-state updates

This keeps the QR mission fast today and makes future on-device object detection a swap of analyzer implementation rather than a rebuild of the camera stack.

## Runtime Flows

### Alarm Scheduling

1. User creates or updates an alarm in Flutter.
2. Flutter sends a normalized `AlarmSpec` to the native bridge.
3. Native persistence stores the alarm and schedules the next exact fire time.

### Alarm Firing

1. Android receives the alarm broadcast at the scheduled time.
2. A native foreground service starts immediately.
3. Audio, vibration, wakelock, and session persistence begin before Flutter UI is required.
4. A full-screen alarm activity launches over the lock screen.

### Mission Completion

1. The active mission screen binds to the current `RingSession`.
2. The mission driver reports progress and completion.
3. Native session logic validates dismissal or snooze rules.
4. The service stops only after a successful dismiss path.

### Recovery

If the app process dies while an alarm is ringing, the native session state remains authoritative. Relaunch should restore the user directly into the active mission flow.

## Key Invariants

- Alarm delivery must not depend on a live Flutter isolate.
- Ring audio must start before any mission UI dependency is satisfied.
- Persisted alarm state and persisted ring-session state must be recoverable independently.
- Mission implementations must not mutate scheduler behavior directly.
- Vision missions must depend on analyzer results, not raw cross-platform frame transport.

## Non-Goals For V1

- Cloud sync
- iOS support
- Guaranteed blocking of the stock Android power-off menu
- Server-side analytics or telemetry
