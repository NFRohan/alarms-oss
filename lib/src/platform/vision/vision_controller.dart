import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final visionControllerProvider = Provider<VisionController>(
  (ref) => const NativeVisionController(),
);

enum VisionEventType {
  ready('ready'),
  error('error'),
  qrDetected('qr_detected'),
  qrMatched('qr_matched'),
  qrMismatch('qr_mismatch');

  const VisionEventType(this.id);

  final String id;

  static VisionEventType? fromId(String? value) {
    for (final type in VisionEventType.values) {
      if (type.id == value) {
        return type;
      }
    }
    return null;
  }
}

enum VisionSessionMode {
  qrRegistration('qr_registration'),
  qrMission('qr_mission');

  const VisionSessionMode(this.id);

  final String id;

  static VisionSessionMode? fromId(String? value) {
    for (final mode in VisionSessionMode.values) {
      if (mode.id == value) {
        return mode;
      }
    }
    return null;
  }
}

class VisionEvent {
  const VisionEvent({
    required this.type,
    this.mode,
    this.rawValue,
    this.code,
    this.message,
  });

  factory VisionEvent.fromMap(Map<Object?, Object?> raw) {
    return VisionEvent(
      type:
          VisionEventType.fromId(raw['type'] as String?) ??
          VisionEventType.error,
      mode: VisionSessionMode.fromId(raw['mode'] as String?),
      rawValue: raw['rawValue'] as String?,
      code: raw['code'] as String?,
      message: raw['message'] as String?,
    );
  }

  final VisionEventType type;
  final VisionSessionMode? mode;
  final String? rawValue;
  final String? code;
  final String? message;
}

abstract class VisionController {
  Stream<VisionEvent> events();

  Future<void> startQrRegistration();

  Future<void> startQrMission({required String targetValue});

  Future<void> stopSession();
}

class NativeVisionController implements VisionController {
  const NativeVisionController();

  static const _methodChannel = MethodChannel('dev.alarmsoss.vision');
  static const _eventChannel = EventChannel('dev.alarmsoss.vision/events');

  @override
  Stream<VisionEvent> events() {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => VisionEvent.fromMap(event as Map<Object?, Object?>),
    );
  }

  @override
  Future<void> startQrRegistration() {
    return _methodChannel.invokeMethod<void>('startQrRegistration');
  }

  @override
  Future<void> startQrMission({required String targetValue}) {
    return _methodChannel.invokeMethod<void>('startQrMission', {
      'targetValue': targetValue,
    });
  }

  @override
  Future<void> stopSession() {
    return _methodChannel.invokeMethod<void>('stopVisionSession');
  }
}

class VisionPreviewSurface extends StatelessWidget {
  const VisionPreviewSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return const AndroidView(viewType: 'dev.alarmsoss.vision/preview');
  }
}
