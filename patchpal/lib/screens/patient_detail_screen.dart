// lib/screens/patient_detail_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/healthcare_nav_bar.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  
  const PatientDetailScreen({
    Key? key, 
    required this.patientId, 
    required this.patientName,
  }) : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _latestHealthSummary;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }
  
  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get patient profile data
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.patientId)
          .get();
      
      if (userDoc.exists) {
        _patientData = userDoc.data();
      }
      
      // Get health summary for selected date
      final DateTime startOfDay = DateTime(
        _selectedDate.year, 
        _selectedDate.month, 
        _selectedDate.day
      );
      
      final DateTime endOfDay = DateTime(
        _selectedDate.year, 
        _selectedDate.month, 
        _selectedDate.day, 
        23, 59, 59
      );
      
      final summariesSnapshot = await _firestore
          .collection('health_summaries')
          .where('userId', isEqualTo: widget.patientId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (summariesSnapshot.docs.isNotEmpty) {
        _latestHealthSummary = summariesSnapshot.docs.first.data();
      } else {
        // If no data for selected date, get the most recent entry
        final recentSummary = await _firestore
            .collection('health_summaries')
            .where('userId', isEqualTo: widget.patientId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
            
        if (recentSummary.docs.isNotEmpty) {
          _latestHealthSummary = recentSummary.docs.first.data();
          // Update selected date to match the most recent entry
          final timestamp = recentSummary.docs.first.data()['timestamp'] as Timestamp;
          _selectedDate = timestamp.toDate();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patient data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadPatientData();
  }
  
  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selectedDay == today) {
      return 'TODAY';
    } else if (selectedDay == yesterday) {
      return 'YESTERDAY';
    } else {
      return DateFormat('MMMM d').format(_selectedDate);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Date selector and profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back and forward date buttons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 30),
                                onPressed: () => _changeDate(-1),
                              ),
                              Text(
                                _getDateLabel(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 30),
                                onPressed: () {
                                  // Don't allow selecting future dates
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                  
                                  if (selectedDay.isBefore(today)) {
                                    _changeDate(1);
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          // Profile image
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue,
                            child: Text(
                              "J",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Patient profile
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        widget.patientName.isNotEmpty 
                            ? widget.patientName[0].toUpperCase() 
                            : 'J',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Patient name
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF673AB7), // Purple color
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Health status indicator
                    if (_latestHealthSummary != null) ...[
                      // Status button
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getStatusColor(_latestHealthSummary!['colorCode']),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Status text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'HEALTH STATUS: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStatusText(_latestHealthSummary!['colorCode']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_latestHealthSummary!['colorCode']),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Patient info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Left column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gender:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _patientData?['additionalInfo']?['gender'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Age:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _patientData?['additionalInfo']?['age'] != null
                                        ? '${_patientData!['additionalInfo']['age']} Years'
                                        : 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Right column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Blood Type:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _patientData?['additionalInfo']?['bloodType'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Weight:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _patientData?['additionalInfo']?['weight'] != null
                                        ? '${_patientData!['additionalInfo']['weight']} Kg'
                                        : 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Scan summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Scan Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Divider(
                                    color: Colors.blue,
                                    thickness: 2,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Vitals healthy indicator
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Your vitals look healthy.',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Vital signs
                            if (_latestHealthSummary?['vitalSigns'] != null) ...[
                              Text(
                                'Temperature: ${_latestHealthSummary!['vitalSigns']['temperature']?.toStringAsFixed(1) ?? 'N/A'} C',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hydration: ${_getHydrationText(_latestHealthSummary!['vitalSigns']['hydrationLevel'])}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pulse: ${_latestHealthSummary!['vitalSigns']['heartRate'] ?? 'N/A'} bpm',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No unusual signs detected this time.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                            
                            // Health advice
                            Row(
                              children: [
                                Text(
                                  'Health Advice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Divider(
                                    color: Colors.blue,
                                    thickness: 2,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Advice text
                            if (_latestHealthSummary?['advice'] != null) ...[
                              Text(
                                _getAdviceText(_latestHealthSummary!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                            
                            // Add extra space at the bottom to avoid overflow
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                    
                    // If no health summary data
                    if (_latestHealthSummary == null) ...[
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No health data available for this date',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: HealthcareNavBar(
        currentIndex: 4, // Patients tab
        onTap: (index) {
          // Handle navigation
          if (index != 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
  
  Color _getStatusColor(String? colorCode) {
    if (colorCode == null) return Colors.grey;
    
    switch (colorCode.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String? colorCode) {
    if (colorCode == null) return 'UNKNOWN';
    
    return colorCode.toUpperCase();
  }
  
  String _getHydrationText(dynamic hydrationLevel) {
    if (hydrationLevel == null) return 'Unknown';
    
    int level = hydrationLevel is int ? hydrationLevel : int.tryParse(hydrationLevel.toString()) ?? 0;
    
    if (level >= 70) {
      return 'Normal';
    } else if (level >= 50) {
      return 'Moderate';
    } else {
      return 'Low';
    }
  }
  
  String _getAdviceText(Map<String, dynamic> healthSummary) {
    // Extract the advice recommendations and format them into a paragraph
    if (healthSummary['advice'] == null) {
      return 'No health advice available.';
    }
    
    final advice = healthSummary['advice'];
    
    // Start with the summary
    String adviceText = advice['summary'] ?? '';
    
    // Add recommendations
    if (advice['recommendations'] != null && (advice['recommendations'] as List).isNotEmpty) {
      // Just combine the first few recommendations into a nice paragraph
      adviceText += ' ' + (advice['recommendations'] as List)
          .take(3)
          .join(' ');
    }
    
    // Add next check-up recommendation
    adviceText += ' Your next check-up is recommended in 30 days.';
    
    return adviceText;
  }
}