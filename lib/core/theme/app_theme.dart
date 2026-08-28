import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryLight = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF60A5FA);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryLight,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outlineVariant: const Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFFDBEAFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _primaryLight : const Color(0xFF64748B),
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _primaryLight,
        unselectedLabelColor: Color(0xFF64748B),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B),
      surfaceContainerHighest: const Color(0xFF334155),
      outlineVariant: const Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF475569)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF1E3A8A),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _primaryDark : const Color(0xFF94A3B8),
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _primaryDark,
        unselectedLabelColor: Color(0xFF94A3B8),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
