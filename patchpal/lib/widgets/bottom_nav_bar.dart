// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum NavItem {
  dashboard,
  connect,
  scan,
  history,
  replace,
}

class BottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemSelected;

  const BottomNavBar({
    Key? key,
    required this.currentItem,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E88C9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dashboard
          _buildNavItem(
            context,
            NavItem.dashboard,
            Icons.lightbulb_outline,
            'Dashboard',
          ),
          
          // Connect
          _buildNavItem(
            context,
            NavItem.connect,
            Icons.phone_outlined,
            'Connect',
          ),
          
          // Scan (center, elevated button)
          _buildScanButton(context),
          
          // History
          _buildNavItem(
            context,
            NavItem.history,
            Icons.history,
            'History',
          ),
          
          // Replace
          _buildNavItem(
            context,
            NavItem.replace,
            Icons.rotate_right,
            'Replace',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item, IconData icon, String label) {
    final isSelected = currentItem == item;
    
    return GestureDetector(
      onTap: () => onItemSelected(item),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onItemSelected(NavItem.scan),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Color(0xFF1E88C9),
          size: 28,
        ),
      ),
    );
  }
}