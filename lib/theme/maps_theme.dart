import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class AppAssets {
  static const logoIcon = 'assets/logo/icon.png';
}

/// Google Maps–inspired design tokens (see DESIGN.md).
class MapsColors {
  // Google logo / semantic
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleBluePressed = Color(0xFF1A73E8);
  static const Color googleBlueDark = Color(0xFF174EA6);
  static const Color googleBlueHalo = Color(0x2E4285F4); // rgba(66,133,244,0.18)
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC04);
  static const Color categoryOrange = Color(0xFFFB8C00);

  // Canvas & text (light)
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F4);
  static const Color divider = Color(0xFFDADCE0);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF80868B);

  // Map tiles (light)
  static const Color landNeutral = Color(0xFFF5F5F5);
  static const Color roadWhite = Color(0xFFFFFFFF);
  static const Color highwayYellow = Color(0xFFFDF6E3);
  static const Color waterBlue = Color(0xFFAADAFF);
  static const Color parkGreen = Color(0xFFC8E6C9);
  static const Color buildingFill = Color(0xFFF0F0F0);

  // Dark mode
  static const Color darkCanvas = Color(0xFF202124);
  static const Color darkSurface1 = Color(0xFF2D2E31);
  static const Color darkSurface2 = Color(0xFF3C4043);
  static const Color darkDivider = Color(0xFF3C4043);
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFF9AA0A6);
  static const Color darkMapLand = Color(0xFF242F3E);
  static const Color darkMapWater = Color(0xFF17263C);
  static const Color darkMapPark = Color(0xFF023E58);

  // Semantic
  static const Color error = Color(0xFFEA4335);
  static const Color success = Color(0xFF34A853);

  // Chip active (light)
  static const Color chipActiveBg = Color(0xFFE8F0FE);
  static const Color chipActiveText = Color(0xFF1967D2);
}

class MapsShadows {
  static List<BoxShadow> searchBar(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> mapControl(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> bottomSheet(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> fab(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.45 : 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class MapsRadii {
  static const double sheet = 16;
  static const double searchPill = 24;
  static const double chip = 18;
  static const double buttonPill = 22;
  static const double card = 12;
}

extension DarkModeTheme on BuildContext {
  bool get isDarkMode => watch<NavigationProvider>().isDarkMode;

  Color get canvasColor =>
      isDarkMode ? MapsColors.darkSurface1 : MapsColors.canvasWhite;
  Color get surfaceColor =>
      isDarkMode ? MapsColors.darkSurface2 : MapsColors.surfaceMuted;
  Color get inkColor =>
      isDarkMode ? MapsColors.darkTextPrimary : MapsColors.textPrimary;
  Color get secondaryColor =>
      isDarkMode ? MapsColors.darkTextSecondary : MapsColors.textSecondary;
  Color get mutedColor =>
      isDarkMode ? MapsColors.darkTextSecondary : MapsColors.textTertiary;
  Color get dividerColor =>
      isDarkMode ? MapsColors.darkDivider : MapsColors.divider;
  Color get creamColor =>
      isDarkMode ? MapsColors.darkMapLand : MapsColors.landNeutral;
  Color get accentBlue => MapsColors.googleBlue;
  Color get accentBluePressed => MapsColors.googleBluePressed;
  Color get pinRed => MapsColors.googleRed;
  Color get savedGreen => MapsColors.googleGreen;
  Color get chipActiveBg =>
      isDarkMode ? MapsColors.googleBlue.withOpacity(0.18) : MapsColors.chipActiveBg;
  Color get chipActiveBorder => MapsColors.googleBlue;
  Color get chipActiveText =>
      isDarkMode ? MapsColors.googleBlue : MapsColors.chipActiveText;
}

class MapsTypography {
  static const TextStyle screenTitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.2,
  );
  static const TextStyle sectionHdr = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.25,
    letterSpacing: 0.4,
  );
  static const TextStyle rowTitle = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.4,
  );
  static const TextStyle meta = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.3,
  );
  static const TextStyle searchHint = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.25,
  );
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1,
  );
  static const TextStyle chip = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1,
  );
  static const TextStyle eta = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1,
  );
  static const TextStyle hudValue = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle hudLabel = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 9,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // Legacy aliases
  static const TextStyle navTitle = screenTitle;
  static const TextStyle listTitle = rowTitle;
  static const TextStyle placeSubtitle = body;
  static const TextStyle caption = meta;
  static const TextStyle button = buttonPrimary;
  static const TextStyle etaTime = eta;
}

class MapsTheme {
  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? MapsColors.darkCanvas : MapsColors.landNeutral;
    final surface = isDark ? MapsColors.darkSurface1 : MapsColors.canvasWhite;
    final onSurface =
        isDark ? MapsColors.darkTextPrimary : MapsColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: MapsColors.googleBlue,
        onPrimary: Colors.white,
        secondary: MapsColors.googleGreen,
        onSecondary: Colors.white,
        error: MapsColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: MapsTypography.screenTitle.copyWith(color: onSurface),
        contentTextStyle:
            MapsTypography.body.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MapsRadii.sheet)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MapsColors.googleBlue,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MapsColors.googleBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? MapsColors.darkSurface2
              : MapsColors.surfaceMuted,
          disabledForegroundColor: MapsColors.textTertiary,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MapsRadii.buttonPill),
          ),
          textStyle: MapsTypography.buttonPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: isDark
              ? MapsColors.darkTextSecondary
              : MapsColors.textSecondary,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? MapsColors.darkDivider : MapsColors.divider,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: MapsColors.googleBlue, width: 2),
        ),
      ),
      sliderTheme: SliderThemeData(
        thumbColor: Colors.white,
        activeTrackColor: MapsColors.googleBlue,
        inactiveTrackColor: MapsColors.googleBlue.withOpacity(0.15),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? MapsColors.darkSurface2 : MapsColors.textPrimary,
        contentTextStyle: TextStyle(
          color: isDark ? MapsColors.darkTextPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MapsRadii.card)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? MapsColors.darkDivider : MapsColors.divider,
      ),
    );
  }

  static void applySystemOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? MapsColors.darkSurface1 : MapsColors.canvasWhite,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }
}
