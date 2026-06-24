import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Poppins',
    color: AppColors.textPrimary,
  );

  static final displayLarge = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static final displayMedium = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);
  static final displaySmall = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

  static final headlineLarge = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static final headlineMedium = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);
  static final headlineSmall = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  static final titleLarge = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5);
  static final titleMedium = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);
  static final titleSmall = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);

  static final bodyLarge = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static final bodyMedium = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static final bodySmall = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.6);

  static final labelLarge = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.1);
  static final labelMedium = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.5);
  static final labelSmall = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.5);

  static final price = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary);
  static final priceLarge = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary);
  static final priceSmall = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary);

  static final badge = _base.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary, letterSpacing: 0.5);
  static final caption = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static final link = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary, decoration: TextDecoration.underline);
}
