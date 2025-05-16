import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/healthcare_professional_home_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Debug logs
        print('Auth state: ${snapshot.hasData}');
        print('User: ${snapshot.data}');

        // Navigate based on authentication state
        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated, fetch user type to decide which screen to show
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If user document exists and has accountType field
              if (userSnapshot.hasData && 
                  userSnapshot.data != null && 
                  userSnapshot.data!.exists) {
                
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final accountType = userData?['accountType'] as String?;
                
                print('User account type: $accountType');
                
                // Route based on account type
                if (accountType == 'healthcare_professional') {
                  return const HealthcareProfessionalHomeScreen();
                } else {
                  // Default to personal user home screen
                  return const HomeScreen();
                }
              } else {
                // If user document doesn't exist or has no accountType,
                // sign out and go to login
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }
            },
          );
        } else {
          // User is not authenticated
          return const LoginScreen();
        }
      },
    );
  }
}