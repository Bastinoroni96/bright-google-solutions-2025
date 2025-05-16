// lib/models/vital_sign_model.dart
class VitalSignModel {
  final String id;
  final String patchId;
  final DateTime timestamp;
  final double temperature;
  final int heartRate;
  final String hydrationLevel;
  final Map<String, dynamic>? fullSensorData;

  VitalSignModel({
    required this.id,
    required this.patchId,
    required this.timestamp,
    required this.temperature,
    required this.heartRate,
    required this.hydrationLevel,
    this.fullSensorData,
  });

  factory VitalSignModel.fromMap(Map<String, dynamic> map) {
    return VitalSignModel(
      id: map['id'] ?? '',
      patchId: map['patchId'] ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] is DateTime 
              ? map['timestamp'] 
              : DateTime.parse(map['timestamp']))
          : DateTime.now(),
      temperature: (map['temperature'] ?? 36.5).toDouble(),
      heartRate: (map['heartRate'] ?? 75).toInt(),
      hydrationLevel: map['hydrationLevel'] ?? 'Normal',
      fullSensorData: map['fullSensorData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patchId': patchId,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'heartRate': heartRate,
      'hydrationLevel': hydrationLevel,
      'fullSensorData': fullSensorData,
    };
  }
  
  // Create a simulated vital sign for demo purposes
  factory VitalSignModel.simulated(String patchId, {DateTime? timestamp, String? healthState}) {
    timestamp ??= DateTime.now();
    healthState ??= 'normal'; // 'normal', 'warning', 'critical'
    
    // Base values
    double baseTemp = 36.5;
    int baseHeartRate = 75;
    String hydration = 'Normal';
    
    // Adjust based on health state
    if (healthState == 'warning') {
      baseTemp = 37.3;
      baseHeartRate = 98;
      hydration = 'Borderline';
    } else if (healthState == 'critical') {
      baseTemp = 38.2;
      baseHeartRate = 110;
      hydration = 'Dehydrated';
    }
    
    // Add small random variation
    final random = DateTime.now().millisecondsSinceEpoch;
    final tempVariation = (random % 10) / 100;
    final hrVariation = random % 5;
    
    return VitalSignModel(
      id: 'vs_${DateTime.now().millisecondsSinceEpoch}',
      patchId: patchId,
      timestamp: timestamp,
      temperature: baseTemp + tempVariation,
      heartRate: baseHeartRate + hrVariation,
      hydrationLevel: hydration,
      fullSensorData: {
        'rawTemperature': baseTemp + tempVariation,
        'rawHeartRate': baseHeartRate + hrVariation,
        'skinConductivity': healthState == 'normal' ? 'stable' : 'fluctuating',
        'movementLevel': healthState == 'normal' ? 'normal' : 'elevated',
      },
    );
  }
}