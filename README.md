# alarms-oss

Android-first, local-first, open source alarm app built with Flutter and a native Android core.

## Documentation

- Project docs index: [docs/README.md](docs/README.md)
- Overall implementation plan: [docs/planning/overall-plan.md](docs/planning/overall-plan.md)
- Sprint plan: [docs/planning/sprint-plan.md](docs/planning/sprint-plan.md)
- Test strategy: [docs/testing/test-strategy.md](docs/testing/test-strategy.md)
- Architecture overview: [docs/architecture/overview.md](docs/architecture/overview.md)
- Engineering story: [docs/architecture/engineering-story.md](docs/architecture/engineering-story.md)

## Current Status

The project is now on a clean Flutter 3.41 scaffold. Sprint 1 implementation work is establishing:

- a deliberate Flutter shell instead of the template app
- Android CI that builds an APK artifact
- the first stable project boundaries for alarm engine, missions, and vision work
