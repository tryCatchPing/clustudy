import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTypography {
  // Title: Play, 36px, Bold & Regular
  static final TextStyle title1 = GoogleFonts.play(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 44 / 36,  // 1.22
    letterSpacing: 0,
  );

  static final TextStyle title2 = GoogleFonts.play(
    fontSize: 36,
    fontWeight: FontWeight.normal,
    height: 44 / 36,  // 1.22
    letterSpacing: 0,
  );

  // Subtitle: Pretendard, 17px, Semibold & Regular
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 17,
    fontWeight: FontWeight.w600, // SemiBold
    height: 24 / 17,  // 1.41
    letterSpacing: 0,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 24 / 17,  // 1.41
    letterSpacing: 0,
  );

  // Body: Pretendard, 16px & 13px, Bold, Semibold, Regular
  static const TextStyle body1 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 20 / 16,  // 1.25
    letterSpacing: 0,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w600, // SemiBold
    height: 20 / 16,  // 1.25
    letterSpacing: 0,
  );

  static const TextStyle body3 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 20 / 16,  // 1.25
    letterSpacing: 0,
  );

  static const TextStyle body4 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w600, // SemiBold
    height: 16 / 13,  // 1.23
    letterSpacing: 0,
  );

  static const TextStyle body5 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 16 / 13,  // 1.23
    letterSpacing: 0,
  );

  // Body 13 Bold (스펙 보강용)
  static const TextStyle body6 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 16 / 13,  // 1.23
    letterSpacing: 0,
  );

  // Caption: Pretendard, 10px, Regular
  static const TextStyle caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 12 / 10,  // 1.20
    letterSpacing: 0,
  );
}
