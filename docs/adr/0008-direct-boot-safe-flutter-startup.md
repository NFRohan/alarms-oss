# 0008: Direct-Boot-Safe Flutter Startup

## Status

Accepted

## Context

Once the app became direct-boot aware, Flutter startup could no longer be treated as a normal unlocked-app assumption.

Before first unlock after reboot:

- native alarm components may still need to run
- device-protected alarm/session state is available
- credential-protected storage is not guaranteed to be available
- third-party Flutter plugins may crash if they assume normal unlocked startup

That means the Flutter shell must not eagerly initialize optional behavior just because the process started.

## Decision

The app adopts a direct-boot-safe Flutter startup policy:

1. `main.dart` stays minimal and free of nonessential startup side effects.
2. Native Android exposes whether the user is unlocked.
3. Flutter treats unlocked state as an explicit startup contract, not an assumption.
4. If the device is still in direct boot mode:
   - active alarm UI may still be shown
   - the full dashboard is not loaded
   - the app shows a minimal direct-boot-safe shell instead
5. Future plugins or startup work must be considered unsafe by default until proven direct-boot safe.

## Consequences

### Positive

- pre-unlock alarm launches stay focused on alarm-critical behavior
- future contributors have a visible policy for startup-time plugin safety
- the app avoids normalizing a dangerous pattern where arbitrary startup code runs during direct boot

### Negative

- some otherwise harmless startup conveniences must be deferred until unlocked state is confirmed
- contributors need to think about startup mode explicitly when adding dependencies

## Alternatives Considered

### Let Flutter Start Normally In Direct Boot

Rejected because it would make correctness depend on the internal behavior of every future dependency.

### Avoid Launching Flutter Before Unlock Entirely

Rejected because active alarm UI still benefits from the Flutter shell, and the native alarm engine is already authoritative enough to decide when that UI is appropriate.
