# Release Plan: v1.0.3 Custom Tones And Playback Reliability

## Release Theme

`v1.0.3` should be a focused playback release:

- custom alarm tone import and reuse
- resilient fallback behavior when tone sources break
- clear direct-boot behavior for custom tones

This release should stay intentionally narrow. The goal is not to add a broad new feature bucket. The goal is to make alarm audio feel more personal without weakening the reliability guarantees that already exist.

## Product Decisions Locked

### Tone Source UX

- custom tones are selected through Android's file picker
- the picker is used from the alarm editor
- imported tones become reusable across alarms after the first import
- users can remove imported tones later from a tone-management surface

### Persistence Policy

- first choice: copy the selected tone into app-managed storage
- fallback: if copying fails but the original URI remains usable, keep a reference to the original URI
- NeoAlarm should prefer app-owned copies because they are more stable than external references

### Failure Policy

If a custom tone becomes unavailable later:

- the alarm should still ring
- playback should fall back to the bundled NeoAlarm fallback tone
- the UI should show a warning so the user knows that the selected custom tone is no longer healthy

### Direct-Boot Policy

- when the device is unlocked, use the custom tone if it is available
- before first unlock after reboot, always use the bundled direct-boot-safe fallback tone

This is explicit product behavior, not a bug or temporary workaround.

### Format Policy

First release supports:

- `.mp3`
- `.wav`

Unsupported selections should be handled before import completes:

- reject the import
- explain that `v1.0.3` supports only MP3 and WAV
- do not save a broken tone entry

Validation should not trust file extensions alone:

- query Android `ContentResolver.getType(uri)` before import
- accept only MIME types that map to the supported first-release formats
- first-pass accepted MIME types should be:
  - `audio/mpeg`
  - `audio/x-wav`
  - `audio/wav`
- if the MIME type does not match, reject the file even if the extension looks correct

### Import Size Limit

Imported tones should have a strict size cap:

- reject files larger than `15 MB`
- show clear feedback such as `File too large. Please select a tone under 15 MB.`

This is both a storage rule and a playback-reliability rule. Alarm tones should stay small and predictable.

### Scope Policy

`v1.0.3` should focus on custom tones and playback reliability only.

Not in scope:

- unrelated quality-of-life features
- new missions
- backup/export
- app-wide tone defaults

## Clarified Engineering Direction

### File Picker Model

There are two related but different concepts:

1. **File picker as UI**
   - Android's picker shows local files and other document providers
   - this is how the user chooses a file

2. **URI reference as storage model**
   - after the picker returns, the app can either:
     - keep the returned URI as the long-term source
     - or copy the file into app-managed storage and use that copy

The release should use the file picker for selection, but should prefer copying the chosen tone into app-managed storage for reliability.

### Storage Model

The tone system should distinguish between:

- imported app-managed tones
- fallback reference-backed tones if copying fails
- bundled fallback tone used for direct boot and broken-source recovery

The stored metadata should also include:

- file size
- detected MIME type
- whether the tone is app-managed or reference-backed

### Direct-Boot Separation

Custom tones are an unlocked-device convenience feature.

The alarm engine should not attempt to make arbitrary user-picked tone sources work before first unlock after reboot. The bundled fallback tone remains the only guaranteed direct-boot-safe alarm sound.

## Proposed User Flows

### Import Tone While Editing An Alarm

1. User opens alarm editor
2. User chooses `Custom tone`
3. Android file picker opens
4. User selects an MP3 or WAV file
5. App validates MIME type and file size
6. App copies the file into app-managed tone storage
7. If copy fails due to low storage, the app catches the `IOException` and falls back to a reference-backed tone if the original URI is still usable
8. The imported tone is now selectable for this alarm and future alarms

### Broken Tone Recovery

1. Alarm references a tone that is no longer available
2. Alarm still rings with the bundled fallback tone
3. Alarm card/editor/settings show a warning
4. User can reselect, repair, or remove the broken tone

### Remove Imported Tone

1. User opens tone-management UI
2. User removes an imported tone
3. Any alarms using it become warning-state alarms
4. Those alarms fall back to the bundled tone until fixed

## Data Model Changes

Add a reusable imported-tone model with fields like:

- tone id
- display name
- source kind: `imported_copy` or `external_reference`
- local app path or persisted URI
- mime type / extension
- health state
- created at

Update alarm records to reference:

- ringtone policy
- optional custom tone id

Do not overload the existing ringtone enum with file-path details.

## Android Engine Changes

- add tone resolution logic that prefers imported app-managed files
- keep `MediaPlayer` as the playback engine
- preserve the direct-boot-safe fallback path
- detect source failure and fall back loudly rather than silently
- surface tone-health status back through the Flutter/native bridge
- reject oversize files before import
- validate MIME type through `ContentResolver`, not just file extension
- catch copy-time `IOException` explicitly so low-storage devices degrade safely instead of crashing the import flow

## Flutter UI Changes

- add a custom-tone import path in the alarm editor
- show selected tone name in alarm cards and editor summaries
- add warning treatment when the chosen tone is unhealthy
- add a small tone-management surface for removing imported tones

## Validation Plan

Before release:

- import a valid WAV tone and confirm it rings
- import a valid MP3 tone and confirm it rings
- attempt to import an unsupported file and confirm it is rejected cleanly
- attempt to import an oversize file and confirm it is rejected cleanly
- validate low-storage copy failure behavior and confirm the app falls back to a reference-backed tone instead of crashing
- confirm imported tones can be reused across alarms
- remove an imported tone and confirm affected alarms fall back and warn
- confirm direct-boot/reboot-before-unlock still uses the bundled fallback tone
- confirm normal unlocked alarms still use the chosen imported tone
- confirm broken-source fallback does not stop alarm delivery

## Release Shape

`v1.0.3` should read as:

`Custom alarm tones, reusable imports, and safer playback fallback behavior`

That is coherent, user-visible, and directly aligned with the current playback architecture work.
