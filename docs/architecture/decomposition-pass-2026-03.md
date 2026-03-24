# Decomposition Pass: March 2026

## Why We Did This

Several core files had grown past the point where they were comfortable to review or extend safely. The issue was not line count by itself. The real problem was that UI layout, local state, async actions, and feature-specific helpers had started to live together in the same files.

This pass was meant to:

- reduce edit risk in high-churn files
- make responsibilities easier to see
- remove stale in-file helper code left behind by earlier extractions
- keep behavior unchanged while improving maintainability

## What Changed

### Alarm Editor

The largest split happened around the alarm editor.

Before:
- `alarm_editor_sheet.dart` held the sheet container, local editing state, custom tone management, the roller time picker, and a large set of small editor-specific widgets

After:
- [alarm_editor_sheet.dart](e:/Projects/alarms-oss/lib/src/features/alarms/presentation/alarm_editor_sheet.dart) keeps the stateful editor container and save logic
- [alarm_editor_widgets.dart](e:/Projects/alarms-oss/lib/src/features/alarms/presentation/widgets/alarm_editor_widgets.dart) owns the reusable editor controls
- [alarm_custom_tone_panel.dart](e:/Projects/alarms-oss/lib/src/features/alarms/presentation/widgets/alarm_custom_tone_panel.dart) owns custom-tone selection and import management UI
- [alarm_time_picker_sheet.dart](e:/Projects/alarms-oss/lib/src/features/alarms/presentation/widgets/alarm_time_picker_sheet.dart) owns the roller-style time picker

Result:
- the editor file dropped from roughly 1481 lines to 778 lines
- dead legacy widget code was removed instead of being left behind as inactive ballast

### Dashboard

Before:
- `dashboard_screen.dart` mixed shell lifecycle, app resume behavior, mutation handlers, and the full dashboard presentation tree

After:
- [dashboard_screen.dart](e:/Projects/alarms-oss/lib/src/features/dashboard/presentation/dashboard_screen.dart) keeps shell state and action wiring
- [dashboard_widgets.dart](e:/Projects/alarms-oss/lib/src/features/dashboard/presentation/widgets/dashboard_widgets.dart) owns the dashboard presentation widgets and formatting helpers

Result:
- the dashboard shell became much easier to scan and reason about during feature work

### Alarm Playback

Before:
- `AlarmRingingService.kt` owned service lifecycle, session transitions, playback setup, vibration, ramp logic, route checks, loudness policy, and fallback audio decisions

After:
- [AlarmRingingService.kt](e:/Projects/alarms-oss/android/app/src/main/kotlin/dev/neoalarm/app/alarmengine/AlarmRingingService.kt) keeps service/session orchestration
- [AlarmPlaybackController.kt](e:/Projects/alarms-oss/android/app/src/main/kotlin/dev/neoalarm/app/alarmengine/AlarmPlaybackController.kt) owns audio playback policy and execution

Result:
- playback behavior now has a single focused home
- future audio work like custom tones, route policy, and boost tuning should stay out of the service lifecycle code

## Cleanup Included In The Same Pass

This pass also kept a few small cleanup changes that fit naturally with the split:

- [ToneLibraryManager.kt](e:/Projects/alarms-oss/android/app/src/main/kotlin/dev/neoalarm/app/alarmengine/ToneLibraryManager.kt) now deletes partial imported files if copy fails mid-stream
- [alarm_spec.dart](e:/Projects/alarms-oss/lib/src/features/alarms/domain/alarm_spec.dart) uses a stable plain-text volume summary separator
- [alarm_tone.dart](e:/Projects/alarms-oss/lib/src/features/alarms/domain/alarm_tone.dart) now exposes tone metadata summary formatting at the model level

## Verification

The decomposition was treated as behavior-neutral refactoring and validated the same way as product work:

- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- install the rebuilt release APK to a physical Android device

## What To Watch During Manual Verification

Because the highest-risk splits were in editor, dashboard, and playback flows, the most useful real-device checks are:

- create and edit alarms
- open and use the roller time picker
- import, select, and manage custom tones
- enable/disable alarms from the dashboard
- let alarms ring and verify normal audio behavior

## Follow-Up Guidance

This pass intentionally focused on the biggest pain points first. It did not try to split every large file in the repo just to hit an arbitrary size target.

Files worth watching later, but not urgent right now:

- `settings_screen.dart`
- `onboarding_screen.dart`
- `AlarmEngineMethodCallHandler.kt`

The rule going forward should stay simple:
- split when a file is carrying multiple responsibilities or leaving dead/stale code behind
- do not split purely to satisfy line-count aesthetics
