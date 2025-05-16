import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF00486D);
  static const Color primaryLight = Color(0xFF0099CC);
  static const Color accentColor = Color(0xFF5DC8E3);
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryLight],
  );
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subheading = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );
  
  static const TextStyle inputLabel = TextStyle(
    color: Colors.white,
    fontSize: 16,
  );
}