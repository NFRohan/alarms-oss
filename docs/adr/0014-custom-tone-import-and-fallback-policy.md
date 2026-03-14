# 0014. Custom Tone Import And Fallback Policy

Date: 2026-03-15

## Status

Accepted

## Context

NeoAlarm now owns alarm playback through `MediaPlayer`, which makes user-selectable custom tones practical. That introduces a new reliability boundary:

- user-picked tones can live behind unstable content URIs
- user-picked files can be oversized or unsupported
- imported copies can fail on low storage
- custom tones are not reliable before first unlock after reboot

The project needs a custom-tone policy that stays consistent with the rest of the alarm engine: local-first, explicit failure handling, and no silent alarm path when user media disappears.

## Decision

NeoAlarm adopts the following first-pass custom-tone policy:

1. Tone selection uses Android's document picker.
2. The app supports only MP3 and WAV imports in the first version.
3. Validation is based on `ContentResolver.getType(uri)`, not just the file extension.
4. Tone imports are capped at 15 MB.
5. The app attempts to copy the selected tone into app-managed storage first.
6. If the copy fails with an `IOException`, the app falls back to a persistable URI reference when possible.
7. If a configured custom tone later becomes unavailable, the alarm still fires with NeoAlarm's bundled fallback tone.
8. Flutter surfaces the broken-tone state as a warning so the user can repair it.
9. Before first unlock after reboot, custom tones are never trusted. NeoAlarm always uses the bundled direct-boot-safe fallback tone in that state.
10. Imported tones are reusable across alarms and removable through tone management UI.

## Consequences

Positive:

- custom tones stay compatible with the local-first model
- missing or broken tone sources cannot silently disable an alarm
- large media files and mislabeled formats are rejected before they become playback bugs
- the direct-boot path remains deterministic even after custom tones are introduced

Negative:

- some valid but uncommon audio formats are intentionally rejected for now
- URI-backed tones may remain less reliable than copied imports
- users may be surprised that their custom tone does not play before first unlock after reboot

## Alternatives Considered

### Store only external URIs

Rejected because it makes the alarm too dependent on external providers, permission continuity, and source-file lifetime.

### Allow any file `MediaPlayer` can attempt to open

Rejected because it pushes format ambiguity and playback failures to alarm time instead of validating at import time.

### Use the custom tone before first unlock if the URI happens to resolve

Rejected because the direct-boot path needs deterministic behavior, not best-effort OEM-dependent media resolution.
