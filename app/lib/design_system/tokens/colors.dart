import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Emerald (Primary Brand) ===
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);

  // === Teal ===
  static const teal500 = Color(0xFF14B8A6);

  // === Gray ===
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // === Blue (부동산 카테고리) ===
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue900 = Color(0xFF1E3A8A);

  // === Green (주식/투자 카테고리) ===
  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);

  // === Purple (현금/예금 카테고리) ===
  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple600 = Color(0xFF9333EA);

  // === Red (부채/지출) ===
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red900 = Color(0xFF7F1D1D);

  // === Orange ===
  static const orange50 = Color(0xFFFFF7ED);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange200 = Color(0xFFFED7AA);
  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);
  static const orange700 = Color(0xFFC2410C);

  // === Indigo ===
  static const indigo50 = Color(0xFFEEF2FF);

  // === Semantic Colors ===
  static const success = emerald600;
  static const error = red600;
  static const warning = Color(0xFFF59E0B);
  static const info = blue600;

  // === Surface ===
  static const background = gray50;
  static const surface = Colors.white;
  static const surfaceDim = gray100;
  static const scrim = Color(0x80000000); // black/50

  // === Category Color Sets ===
  static const Map<String, CategoryColors> category = {
    'blue': CategoryColors(
      bg: blue600,
      text: blue600,
      light: blue50,
      hex: blue600,
    ),
    'green': CategoryColors(
      bg: green600,
      text: green600,
      light: green50,
      hex: green600,
    ),
    'purple': CategoryColors(
      bg: purple600,
      text: purple600,
      light: purple50,
      hex: purple600,
    ),
    'red': CategoryColors(
      bg: red600,
      text: red600,
      light: red50,
      hex: red600,
    ),
  };
}

class CategoryColors {
  final Color bg;
  final Color text;
  final Color light;
  final Color hex;

  const CategoryColors({
    required this.bg,
    required this.text,
    required this.light,
    required this.hex,
  });
}
