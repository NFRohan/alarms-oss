import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeoPalette {
  const NeoPalette({
    required this.paper,
    required this.panel,
    required this.warm,
    required this.ink,
    required this.subtext,
    required this.disabled,
    required this.muted,
    required this.shadow,
    required this.warningSurface,
    required this.warningText,
  });

  final Color paper;
  final Color panel;
  final Color warm;
  final Color ink;
  final Color subtext;
  final Color disabled;
  final Color muted;
  final Color shadow;
  final Color warningSurface;
  final Color warningText;
}

class NeoColors {
  static const accentInk = Color(0xFF111111);
  static const primary = Color(0xFFFFFF00);
  static const cyan = Color(0xFF16E0E7);
  static const orange = Color(0xFFFF7A00);
  static const success = Color(0xFF34C759);

  static const lightPalette = NeoPalette(
    paper: Color(0xFFF8F8F5),
    panel: Color(0xFFFFFFFF),
    warm: Color(0xFFF4EBD3),
    ink: Color(0xFF111111),
    subtext: Color(0xFF3F4654),
    disabled: Color(0xFFD6D6D0),
    muted: Color(0xFFEAE7DD),
    shadow: Color(0xFF000000),
    warningSurface: Color(0xFFFFF2EE),
    warningText: Color(0xFF56483A),
  );

  static const darkPalette = NeoPalette(
    paper: Color(0xFF11151A),
    panel: Color(0xFF1D232B),
    warm: Color(0xFF332B20),
    ink: Color(0xFFF5F1E7),
    subtext: Color(0xFFD2CCBF),
    disabled: Color(0xFF535B65),
    muted: Color(0xFF2A3139),
    shadow: Color(0xFF040506),
    warningSurface: Color(0xFF402821),
    warningText: Color(0xFFF1D6CC),
  );

  static NeoPalette _activePalette = lightPalette;

  static void use(NeoPalette palette) {
    _activePalette = palette;
  }

  static Color get paper => _activePalette.paper;
  static Color get panel => _activePalette.panel;
  static Color get warm => _activePalette.warm;
  static Color get ink => _activePalette.ink;
  static Color get subtext => _activePalette.subtext;
  static Color get disabled => _activePalette.disabled;
  static Color get muted => _activePalette.muted;
  static Color get shadow => _activePalette.shadow;
  static Color get warningSurface => _activePalette.warningSurface;
  static Color get warningText => _activePalette.warningText;

  static Color foregroundOn(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? darkPalette.ink : accentInk;
  }
}

BorderSide neoBorderSide({double width = 3, Color? color}) {
  return BorderSide(color: color ?? NeoColors.ink, width: width);
}

List<BoxShadow> neoShadow({Offset offset = const Offset(4, 4), Color? color}) {
  return [
    BoxShadow(color: color ?? NeoColors.shadow, offset: offset, blurRadius: 0),
  ];
}

RoundedRectangleBorder neoShape({double width = 3, Color? color}) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: neoBorderSide(width: width, color: color),
  );
}

BoxDecoration neoPanelDecoration({
  Color? color,
  double borderWidth = 3,
  Offset shadowOffset = const Offset(4, 4),
}) {
  return BoxDecoration(
    color: color ?? NeoColors.panel,
    border: Border.all(color: NeoColors.ink, width: borderWidth),
    boxShadow: neoShadow(offset: shadowOffset),
  );
}

ThemeData buildAppTheme({required bool isDark}) {
  final palette = isDark ? NeoColors.darkPalette : NeoColors.lightPalette;
  NeoColors.use(palette);
  GoogleFonts.config.allowRuntimeFetching = false;

  final colorScheme =
      (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: NeoColors.primary,
        onPrimary: NeoColors.accentInk,
        secondary: NeoColors.cyan,
        onSecondary: NeoColors.accentInk,
        error: NeoColors.orange,
        onError: NeoColors.accentInk,
        surface: NeoColors.panel,
        onSurface: NeoColors.ink,
        outline: NeoColors.ink,
        outlineVariant: NeoColors.subtext,
        shadow: NeoColors.shadow,
        scrim: NeoColors.shadow,
        surfaceContainerHighest: NeoColors.muted,
        surfaceTint: Colors.transparent,
        inverseSurface: isDark ? NeoColors.paper : NeoColors.ink,
        onInverseSurface: isDark ? NeoColors.ink : NeoColors.paper,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: colorScheme,
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w900,
      height: 0.95,
      letterSpacing: -2.6,
      color: NeoColors.ink,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 44,
      fontWeight: FontWeight.w900,
      height: 0.95,
      letterSpacing: -1.8,
      color: NeoColors.ink,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.w900,
      height: 0.98,
      letterSpacing: -1.2,
      color: NeoColors.ink,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -1.0,
      color: NeoColors.ink,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.8,
      color: NeoColors.ink,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.4,
      color: NeoColors.ink,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.4,
      color: NeoColors.ink,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: NeoColors.ink,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: NeoColors.ink,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: NeoColors.ink,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: NeoColors.ink,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: NeoColors.subtext,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
      color: NeoColors.ink,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
      color: NeoColors.subtext,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: NeoColors.paper,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: NeoColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: neoShape(),
      clipBehavior: Clip.antiAlias,
    ),
    dividerColor: NeoColors.ink,
    iconTheme: IconThemeData(color: NeoColors.ink, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: NeoColors.paper,
      foregroundColor: NeoColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeoColors.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: textTheme.labelLarge?.copyWith(color: NeoColors.subtext),
      hintStyle: textTheme.bodyMedium?.copyWith(color: NeoColors.subtext),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: neoBorderSide(),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: neoBorderSide(),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: neoBorderSide(width: 4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: NeoColors.primary,
        foregroundColor: NeoColors.accentInk,
        shape: neoShape(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NeoColors.ink,
        textStyle: textTheme.labelLarge,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? NeoColors.shadow : NeoColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: NeoColors.primary,
      ),
      shape: neoShape(),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
