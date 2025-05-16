// lib/screens/home_screen.dart (updated to navigate to personal health screen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/patchpal_logo.dart';
import '../widgets/bottom_nav_bar.dart';
import 'login_screen.dart';
import 'healthcare_professional_home_screen.dart';
import '../screens/personal_health_screen.dart'; 


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    
    // Check if user is personal type
    if (authProvider.userModel != null && 
        authProvider.userModel!.accountType != 'personal') {
      // Redirect to healthcare professional home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthcareProfessionalHomeScreen()),
        );
      });
      
      // Show loading while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Get the user's name
    final String userName = authProvider.userModel?.fullName ?? 'User';
    
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
                  'Hi, $userName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88C9),
                  ),
                ),
              ),
            ),
            
            // Question text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Whose health do you want to monitor?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // Expanded area with options on a light blue background
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Personal option
                    _buildOptionCard(
                      icon: Icons.person,
                      title: 'Personal',
                      onTap: () {
                        // Navigate to the personal health screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalHealthScreen()),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Family option
                    _buildOptionCard(
                      icon: Icons.family_restroom,
                      title: 'Family',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Family monitoring coming soon')),
                        );
                      },
                    ),
                  ],
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

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1E88C9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1E88C9),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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