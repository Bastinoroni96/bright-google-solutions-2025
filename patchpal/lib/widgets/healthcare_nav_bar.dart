// lib/widgets/healthcare_nav_bar.dart
import 'package:flutter/material.dart';

enum HealthcareNavItem {
  dashboard,
  triage,
  scan,
  alerts,
  patients,
}

class HealthcareNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HealthcareNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
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
            0,
            Icons.dashboard_outlined,
            'Dashboard',
          ),
          
          // Triage
          _buildNavItem(
            context,
            1,
            Icons.medical_services_outlined,
            'Triage',
          ),
          
          // Scan (center, elevated button)
          _buildScanButton(context),
          
          // Alerts
          _buildNavItem(
            context,
            3,
            Icons.notifications_outlined,
            'Alerts',
            badge: 1, // Set to null to hide badge
          ),
          
          // Patients
          _buildNavItem(
            context,
            4,
            Icons.people_outline,
            'Patients',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    int index, 
    IconData icon, 
    String label, 
    {int? badge}
  ) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
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
            
            // Badge for notifications/alerts
            if (badge != null)
              Positioned(
                top: 12,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(2),
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