import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color quickbiteOrange = Color(0xFFFF6B35);
  static const Color appetiteRed = Color(0xFFD62828);
  static const Color energyYellow = Color(0xFFF7B801);

  static const Color white = Color(0xFFFFFFFF);
  static const Color mistGray = Color(0xFFF5F5F5);
  static const Color textGray = Color(0xFF4A4A4A);
  static const Color secondaryGray = Color(0xFF9E9E9E);
  static const Color softBlack = Color(0xFF1A1A1A);

  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFC62828);
  static const Color warningYellow = Color(0xFFF9A825);
  static const Color infoBlue = Color(0xFF1565C0);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double button = 12;
  static const double card = 16;
  static const double field = 8;
  static const double image = 12;
  static const double modal = 24;
  static const double chip = 20;
}

abstract final class AppSizes {
  static const double buttonHeight = 48;
  static const double fieldHeight = 56;
  static const double minTapTarget = 48;
}
