import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF16A34A);       // green-600
  static const Color primaryDark = Color(0xFF15803D);   // green-700
  static const Color primaryLight = Color(0xFFDCFCE7);  // green-100
  static const Color primarySurface = Color(0xFFF0FDF4); // green-50

  static const Color secondary = Color(0xFF0D9488);     // teal-600
  static const Color accent = Color(0xFF7C3AED);        // purple-600

  static const Color textDark = Color(0xFF111827);      // gray-900
  static const Color textMedium = Color(0xFF4B5563);    // gray-600
  static const Color textLight = Color(0xFF9CA3AF);     // gray-400

  static const Color border = Color(0xFFE5E7EB);        // gray-200
  static const Color surface = Color(0xFFF9FAFB);       // gray-50
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Tree health colors
  static const Color healthExcellent = Color(0xFF16A34A);
  static const Color healthGood = Color(0xFF65A30D);
  static const Color healthFair = Color(0xFFF59E0B);
  static const Color healthPoor = Color(0xFFEF4444);
}
