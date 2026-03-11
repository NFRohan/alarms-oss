import 'package:neoalarm/src/features/alarms/application/alarm_list_controller.dart';
import 'package:neoalarm/src/features/app_startup/domain/app_startup_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appStartupContextProvider = FutureProvider<AppStartupContext>(
  (ref) => ref.watch(alarmRepositoryProvider).getStartupContext(),
);
