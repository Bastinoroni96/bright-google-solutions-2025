// lib/app.dart (fixed)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/navigation_service.dart';
import 'services/app_lifecycle_service.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

class PatchPalApp extends StatefulWidget {
  const PatchPalApp({Key? key}) : super(key: key);

  @override
  State<PatchPalApp> createState() => _PatchPalAppState();
}

class _PatchPalAppState extends State<PatchPalApp> {
  final AppLifecycleService _lifecycleService = AppLifecycleService();

  @override
  void initState() {
    super.initState();
    _lifecycleService.initialize();
    
    // Remove any code related to PatchPalDataInitializer here
    // The data generation is now handled in the AuthProvider._init() method
  }

  @override
  void dispose() {
    _lifecycleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PatchPal',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}