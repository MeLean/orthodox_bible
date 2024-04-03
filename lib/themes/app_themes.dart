import 'package:flutter/material.dart';

class AppThemes {
  static final light = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color.fromARGB(255, 100, 149, 237),
      secondary: Colors.white,
      tertiary: Colors.grey,
      onPrimary: Colors.black,
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final dark = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 100, 149, 237),
      secondary: Colors.black,
      tertiary: Colors.grey,
      onPrimary: Colors.white,
      brightness: Brightness.light,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
