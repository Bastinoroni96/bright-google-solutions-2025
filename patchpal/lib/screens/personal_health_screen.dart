// lib/screens/personal_health_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/patch_service.dart';
import '../models/health_summary_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/constants.dart';

class PersonalHealthScreen extends StatefulWidget {
  const PersonalHealthScreen({Key? key}) : super(key: key);

  @override
  State<PersonalHealthScreen> createState() => _PersonalHealthScreenState();
}

class _PersonalHealthScreenState extends State<PersonalHealthScreen> {
  final PatchService _patchService = PatchService();
  NavItem _currentNavItem = NavItem.dashboard;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  HealthSummaryModel? _healthSummary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHealthSummary();
  }

  Future<void> _loadHealthSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to get from Firestore
      final summary = await _patchService.getHealthSummaryForDate(_selectedDate);
      
      // If not found, generate simulated data
      if (summary == null) {
        // Default to healthy state, but occasionally show warning
        final random = DateTime.now().millisecondsSinceEpoch;
        String healthState = 'normal';
        
        // Today and yesterday always show as normal (green)
        final today = DateTime.now();
        final isRecentDay = _selectedDate.year == today.year && 
                            _selectedDate.month == today.month &&
                            (_selectedDate.day == today.day || 
                             _selectedDate.day == today.day - 1);
                             
        // April 14 shows yellow as per the design
        final isApril14 = _selectedDate.month == 4 && _selectedDate.day == 14;
        
        if (isApril14) {
          healthState = 'warning';
        } else if (!isRecentDay && random % 5 == 0) {
          // 20% chance of showing warning for older dates
          healthState = 'warning';
        }
        
        final simulatedSummary = await _patchService.generateSimulatedHealthSummary(
          healthState: healthState
        );
        
        setState(() {
          _healthSummary = simulatedSummary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _healthSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load health summary: $e';
        _isLoading = false;
      });
    }
  }

  void _handleNavigation(NavItem item) {
    setState(() {
      _currentNavItem = item;
    });
    // In the future, navigate to different screens based on the selected item
  }

  void _handleDateChange(int daysToAdd) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
    });
    _loadHealthSummary();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'TODAY';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'YESTERDAY';
    } else {
      return DateFormat('MMMM d').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button and date selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  // Date selector
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF1E88C9),
                        ),
                        onPressed: () => _handleDateChange(-1),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88C9),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1E88C9),
                        ),
                        onPressed: () {
                          // Don't allow selecting future dates
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          if (_selectedDate.isBefore(today)) {
                            _handleDateChange(1);
                          }
                        },
                      ),
                    ],
                  ),
                  
                  // Empty space to balance layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Health status
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _buildHealthSummary(),
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

  Widget _buildHealthSummary() {
    if (_healthSummary == null) {
      return const Center(child: Text('No health data available for this date'));
    }

    // Color mapping for health status
    final statusColor = _healthSummary!.status == HealthStatus.green
        ? Colors.green
        : _healthSummary!.status == HealthStatus.yellow
            ? Colors.yellow
            : Colors.red;
            
    // Icon for health status
    final statusIcon = _healthSummary!.status == HealthStatus.green
        ? '😊'
        : _healthSummary!.status == HealthStatus.yellow
            ? '😐'
            : '😟';
            
    // Status text
    final statusText = _healthSummary!.status == HealthStatus.green
        ? 'GREEN'
        : _healthSummary!.status == HealthStatus.yellow
            ? 'YELLOW'
            : 'RED';
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Health Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'PERSONAL HEALTH STATUS: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Health status indicator bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The bar background
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    // The color sections
                    child: Row(
                      children: [
                        // Red section
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        // Yellow section
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Colors.yellow,
                          ),
                        ),
                        // Green section
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The status indicator
                  Positioned(
                    // Calculate position based on status
                    left: _healthSummary!.status == HealthStatus.green
                        ? null // Not on left
                        : _healthSummary!.status == HealthStatus.yellow
                            ? MediaQuery.of(context).size.width / 2 - 40 // Center
                            : 20, // Left (red)
                    right: _healthSummary!.status == HealthStatus.green
                        ? 20 // Right
                        : null, // Not on right
                    top: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          statusIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Scan Summary Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan Summary Header
                    const Text(
                      'Scan Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88C9),
                      ),
                    ),
                    const Divider(color: Color(0xFF1E88C9)),
                    
                    // Summary text with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _healthSummary!.status == HealthStatus.green
                                ? Icons.check
                                : Icons.warning,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Summary text
                        Expanded(
                          child: Text(
                            _healthSummary!.summaryText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vital signs - using Wrap to prevent overflow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temperature row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Temperature: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_healthSummary!.vitalSigns['temperature'].toStringAsFixed(1)} °C',
                                style: TextStyle(
                                  color: _healthSummary!.vitalSigns['temperature'] >= 37.2
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                              if (_healthSummary!.vitalSigns['temperature'] >= 37.2)
                                Text(
                                  ' (${_healthSummary!.vitalSigns['temperature'] >= 38.0 ? 'elevated' : 'slightly elevated'})',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Hydration row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Hydration: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _healthSummary!.vitalSigns['hydrationLevel'],
                                style: TextStyle(
                                  color: _healthSummary!.vitalSigns['hydrationLevel'] != 'Normal'
                                      ? Colors.orange
                                      : Colors.black,
                                ),
                              ),
                              if (_healthSummary!.vitalSigns['hydrationLevel'] != 'Normal')
                                Text(
                                  ' (${_healthSummary!.vitalSigns['hydrationLevel'] == 'Borderline' ? 'early signs of dehydration' : 'dehydration'})',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Pulse row
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Pulse: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_healthSummary!.vitalSigns['heartRate'].toString()} bpm',
                                style: TextStyle(
                                  color: _healthSummary!.vitalSigns['heartRate'] >= 90
                                      ? Colors.orange
                                      : Colors.black,
                                ),
                              ),
                              if (_healthSummary!.vitalSigns['heartRate'] >= 90)
                                Text(
                                  ' (${_healthSummary!.vitalSigns['heartRate'] >= 100 ? 'elevated resting rate' : 'slightly elevated'})',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (_healthSummary!.alertsTriggered.isEmpty && _healthSummary!.status == HealthStatus.green)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'No unusual signs detected this time.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    if (_healthSummary!.status == HealthStatus.yellow || _healthSummary!.status == HealthStatus.red)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Subtle upward shift in temperature and pulse over the last few hours.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: _healthSummary!.status == HealthStatus.red ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 30),
                    
                    // Health Advice Section
                    const Text(
                      'Health Advice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88C9),
                      ),
                    ),
                    const Divider(color: Color(0xFF1E88C9)),
                    
                    Text(
                      _healthSummary!.adviceText,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    
                    // If yellow status, add bullet points with specific advice
                    if (_healthSummary!.status == HealthStatus.yellow || _healthSummary!.status == HealthStatus.red)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                const Expanded(
                                  child: Text(
                                    'Drink water regularly and avoid intense physical activity for now.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                const Expanded(
                                  child: Text(
                                    'Get rest and observe for symptoms like headache, chills, or general discomfort.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                        
                    if (_healthSummary!.status == HealthStatus.yellow || _healthSummary!.status == HealthStatus.red)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'If your temperature rises above 38°C or your symptoms worsen, contact your healthcare provider.',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}