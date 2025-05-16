// lib/services/sample_data_generator.dart
// This is the ONLY file you need to add to your project

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple utility to generate sample data for PatchPal app on login
class SampleDataGenerator {
  // Singleton pattern for global access
  static final SampleDataGenerator _instance = SampleDataGenerator._internal();
  factory SampleDataGenerator() => _instance;
  SampleDataGenerator._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();
  
  // Cache to avoid multiple checks during app lifecycle
  final Set<String> _processedUserIds = {};
  
  /// Call this method after user login
  /// Add this to your AuthProvider._init() method
  Future<void> generateDataIfNeeded() async {
    try {
      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No user logged in. Cannot generate sample data.');
        return;
      }
      
      // Skip if already processed this user
      if (_processedUserIds.contains(user.uid)) {
        print('Already processed user ${user.uid} this session. Skipping.');
        return;
      }
      
      // Check if user is a personal user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('User document not found. Cannot determine user type.');
        return;
      }
      
      final userData = userDoc.data();
      if (userData == null || userData['accountType'] != 'personal') {
        print('Not generating data: User is not a personal user.');
        _processedUserIds.add(user.uid); // Mark as processed
        return;
      }
      
      // Check if user already has data
      final hasData = await _userHasExistingData(user.uid);
      if (hasData) {
        print('User already has data. Skipping generation.');
        _processedUserIds.add(user.uid); // Mark as processed
        return;
      }
      
      print('Starting sample data generation for user: ${userData['fullName']}');
      
      // Create patch for the user
      final patchId = await _createPatch(user.uid);
      print('Created patch with ID: $patchId');
      
      // Generate 30 days of vital signs
      await _generateVitalSigns(patchId, user.uid, 30);
      print('Generated vital signs and health summaries for 30 days');
      
      // Mark user as processed for this session
      _processedUserIds.add(user.uid);
      
      print('Sample data generation completed successfully!');
    } catch (e) {
      print('Error generating sample data: $e');
    }
  }
  
  // Check if user already has any health data
  Future<bool> _userHasExistingData(String userId) async {
    try {
      // Check for existing patches
      final patchesQuery = await _firestore
          .collection('patches')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (patchesQuery.docs.isEmpty) {
        return false;
      }
      
      // Check for existing vitals
      final patchId = patchesQuery.docs.first.id;
      final vitalsQuery = await _firestore
          .collection('vitals')
          .where('patchId', isEqualTo: patchId)
          .limit(1)
          .get();
      
      return vitalsQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for existing data: $e');
      return false;
    }
  }
  
  // Create a patch for the user
  Future<String> _createPatch(String userId) async {
    // Create patch with active status
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 14)); // Patches last 14 days
    
    final patchRef = await _firestore.collection('patches').add({
      'userId': userId,
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
    });
    
    return patchRef.id;
  }
  
  // Generate vital signs for a specific number of days
  Future<void> _generateVitalSigns(String patchId, String userId, int days) async {
    final now = DateTime.now();
    
    // Generate vitals for each day
    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: day));
      
      // Generate 4-6 readings per day
      final readingsPerDay = 4 + _random.nextInt(3);
      
      for (int reading = 0; reading < readingsPerDay; reading++) {
        // Create timestamp within the day
        final hour = 7 + _random.nextInt(15); // Between 7am and 10pm
        final minute = _random.nextInt(60);
        final timestamp = DateTime(date.year, date.month, date.day, hour, minute);
        
        // Special scenarios for certain dates
        bool isYellowWarning = date.month == 4 && date.day == 14; // April 14 is always "yellow" warning
        bool isRedWarning = day == 7 && reading == readingsPerDay - 1; // A red warning on day 7
        
        // Generate vital signs
        final temperature = _generateTemperature(isYellowWarning, isRedWarning);
        final heartRate = _generateHeartRate(isYellowWarning, isRedWarning);
        final hydrationLevel = _generateHydrationLevel(isYellowWarning, isRedWarning);
        
        // Create vital sign record
        await _firestore.collection('vitals').add({
          'patchId': patchId,
          'timestamp': Timestamp.fromDate(timestamp),
          'temperature': temperature,
          'heartRate': heartRate,
          'hydrationLevel': hydrationLevel,
          'fullSensorData': {
            'rawData': 'simulated_data',
            'batteryLevel': 70 + _random.nextInt(30),
            'signalStrength': 3 + _random.nextInt(2),
          },
        });
        
        // Generate health summary for the last reading of the day
        if (reading == readingsPerDay - 1) {
          await _generateHealthSummary(
            userId, 
            timestamp, 
            temperature, 
            heartRate, 
            hydrationLevel,
            isYellowWarning,
            isRedWarning
          );
        }
      }
    }
  }
  
  // Generate temperature based on health status
  double _generateTemperature(bool isYellowWarning, bool isRedWarning) {
    if (isRedWarning) {
      return 38.0 + (_random.nextDouble() * 1.0); // 38.0-39.0°C (high fever)
    } else if (isYellowWarning) {
      return 37.2 + (_random.nextDouble() * 0.7); // 37.2-37.9°C (mild fever)
    } else {
      // 10% chance of slightly elevated temperature even on normal days
      if (_random.nextInt(10) == 0) {
        return 36.9 + (_random.nextDouble() * 0.2); // 36.9-37.1°C (slightly elevated)
      }
      return 36.2 + (_random.nextDouble() * 0.6); // 36.2-36.8°C (normal)
    }
  }
  
  // Generate heart rate based on health status
  int _generateHeartRate(bool isYellowWarning, bool isRedWarning) {
    if (isRedWarning) {
      return 100 + _random.nextInt(30); // 100-130 BPM (high)
    } else if (isYellowWarning) {
      return 90 + _random.nextInt(10); // 90-100 BPM (elevated)
    } else {
      // 10% chance of slightly elevated heart rate even on normal days
      if (_random.nextInt(10) == 0) {
        return 80 + _random.nextInt(10); // 80-90 BPM (slightly elevated)
      }
      return 60 + _random.nextInt(20); // 60-80 BPM (normal)
    }
  }
  
  // Generate hydration level based on health status
  int _generateHydrationLevel(bool isYellowWarning, bool isRedWarning) {
    if (isRedWarning) {
      return 40 + _random.nextInt(10); // 40-50% (dehydrated)
    } else if (isYellowWarning) {
      return 55 + _random.nextInt(10); // 55-65% (slightly dehydrated)
    } else {
      // 10% chance of slightly lower hydration even on normal days
      if (_random.nextInt(10) == 0) {
        return 65 + _random.nextInt(10); // 65-75% (borderline)
      }
      return 75 + _random.nextInt(20); // 75-95% (well hydrated)
    }
  }
  
  // Generate health summary based on vital signs
  Future<void> _generateHealthSummary(
    String userId,
    DateTime timestamp,
    double temperature,
    int heartRate,
    int hydrationLevel,
    bool isYellowWarning,
    bool isRedWarning
  ) async {
    // Determine health status
    String status;
    String colorCode;
    List<String> alertsTriggered = [];
    
    // Determine status based on vital signs
    if (isRedWarning || temperature >= 38.0 || heartRate >= 100 || hydrationLevel <= 50) {
      status = 'critical';
      colorCode = 'red';
      
      if (temperature >= 38.0) alertsTriggered.add('High body temperature');
      if (heartRate >= 100) alertsTriggered.add('Elevated heart rate');
      if (hydrationLevel <= 50) alertsTriggered.add('Dehydration detected');
      
    } else if (isYellowWarning || temperature >= 37.2 || heartRate >= 90 || hydrationLevel <= 65) {
      status = 'warning';
      colorCode = 'yellow';
      
      if (temperature >= 37.2) alertsTriggered.add('Slight temperature elevation');
      if (heartRate >= 90) alertsTriggered.add('Mild heart rate elevation');
      if (hydrationLevel <= 65) alertsTriggered.add('Mild dehydration');
      
    } else {
      status = 'normal';
      colorCode = 'green';
    }
    
    // Create a health advice based on status
    Map<String, dynamic> advice = _generateAdvice(status, temperature, heartRate, hydrationLevel);
    
    // Create a unique ID for the summary based on the date (one summary per day)
    final dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final summaryId = '${userId}_$dateStr';
    
    // Create or update the health summary
    await _firestore.collection('health_summaries').doc(summaryId).set({
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'colorCode': colorCode,
      'alertsTriggered': alertsTriggered,
      'vitalSigns': {
        'temperature': temperature,
        'heartRate': heartRate,
        'hydrationLevel': hydrationLevel,
      },
      'advice': advice,
      'generatedBy': 'simulation',
    });
  }
  
  // Generate appropriate health advice based on status
  Map<String, dynamic> _generateAdvice(
    String status, 
    double temperature, 
    int heartRate, 
    int hydrationLevel
  ) {
    switch (status) {
      case 'critical':
        return {
          'summary': 'Your vital signs indicate potential health concerns that need attention.',
          'recommendations': [
            'Consider seeking medical attention soon',
            'Increase fluid intake immediately to improve hydration',
            'Rest and avoid strenuous activity',
            'Monitor your symptoms closely',
            temperature >= 38.5 ? 'Consider taking appropriate fever-reducing medication' : 'Monitor your temperature regularly',
          ],
          'warning': 'Contact a healthcare provider if symptoms worsen or persist.',
        };
        
      case 'warning':
        return {
          'summary': 'Your vital signs show some mild abnormalities worth monitoring.',
          'recommendations': [
            'Increase your water intake throughout the day',
            'Take frequent rest breaks',
            'Monitor your temperature every few hours',
            'Avoid strenuous physical activities today',
            'Ensure you get adequate sleep tonight',
          ],
          'note': 'If symptoms persist for more than 24 hours, consider consulting a healthcare professional.',
        };
        
      case 'normal':
        return {
          'summary': 'Your vital signs are within normal ranges. Keep up the good work!',
          'recommendations': [
            'Continue your regular hydration habits',
            'Maintain your healthy activity levels',
            'Get 7-8 hours of quality sleep',
            'Keep a balanced diet with plenty of fruits and vegetables',
          ],
          'note': 'Regular monitoring helps maintain optimal health and detect changes early.',
        };
        
      default:
        return {
          'summary': 'No specific health advice available.',
          'recommendations': [
            'Continue monitoring your health regularly.',
          ],
        };
    }
  }
}