import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0d6efd); // Bootstrap Primary Blue
  static const Color secondaryColor = Color(0xFF6c757d); // Bootstrap Secondary
  static const Color successColor = Color(0xFF198754);
  static const Color dangerColor = Color(0xFFdc3545);
  static const Color warningColor = Color(0xFFffc107);
  static const Color infoColor = Color(0xFF0dcaf0);
  
  static const Color backgroundColorLight = Color(0xFFf8f9fa); // Bootstrap Light
  static const Color backgroundColorDark = Color(0xFF212529); // Bootstrap Dark

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF343a40),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
    );
  }
}
