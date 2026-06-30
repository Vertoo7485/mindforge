import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFD4A574), // Бронза
        secondary: Color(0xFF7B68EE), // Приглушённый фиолетовый
        surface: Color(0xFF1B1B2F), // Глубокий индиго
      ),
      scaffoldBackgroundColor: Color(0xFF1B1B2F),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF162447),
        foregroundColor: Color(0xFFD4A574), // Бронзовый текст в AppBar
        elevation: 0,
      ),
    );
  }
}
