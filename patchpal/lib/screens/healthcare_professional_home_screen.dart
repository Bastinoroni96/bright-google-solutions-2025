// lib/screens/healthcare_professional_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/patchpal_logo.dart';
import '../widgets/bottom_nav_bar.dart';
import 'login_screen.dart';

class HealthcareProfessionalHomeScreen extends StatefulWidget {
  const HealthcareProfessionalHomeScreen({Key? key}) : super(key: key);

  @override
  State<HealthcareProfessionalHomeScreen> createState() => _HealthcareProfessionalHomeScreenState();
}

class _HealthcareProfessionalHomeScreenState extends State<HealthcareProfessionalHomeScreen> {
  NavItem _currentNavItem = NavItem.dashboard;

  void _handleNavigation(NavItem item) {
    setState(() {
      _currentNavItem = item;
    });
    // In the future, you might want to navigate to different screens based on the selected item
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is healthcare professional
    if (authProvider.userModel != null && 
        authProvider.userModel!.accountType != 'healthcare_professional') {
      // Redirect to personal user home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      
      // Show loading while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Get the healthcare professional's info
    final String name = authProvider.userModel?.fullName ?? 'Doctor';
    final Map<String, dynamic>? additionalInfo = authProvider.userModel?.additionalInfo;
    final String hospital = additionalInfo?['hospital'] ?? 'Hospital';
    final String specialty = additionalInfo?['specialty'] ?? 'Specialty';
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // PatchPal logo
                  const PatchPalLogo(size: 40),
                  
                  // Profile picture
                  GestureDetector(
                    onTap: () {
                      // Show logout option
                      _showLogoutDialog(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF005B82),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Greeting text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome, Dr. $name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88C9),
                  ),
                ),
              ),
            ),
            
            // Specialty and hospital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$specialty • $hospital',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // Expanded area with healthcare professional options
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE6F4FA),
                      Color(0xFFCEEAF7),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Your Patients',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88C9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Placeholder for patient list
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Color(0xFF1E88C9),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No patients yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88C9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your patient list will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('This feature is coming soon')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88C9),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Add Patient',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            BottomNavBar(
              currentItem: _currentNavItem,
              onItemSelected: _handleNavigation,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}