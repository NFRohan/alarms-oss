# ADR 0002: Native Vision Pipeline For QR And Future ML Missions

- Status: Accepted
- Date: 2026-03-11

## Context

The first planned vision mission is QR scanning, but the roadmap includes possible future on-device object recognition. A simple QR plugin wired directly to a Flutter screen would be faster to prototype but would likely become throwaway architecture once object detection is introduced.

Routing raw camera frames through Dart would also create unnecessary bridge overhead and complicate future analyzer performance work.

## Decision

Build a native Android vision pipeline from the start:

- CameraX owns camera preview and image analysis
- a native `VisionAnalyzer` interface consumes frames
- QR scanning is implemented as the first analyzer
- Flutter receives mission-state updates and analyzer results, not raw frames

Future object-detection work should plug in a new analyzer implementation rather than replace the camera ownership model.

## Consequences

- The QR mission takes slightly more upfront design work.
- Future ML missions can reuse the camera shell and analyzer contract.
- Camera performance and frame lifecycle stay native, where optimization is easier.
- The Flutter UI remains simpler and more focused on mission presentation.

## Alternatives Considered

- Use a QR plugin now and redesign later
- Stream raw frames into Dart and keep analyzers cross-platform

The plugin-now approach creates planned rework. The Dart-stream approach adds overhead in the hottest part of the pipeline and weakens the future ML path.
