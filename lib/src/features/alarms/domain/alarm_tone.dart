class AlarmTone {
  const AlarmTone({
    required this.id,
    required this.displayName,
    required this.sourceKind,
    required this.mimeType,
    required this.sizeBytes,
    required this.isHealthy,
    this.warning,
  });

  factory AlarmTone.fromMap(Map<Object?, Object?> raw) {
    return AlarmTone(
      id: raw['id']! as String,
      displayName: raw['displayName']! as String,
      sourceKind: raw['sourceKind']! as String,
      mimeType: raw['mimeType']! as String,
      sizeBytes: (raw['sizeBytes'] as num?)?.toInt() ?? 0,
      isHealthy: raw['isHealthy'] as bool? ?? true,
      warning: raw['warning'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String sourceKind;
  final String mimeType;
  final int sizeBytes;
  final bool isHealthy;
  final String? warning;

  String get sizeSummary {
    final megabytes = sizeBytes / (1024 * 1024);
    if (megabytes >= 1) {
      return '${megabytes.toStringAsFixed(1)} MB';
    }

    final kilobytes = sizeBytes / 1024;
    return '${kilobytes.toStringAsFixed(0)} KB';
  }

  String get metadataSummary => '$sizeSummary | $mimeType';
}
