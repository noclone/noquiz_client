import 'package:flutter/material.dart';

class AppColors {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  AppColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  });
}

final AppColors lightColors = AppColors(
  primaryColor: const Color(0xFF00416A),
  secondaryColor: const Color(0xFF0095B6),
  tertiaryColor: Colors.white,
  textPrimaryColor: Colors.white,
  textSecondaryColor: Colors.grey,
);

final AppColors darkColors = AppColors(
  primaryColor: Colors.black,
  secondaryColor: const Color(0xFFFF9800),
  tertiaryColor: Colors.white,
  textPrimaryColor: Colors.white,
  textSecondaryColor: Colors.grey,
);