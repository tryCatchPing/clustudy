import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFEFCF3);
  static const Color primary = Color(0xFF182955);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray10 = Color(0xFFF8F8F8);
  static const Color gray20 = Color(0xFFD1D1D1);
  static const Color gray30 = Color(0xFFA8A8A8);
  static const Color gray40 = Color(0xFF656565);
  static const Color gray50 = Color(0xFF1F1F1F);

  static const Color penBlack = Color(0x00000000);
  static const Color penRed    = Color(0xFFC72C2C);
  static const Color penBlue   = Color(0xFF1A5DBA);
  static const Color penGreen  = Color(0xFF277A3E);
  static const Color penYellow = Color(0xFFFFFF46);

  static const List<Color> penColors = [
    penBlack,
    penRed,
    penBlue,
    penGreen,
    penYellow,
  ];

  static final List<Color> highlighterColors = penColors
      .map((color) => color.withOpacity(0.5))
      .toList();
}
