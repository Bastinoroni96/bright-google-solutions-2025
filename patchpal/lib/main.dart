import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const PatchPalApp());
}

class PatchPalApp extends StatelessWidget {
  const PatchPalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PatchPal',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}