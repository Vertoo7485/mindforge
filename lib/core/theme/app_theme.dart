import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFD4A574),
        secondary: Color(0xFF7B68EE),
        surface: Color(0xFF1B1B2F),
        onSurface: Colors.white,
        onPrimary: Colors.black,
      ),
      scaffoldBackgroundColor: Color(0xFF1B1B2F),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF162447),
        foregroundColor: Color(0xFFD4A574),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF162447),
        selectedItemColor: Color(0xFFD4A574),
        unselectedItemColor: Colors.grey[400],
        selectedIconTheme: IconThemeData(color: Color(0xFFD4A574), size: 24),
        unselectedIconTheme: IconThemeData(color: Colors.grey[400], size: 24),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF23233A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
