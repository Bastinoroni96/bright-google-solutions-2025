// lib/services/app_lifecycle_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || 
        state == AppLifecycleState.paused) {
      // Sign out user when app is closed or put in background
      _auth.signOut();
    }
  }
}