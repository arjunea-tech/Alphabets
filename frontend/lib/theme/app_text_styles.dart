import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get brandTitle => GoogleFonts.catamaran(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
        letterSpacing: 0.5,
      );

  static TextStyle get screenTitle => GoogleFonts.catamaran(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      );

  static TextStyle get cardTitle => GoogleFonts.catamaran(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get cardSubtitle => GoogleFonts.catamaran(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.3,
      );

  static TextStyle get tamilLetterLarge => GoogleFonts.catamaran(
        fontSize: 72,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
        height: 1.1,
      );

  static TextStyle get tamilLetterMedium => GoogleFonts.catamaran(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      );

  static TextStyle get tamilLetterSmall => GoogleFonts.catamaran(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get wordLarge => GoogleFonts.catamaran(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      );

  static TextStyle get buttonText => GoogleFonts.catamaran(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyText => GoogleFonts.catamaran(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        height: 1.4,
      );

  static TextStyle get bodyTextBold => GoogleFonts.catamaran(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get tagLine => GoogleFonts.catamaran(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
        fontStyle: FontStyle.italic,
      );
}
