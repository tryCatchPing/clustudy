import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTypography {
  // Title: Play, 36px, Bold & Regular
  static final TextStyle title1 = GoogleFonts.play(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle title2 = GoogleFonts.play(
    fontSize: 36,
    fontWeight: FontWeight.normal,
  );

  // Subtitle: Pretendard, 17px, Semibold & Regular
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 17,
    fontWeight: FontWeight.w600, // SemiBold
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 17,
    fontWeight: FontWeight.normal,
  );

  // Body: Pretendard, 16px & 13px, Bold, Semibold, Regular
  static const TextStyle body1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w600, // SemiBold
  );

  static const TextStyle body3 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle body4 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w600, // SemiBold
  );

  static const TextStyle body5 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );

  // Caption: Pretendard, 10px, Regular
  static const TextStyle caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );
}
