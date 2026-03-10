class AlarmEngineStatus {
  const AlarmEngineStatus({
    required this.canScheduleExactAlarms,
    required this.notificationsEnabled,
    required this.batteryOptimizationIgnored,
    required this.hasCamera,
    required this.cameraPermissionGranted,
    required this.hasStepSensor,
    required this.activityRecognitionGranted,
    required this.timezoneId,
  });

  factory AlarmEngineStatus.fromMap(Map<Object?, Object?> raw) {
    return AlarmEngineStatus(
      canScheduleExactAlarms: raw['canScheduleExactAlarms']! as bool,
      notificationsEnabled: raw['notificationsEnabled']! as bool,
      batteryOptimizationIgnored: raw['batteryOptimizationIgnored']! as bool,
      hasCamera: raw['hasCamera']! as bool,
      cameraPermissionGranted: raw['cameraPermissionGranted']! as bool,
      hasStepSensor: raw['hasStepSensor']! as bool,
      activityRecognitionGranted: raw['activityRecognitionGranted']! as bool,
      timezoneId: raw['timezoneId']! as String,
    );
  }

  final bool canScheduleExactAlarms;
  final bool notificationsEnabled;
  final bool batteryOptimizationIgnored;
  final bool hasCamera;
  final bool cameraPermissionGranted;
  final bool hasStepSensor;
  final bool activityRecognitionGranted;
  final String timezoneId;

  bool get cameraReady => hasCamera && cameraPermissionGranted;

  bool get stepsMissionReady => hasStepSensor && activityRecognitionGranted;
}
