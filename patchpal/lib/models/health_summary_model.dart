// lib/models/health_summary_model.dart 
import 'vital_sign_model.dart'; 

enum HealthStatus {
  green,
  yellow,
  red,
}

class HealthSummaryModel {
  final String id;
  final String userId;
  final String generatedBy; // 'system', 'ai', 'doctor', etc.
  final DateTime timestamp;
  final HealthStatus status;
  final List<String> alertsTriggered;
  final Map<String, dynamic> vitalSigns;
  final String summaryText;
  final String adviceText;

  HealthSummaryModel({
    required this.id,
    required this.userId,
    required this.generatedBy,
    required this.timestamp,
    required this.status,
    required this.alertsTriggered,
    required this.vitalSigns,
    required this.summaryText,
    required this.adviceText,
  });

  factory HealthSummaryModel.fromMap(Map<String, dynamic> map) {
    return HealthSummaryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      generatedBy: map['generatedBy'] ?? 'system',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] is DateTime 
              ? map['timestamp'] 
              : DateTime.parse(map['timestamp']))
          : DateTime.now(),
      status: _statusFromString(map['status'] ?? 'green'),
      alertsTriggered: List<String>.from(map['alertsTriggered'] ?? []),
      vitalSigns: Map<String, dynamic>.from(map['vitalSigns'] ?? {}),
      summaryText: map['summaryText'] ?? '',
      adviceText: map['adviceText'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'generatedBy': generatedBy,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'alertsTriggered': alertsTriggered,
      'vitalSigns': vitalSigns,
      'summaryText': summaryText,
      'adviceText': adviceText,
    };
  }

  static HealthStatus _statusFromString(String status) {
    if (status.toLowerCase() == 'yellow') return HealthStatus.yellow;
    if (status.toLowerCase() == 'red') return HealthStatus.red;
    return HealthStatus.green;
  }
  
  // Generate a simulated health summary based on vital signs
  factory HealthSummaryModel.fromVitalSign(VitalSignModel vitalSign, String userId) {
    // Determine health status based on vital signs
    HealthStatus status = HealthStatus.green;
    List<String> alerts = [];
    String summaryText = 'Your vitals look healthy.';
    String adviceText = 'Keep doing what you\'re doing! Stay hydrated, get enough sleep, and maintain a balanced diet. Your next check-in is recommended in 24 hours or as needed.';
    
    // Check temperature
    if (vitalSign.temperature >= 38.0) {
      status = HealthStatus.red;
      alerts.add('High temperature');
      summaryText = 'Elevated temperature detected.';
      adviceText = 'Your temperature is above normal range. Rest, stay hydrated, and monitor for other symptoms. If temperature persists above 38°C for more than 24 hours, consider consulting a healthcare provider.';
    } else if (vitalSign.temperature >= 37.2) {
      status = status == HealthStatus.red ? HealthStatus.red : HealthStatus.yellow;
      alerts.add('Slightly elevated temperature');
      summaryText = 'Some early warning signs are showing.';
      adviceText = 'Your body may be responding to early stress, fatigue, or the beginning of an infection. This is not urgent but worth monitoring. Drink water regularly and get rest.';
    }
    
    // Check heart rate
    if (vitalSign.heartRate >= 100) {
      status = status == HealthStatus.red ? HealthStatus.red : HealthStatus.yellow;
      alerts.add('Elevated heart rate');
      if (summaryText == 'Your vitals look healthy.') {
        summaryText = 'Elevated heart rate detected.';
      } else {
        summaryText = 'Multiple warning signs detected.';
      }
      if (adviceText.contains('Stay hydrated')) {
        adviceText = 'Your heart rate is elevated. This could be due to activity, stress, or dehydration. Stay hydrated and monitor for any changes. If you experience chest pain or dizziness, contact a healthcare provider.';
      }
    }
    
    // Check hydration
    if (vitalSign.hydrationLevel != 'Normal') {
      status = status == HealthStatus.red ? HealthStatus.red : HealthStatus.yellow;
      alerts.add('Hydration concerns');
      if (summaryText == 'Your vitals look healthy.') {
        summaryText = 'Hydration levels need attention.';
      } else if (!summaryText.contains('Multiple')) {
        summaryText = 'Multiple warning signs detected.';
      }
      
      if (!adviceText.contains('Drink water')) {
        adviceText = 'Your hydration levels indicate you need to increase fluid intake. Drink water regularly throughout the day and avoid caffeine and alcohol which can contribute to dehydration.';
      }
    }
    
    return HealthSummaryModel(
      id: 'hs_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      generatedBy: 'ai',
      timestamp: vitalSign.timestamp,
      status: status,
      alertsTriggered: alerts,
      vitalSigns: {
        'temperature': vitalSign.temperature,
        'heartRate': vitalSign.heartRate,
        'hydrationLevel': vitalSign.hydrationLevel,
      },
      summaryText: summaryText,
      adviceText: adviceText,
    );
  }
}