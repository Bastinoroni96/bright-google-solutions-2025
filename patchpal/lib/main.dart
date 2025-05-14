// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this import
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the options from firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
  );
  
  // Sign out on app start (for development purposes)
  await FirebaseAuth.instance.signOut();
  print('User signed out on app start');
  
  // Test Firestore connection
  try {
    await FirebaseFirestore.instance.collection('test').doc('test').set({
      'timestamp': FieldValue.serverTimestamp(),
      'test': 'This is a test'
    });
    print('Firestore connection successful');
  } catch (e) {
    print('Firestore connection test failed: $e');
  }
  
  runApp(const PatchPalApp());
}