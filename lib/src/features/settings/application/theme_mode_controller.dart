import 'package:neoalarm/src/features/app_startup/application/app_startup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeModeControllerProvider =
    AsyncNotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

class AppThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _darkModeKey = 'settings.dark_mode_enabled';

  @override
  Future<ThemeMode> build() async {
    final startupContext = await ref.watch(appStartupContextProvider.future);
    if (startupContext.isDirectBootMode) {
      return ThemeMode.light;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final isDarkModeEnabled = preferences.getBool(_darkModeKey) ?? false;
      return isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final nextMode = enabled ? ThemeMode.dark : ThemeMode.light;
    state = AsyncData(nextMode);

    final startupContext = await ref.read(appStartupContextProvider.future);
    if (startupContext.isDirectBootMode) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
  }
}
