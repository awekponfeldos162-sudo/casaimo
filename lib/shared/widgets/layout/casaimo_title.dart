import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CasaimoTitle extends StatelessWidget {
  final double fontSize;

  const CasaimoTitle({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final imgSize = fontSize * 1.35;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'CASAIM',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 3,
            fontFamily: 'Poppins',
            height: 1,
          ),
        ),
        Image.asset(
          'assets/images/logo1.png',
          width: imgSize,
          height: imgSize,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
