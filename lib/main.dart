import 'package:neoalarm/src/app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Keep startup minimal so direct-boot launches only enter alarm-critical UI.
  runApp(const ProviderScope(child: AlarmApp()));
}
