import 'package:alarms_oss/src/core/theme/app_theme.dart';
import 'package:alarms_oss/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'alarms-oss',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const DashboardScreen(),
    );
  }
}
