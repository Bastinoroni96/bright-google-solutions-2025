import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart' as app_auth;
import '../widgets/healthcare_nav_bar.dart';
import 'patient_detail_screen.dart';
import 'triage_screen.dart';

class HealthcareProfessionalHomeScreen extends StatefulWidget {
  const HealthcareProfessionalHomeScreen({Key? key}) : super(key: key);

  @override
  State<HealthcareProfessionalHomeScreen> createState() => _HealthcareProfessionalHomeScreenState();
}

class _HealthcareProfessionalHomeScreenState extends State<HealthcareProfessionalHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<String> _statusFilters = ['Red', 'Yellow', 'Green']; // All selected by default
  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadPatients();
  }
  
  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all personal users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'personal')
          .get();
      
      List<Map<String, dynamic>> patients = [];
      
      // For each user, get their latest health summary
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        
        // Get latest health summary
        final summariesSnapshot = await _firestore
            .collection('health_summaries')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        Map<String, dynamic> healthData = {};
        
        if (summariesSnapshot.docs.isNotEmpty) {
          healthData = summariesSnapshot.docs.first.data();
        }
        
        // Create patient data object
        patients.add({
          'userId': userId,
          'fullName': userData['fullName'] ?? 'Unknown',
          'status': healthData['status'] ?? 'unknown',
          'colorCode': healthData['colorCode'] ?? 'grey',
          'lastUpdateTime': healthData['timestamp'] != null 
              ? (healthData['timestamp'] as Timestamp).toDate() 
              : null,
          'statusMessage': _getStatusMessage(healthData['status'], healthData['alertsTriggered']),
          'profileImage': userData['profileImage'] ?? '',
        });
      }
      
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _getStatusMessage(String? status, List<dynamic>? alerts) {
    if (status == null) return 'No data available.';
    
    switch (status) {
      case 'critical':
        return alerts != null && alerts.isNotEmpty 
            ? 'Needs urgent help. ${alerts.first}' 
            : 'Needs urgent help. Contact nearby medic.';
      case 'warning':
        return alerts != null && alerts.isNotEmpty 
            ? 'Some early warning signs are showing.' 
            : 'Some early warning signs are showing.';
      case 'normal':
        return 'No unusual signs detected. Healthy.';
      default:
        return 'Status unknown.';
    }
  }
  
  String _formatTime(DateTime? time) {
    if (time == null) return 'Unknown';
    
    // Check if it's today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(time.year, time.month, time.day);
    
    if (dateToCheck == today) {
      // Format as time only
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}PM';
    } else {
      // Format as date
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}PM';
    }
  }
  
  // Convert status string to Color
  Color _getStatusColor(String colorCode) {
    switch (colorCode) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.amber;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Filter patients based on status filter and search query
    final filteredPatients = _patients.where((patient) {
      // First apply status filter
      final statusMatches = _statusFilters.contains(
        patient['colorCode'].toString().toLowerCase() == 'red' ? 'Red' :
        patient['colorCode'].toString().toLowerCase() == 'yellow' ? 'Yellow' :
        patient['colorCode'].toString().toLowerCase() == 'green' ? 'Green' : ''
      );
      
      // Then apply search filter if there is one
      final nameMatches = _searchQuery.isEmpty || 
        patient['fullName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      return statusMatches && nameMatches;
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade700,
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                // Show profile or logout options
                _showProfileOptions(context);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.menu, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Find Patient',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.grey),
                    onPressed: () {
                      // Trigger search (optional - already searching on type)
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Health Status Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusFilterChip('Red'),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Yellow'),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Green'),
                  ],
                ),
              ],
            ),
          ),
          
          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? const Center(child: Text('No patients found.'))
                    : ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return _buildPatientListItem(patient);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: HealthcareNavBar(
        currentIndex: 0, // Dashboard is selected
        onTap: (index) {
          // Handle navigation
          if (index == 1) { // Triage
            print('Navigating to Triage screen...');
            // Navigate to triage screen with pushReplacement
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TriageScreen()),
            );
          } else if (index == 2) { // Scan
            // Handle scan action
            _showScanDialog();
          } else if (index == 3) { // Alerts
            // Navigate to alerts screen
            print('Alerts screen not yet implemented');
          } else if (index == 4) { // Patients
            // Navigate to patients screen
            print('Patients screen not yet implemented');
          }
        },
      ),
    );
  }
  
  void _showScanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan'),
          content: const Text('Scan functionality would be implemented here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatusFilterChip(String status) {
    final isSelected = _statusFilters.contains(status);
    final Color chipColor = status == 'Red' 
        ? Colors.red 
        : status == 'Yellow' 
            ? Colors.amber 
            : Colors.green;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _statusFilters.remove(status);
          } else {
            _statusFilters.add(status);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          border: Border.all(color: chipColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPatientListItem(Map<String, dynamic> patient) {
    final statusColor = _getStatusColor(patient['colorCode'].toString().toLowerCase());
    final statusMessage = patient['statusMessage'] ?? 'No data available';
    final lastUpdate = patient['lastUpdateTime'] != null 
        ? 'Last Update: ${_formatTime(patient['lastUpdateTime'])}'
        : 'Last Update: Unknown';
    
    // Get a default profile image if none exists
    Widget profileImage;
    if (patient['profileImage'] != null && patient['profileImage'].toString().isNotEmpty) {
      profileImage = CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(patient['profileImage']),
      );
    } else {
      // Use a placeholder image
      profileImage = CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue.shade100,
        child: Text(
          patient['fullName'].toString().isNotEmpty 
              ? patient['fullName'].toString().substring(0, 1).toUpperCase() 
              : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: profileImage,
        title: Text(
          patient['fullName'] ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Status: '),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  patient['colorCode'].toString().toLowerCase() == 'red' ? 'Red' :
                  patient['colorCode'].toString().toLowerCase() == 'yellow' ? 'Yellow' :
                  patient['colorCode'].toString().toLowerCase() == 'green' ? 'Green' : 'Unknown',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(statusMessage),
            Text(
              lastUpdate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // Navigate to patient details screen
            _navigateToPatientDetails(patient);
          },
        ),
        onTap: () {
          // Navigate to patient details screen
          _navigateToPatientDetails(patient);
        },
      ),
    );
  }
  
  void _navigateToPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patientId: patient['userId'],
          patientName: patient['fullName'],
        ),
      ),
    );
  }
  
  void _showProfileOptions(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  authProvider.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}