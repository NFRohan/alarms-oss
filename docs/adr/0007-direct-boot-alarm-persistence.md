# 0007: Direct-Boot Alarm Persistence

## Status

Accepted

## Context

Android clears `AlarmManager` state on reboot.

That means an alarm app has to do two things after restart:

1. listen for the relevant boot/time reschedule broadcasts
2. read persisted alarms from storage that is actually available at the time those broadcasts arrive

The second requirement is easy to miss.

If alarm definitions live only in credential-protected app storage, then `LOCKED_BOOT_COMPLETED` is not enough by itself. The receiver may run before first unlock, but the alarm data still cannot be read, which makes early-boot rescheduling a false promise.

This project also persists active ring-session state. That state is part of alarm recovery and should live beside the alarm definitions in the same storage model.

## Decision

The project stores alarm definitions and active ring-session state in device-protected storage.

Specifically:

- the shared preference store used by `AlarmStore` and `RingSessionStore` is opened from a device-protected storage context
- existing installs are migrated from credential-protected storage into device-protected storage on access
- `LOCKED_BOOT_COMPLETED` is handled by the reschedule receiver
- alarm-critical components that may need to run before first unlock are marked `directBootAware`

These components include:

- the reschedule receiver
- the alarm broadcast receiver
- the ringing service
- the main activity used to surface the active alarm UI

## Consequences

### Positive

- enabled alarms can be rescheduled after reboot before the user unlocks the device
- alarm/session persistence and direct-boot behavior now match each other
- the app's reboot reliability story is stronger and easier to reason about

### Negative

- alarm/session data now lives in the more broadly available device-protected storage area
- persistence behavior is more security-sensitive and must remain local-only and backup-disabled
- contributors have to understand the difference between direct-boot-ready data and normal app-private data

## Alternatives Considered

### Keep Alarm Data In Credential-Protected Storage

Rejected because it undermines `LOCKED_BOOT_COMPLETED` support and weakens reboot reliability.

### Add `LOCKED_BOOT_COMPLETED` Without Moving Storage

Rejected because it would advertise a capability the app could not actually fulfill before first unlock.

### Move Only Alarm Definitions But Not Active Session State

Rejected because it would split the persistence model unnecessarily and make recovery behavior harder to reason about.
