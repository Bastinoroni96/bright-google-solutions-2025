import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';

void main() => runApp(const PatchPalApp());

class PatchPalApp extends StatelessWidget {
  const PatchPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PatchPal',
      debugShowCheckedModeBanner: false,
      home: const LoadingScreen(),
    );
  }
}
