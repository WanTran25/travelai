import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class AppColors {
  static const Color accentOrange = Color(0xFFF77F00);
  static const Color marineBlue = Color(0xFF0F4C81);
  static const Color navyDark = Color(0xFF1E2640);
  static const Color darkBackground = Color(0xFF121420);
  static const Color darkCard = Color(0xFF1E2640);
  static const Color darkAppBar = Color(0xFF1E2640);
  static const Color lightBackground = Color(0xFFF4F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightSubtext = Color(0xFF6B7280);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      _isDark(context) ? darkBackground : lightBackground;

  static Color card(BuildContext context) =>
      _isDark(context) ? darkCard : lightCard;

  static Color appBar(BuildContext context) =>
      _isDark(context) ? darkAppBar : lightAppBar;

  static Color primaryText(BuildContext context) =>
      _isDark(context) ? Colors.white : lightText;

  static Color secondaryText(BuildContext context) =>
      _isDark(context) ? Colors.grey : lightSubtext;

  static Color fieldBorder(BuildContext context) =>
      _isDark(context) ? Colors.white24 : Colors.black12;

  static Color fieldBg(BuildContext context) =>
      _isDark(context) ? navyDark : lightSurface;

  static Color divider(BuildContext context) =>
      _isDark(context) ? Colors.white12 : Colors.black12;

  static Color markerColor(int categoryId) {
    switch (categoryId) {
      case 1: return const Color(0xFFE63946);
      case 2: return const Color(0xFF457B9D);
      case 3: return const Color(0xFFE9C46A);
      case 4: return const Color(0xFF2A9D8F);
      default: return const Color(0xFF9B5DE5);
    }
  }
}

class AppTheme {
  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentOrange,
      secondary: AppColors.navyDark,
      surface: AppColors.darkCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkAppBar,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerColor: Colors.white12,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentOrange),
      ),
      fillColor: AppColors.navyDark,
      filled: true,
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      labelLarge: TextStyle(color: Colors.white),
    ),
  );

  static ThemeData get light => ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentOrange,
      secondary: AppColors.marineBlue,
      surface: AppColors.lightCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightAppBar,
      foregroundColor: AppColors.lightText,
      elevation: 0,
    ),
    dividerColor: Colors.black12,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentOrange),
      ),
      fillColor: AppColors.lightSurface,
      filled: true,
      hintStyle: const TextStyle(color: AppColors.lightSubtext),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightText),
      bodyMedium: TextStyle(color: AppColors.lightSubtext),
      titleLarge: TextStyle(color: AppColors.lightText),
      titleMedium: TextStyle(color: AppColors.lightText),
      labelLarge: TextStyle(color: AppColors.lightText),
    ),
  );

  static ThemeData fromMode(ThemeMode mode) =>
      mode == ThemeMode.dark ? dark : light;
}
