// lib/screens/auth_wrapper.dart (fixed)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_generator.dart'; // Add this import
import 'home_screen.dart';
import 'healthcare_professional_home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show loading indicator while determining auth state
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Debug logs
    print('Auth state: ${authProvider.isAuthenticated}');
    print('User: ${authProvider.user}');
    
    // Navigate based on authentication state
    if (authProvider.isAuthenticated) {
      // If user is authenticated, check their account type
      
      // Initialize sample data if needed, but only for personal users
      if (authProvider.userModel?.accountType == 'personal') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SampleDataGenerator().generateDataIfNeeded(); // Fixed this line
          print('Initializing sample data for personal user: ${authProvider.userModel?.fullName}');
        });
      }
      
      if (authProvider.userModel?.accountType == 'healthcare_professional') {
        return const HealthcareProfessionalHomeScreen();
      } else {
        // Default to personal user home screen
        return const HomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}