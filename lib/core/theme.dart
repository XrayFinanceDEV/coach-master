import 'package:flutter/material.dart';

const primaryColor = Color(0xFFFF5722);
const secondaryColor = Color(0xFF607D8B);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    secondary: secondaryColor,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
  ),
);
