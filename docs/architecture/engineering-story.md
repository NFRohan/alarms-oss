# Engineering Story

## The Problem We Are Solving

Most alarm apps are easy to copy at the UI level and hard to trust at the systems level. A serious alarm app is not a clock widget with extra screens. It is a reliability product that happens to have a UI.

That distinction drives the entire architecture.

## Why Flutter Is Not The Alarm Engine

Flutter is a strong choice for product velocity, interface quality, and cross-platform ergonomics. It is not the right place to anchor alarm-critical behavior on Android.

An alarm app has to survive:

- overnight Doze
- reclaimed app processes
- boot and time changes
- lock-screen launch constraints
- sensor and camera mission handoff while the ring service is already active

For those reasons, the app uses Flutter as the shell and native Android as the execution core.

## Why The Project Is Local-First

The project exists partly as a rejection of ad-driven alarm apps. The cleanest way to keep that promise is to make the product work entirely on-device:

- no account dependency
- no backend dependency
- no telemetry dependency
- no internet dependency in MVP

This also improves reliability. An alarm should not degrade because a remote service changed or became unavailable.

## Why The Mission System Must Be Modular

Dismissal missions are the main reason contributors will want to extend the project. If missions are embedded directly into the ring service or UI routing, every new challenge becomes an architecture risk.

The project therefore needs a mission contract with strict boundaries:

- the alarm engine decides when a mission is required
- a mission driver decides how completion is evaluated
- the UI renders progress and input for the active mission

This separation should make it possible to add new missions without re-auditing the scheduler on every feature.

## Why QR Is More Than A QR Feature

The first vision mission is QR scanning, but the real engineering decision is to establish the camera boundary correctly now.

If QR is implemented as a disposable plugin tied to one screen, future object-recognition work will require rewriting the camera stack. Instead, the project should build a reusable native vision pipeline:

- CameraX handles preview and frame analysis
- a `VisionAnalyzer` consumes frames
- mission logic reacts to analyzer results

That keeps v1 practical while making future TinyML or TFLite work a matter of swapping analyzers, not redesigning ownership.

## Why The Documentation Must Be Strong

This repository will attract contributors who are capable of extending it beyond the original author. That only works if the engineering story is visible.

Strong documentation should answer:

- what is guaranteed
- what is merely preferred
- what constraints forced a design
- where to put new work
- which decisions are already settled

If the answer to those questions lives only in source code, the project will slow down as soon as the first non-trivial feature lands.
