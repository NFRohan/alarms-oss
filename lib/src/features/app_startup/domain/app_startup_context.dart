class AppStartupContext {
  const AppStartupContext({required this.userUnlocked});

  factory AppStartupContext.fromMap(Map<Object?, Object?> raw) {
    return AppStartupContext(
      userUnlocked: raw['userUnlocked'] as bool? ?? true,
    );
  }

  final bool userUnlocked;

  bool get isDirectBootMode => !userUnlocked;
}
