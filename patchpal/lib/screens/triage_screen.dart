import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/healthcare_nav_bar.dart';
import 'healthcare_professional_home_screen.dart'; // Add import for return navigation

class TriageScreen extends StatefulWidget {
  const TriageScreen({Key? key}) : super(key: key);

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingPatients = [];
  List<Map<String, dynamic>> _completedPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Handle bottom navigation
  void _handleNavigation(int index) {
    print('Navigation tapped: $index');
    
    if (index == 0) { // Dashboard - navigate back to home screen
      print('Navigating to Dashboard');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HealthcareProfessionalHomeScreen()),
      );
    } else if (index == 1) { // Already on Triage
      // Do nothing, already on this screen
    } else if (index == 2) { // Scan
      _handleScan();
    } else if (index == 3) { // Alerts
      print('Alerts screen not yet implemented');
      // Navigate to alerts when implemented
    } else if (index == 4) { // Patients
      print('Patients screen not yet implemented');
      // Navigate to patients when implemented
    }
  }
  
  void _handleScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: const Text('Scanning functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all personal users (patients)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('accountType', isEqualTo: 'personal')
          .get();

      List<Map<String, dynamic>> pendingPatients = [];
      List<Map<String, dynamic>> completedPatients = [];

      // For each user, get their most recent health summary
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        // Get the most recent health summary
        final healthSummariesSnapshot = await FirebaseFirestore.instance
            .collection('health_summaries')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (healthSummariesSnapshot.docs.isNotEmpty) {
          final summaryData = healthSummariesSnapshot.docs.first.data();
          
          // Combine user data with health summary
          final patientData = {
            'userId': userId,
            'name': userData['fullName'] ?? 'Unknown Patient',
            'status': summaryData['status'] ?? 'normal',
            'colorCode': summaryData['colorCode'] ?? 'green',
            'image': userData['profileImage'], // Might be null
            'vitalSigns': summaryData['vitalSigns'] ?? {},
            'queueNumber': summaryData['queueNumber'],
            'isCompleted': summaryData['isCompleted'] ?? false,
            'summaryId': healthSummariesSnapshot.docs.first.id,
            'timestamp': summaryData['timestamp'],
          };

          // Determine critical issue to display
          String criticalIssue = '';
          final vitalSigns = summaryData['vitalSigns'] ?? {};
          
          if (patientData['colorCode'] == 'red' || patientData['status'] == 'critical') {
            if (vitalSigns['temperature'] != null && vitalSigns['temperature'] >= 38.0) {
              criticalIssue = 'High Fever';
            } else if (vitalSigns['heartRate'] != null && vitalSigns['heartRate'] >= 100) {
              criticalIssue = 'High Pulse';
            } else if (vitalSigns['hydration'] != null && vitalSigns['hydration'] < 50) {
              criticalIssue = 'Severe Hydration';
            }
          } else if (patientData['colorCode'] == 'yellow' || patientData['status'] == 'warning') {
            if (vitalSigns['heartRate'] != null && vitalSigns['heartRate'] >= 90) {
              criticalIssue = 'Pulse: ${vitalSigns['heartRate']}. Slightly elevated';
            } else if (vitalSigns['hydration'] != null && vitalSigns['hydration'] < 70) {
              criticalIssue = 'Slightly low hydration';
            } else if (vitalSigns['temperature'] != null && vitalSigns['temperature'] >= 37.2) {
              criticalIssue = 'Slightly elevated temperature';
            }
          }
          
          patientData['criticalIssue'] = criticalIssue;

          // Add to either pending or completed list
          if (patientData['isCompleted'] == true) {
            completedPatients.add(patientData);
          } else {
            pendingPatients.add(patientData);
          }
        }
      }

      // Sort pending patients:
      // 1. Red status first
      // 2. Yellow status second
      // 3. Green status last
      pendingPatients.sort((a, b) {
        // First by status severity
        final statusOrder = {'red': 0, 'yellow': 1, 'green': 2};
        final statusA = statusOrder[a['colorCode']] ?? 3;
        final statusB = statusOrder[b['colorCode']] ?? 3;
        
        if (statusA != statusB) {
          return statusA.compareTo(statusB);
        }
        
        // Then by timestamp (more recent first)
        final timeA = a['timestamp'] as Timestamp;
        final timeB = b['timestamp'] as Timestamp;
        return timeB.compareTo(timeA);
      });

      // Assign queue numbers
      for (int i = 0; i < pendingPatients.length; i++) {
        pendingPatients[i]['queueNumber'] = i + 1;
        
        // Update the queue number in Firestore
        await FirebaseFirestore.instance
            .collection('health_summaries')
            .doc(pendingPatients[i]['summaryId'])
            .update({'queueNumber': i + 1});
      }

      // Sort completed patients by timestamp (most recent first)
      completedPatients.sort((a, b) {
        final timeA = a['timestamp'] as Timestamp;
        final timeB = b['timestamp'] as Timestamp;
        return timeB.compareTo(timeA);
      });

      setState(() {
        _pendingPatients = pendingPatients;
        _completedPatients = completedPatients;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredPatients() {
    final patients = _tabController.index == 0 ? _pendingPatients : _completedPatients;
    
    if (_searchQuery.isEmpty) {
      return patients;
    }
    
    return patients.where((patient) {
      final name = patient['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _markAsComplete(Map<String, dynamic> patient) async {
    try {
      // Update the health summary to mark as completed
      await FirebaseFirestore.instance
          .collection('health_summaries')
          .doc(patient['summaryId'])
          .update({
        'isCompleted': true,
        'queueNumber': null,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the patient lists
      await _fetchPatients();
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient['name']} marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error marking patient as complete: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Failed to update patient status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: const Text(
          'Do you want to mark this patient as complete? Doing this would reset the Queue Number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsComplete(patient);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2794B8),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String colorCode) {
    switch (colorCode.toLowerCase()) {
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
    final filteredPatients = _getFilteredPatients();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Triage',
          style: TextStyle(
            color: Color(0xFF2794B8),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2794B8),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: PatchPalLogo(size: 36),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2794B8),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2794B8),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Find Patient',
                prefixIcon: Icon(Icons.menu),
                suffixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'April 15, 2025',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          
          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          _tabController.index == 0
                              ? 'No pending patients'
                              : 'No completed patients',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: HealthcareNavBar(
        currentIndex: 1, // Triage is selected
        onTap: _handleNavigation, // Use the navigation handler
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Patient image
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: patient['image'] != null
                  ? NetworkImage(patient['image'])
                  : null,
              child: patient['image'] == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Status: '),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(patient['colorCode']),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient['colorCode'].toString().capitalize(),
                        style: TextStyle(
                          color: _getStatusColor(patient['colorCode']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient['criticalIssue'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (patient['queueNumber'] != null)
                    Text(
                      'Queue Number: ${patient['queueNumber']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_tabController.index == 0) {
                      _showConfirmationDialog(patient);
                    }
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      _tabController.index == 0 ? Icons.check : Icons.check_circle,
                      size: 20,
                      color: _tabController.index == 0 ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Navigate to patient detail
                  },
                  child: Icon(
                    Icons.open_in_full,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Simple extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

// Add the PatchPal logo here
class PatchPalLogo extends StatelessWidget {
  final double size;
  
  const PatchPalLogo({
    Key? key,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colors from the image
    final Color lightBlue = Color(0xFF67C0EA);   // Light blue
    final Color darkBlue = Color(0xFF2794B8);    // Darker teal blue
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CrossLogoPainter(
          lightBlue: lightBlue,
          darkBlue: darkBlue,
          cornerRadius: size / 10,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class CrossLogoPainter extends CustomPainter {
  final Color lightBlue;
  final Color darkBlue;
  final double cornerRadius;

  CrossLogoPainter({
    required this.lightBlue,
    required this.darkBlue,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double armWidth = size.width / 3;
    
    // Draw horizontal arm (light blue)
    final horizontalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 3, size.width, armWidth),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(horizontalRect, Paint()..color = lightBlue);
    
    // Draw vertical arm (light blue)
    final verticalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 3, 0, armWidth, size.height),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(verticalRect, Paint()..color = lightBlue);
    
    // Draw dark blue top-right section (including rounded corner)
    final topRightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 3, 0, size.width * 2/3, size.height / 3),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(topRightRect, Paint()..color = darkBlue);
    
    // Draw dark blue right section (including rounded corner)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 2/3, size.height / 3, size.width / 3, armWidth),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rightRect, Paint()..color = darkBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}