// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/vital_sign_model.dart';
import '../models/health_summary_model.dart';

class GeminiService {
  // Model name remains constant
  static const String modelName = 'gemini-1.5-pro';
  
  // API key and model are private
  final String _apiKey;
  late final GenerativeModel? _model;
  
  // Constructor that accepts API key
  GeminiService({required String apiKey}) : _apiKey = apiKey {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: modelName,
        apiKey: _apiKey,
      );
    } else {
      print('WARNING: No Gemini API key provided. Health AI advice will not be available.');
      _model = null;
    }
  }
  
  // Generate health advice based on vital signs
  Future<String> generateHealthAdvice(VitalSignModel vitalSign) async {
    // If no API key/model, return fallback immediately
    if (_model == null) {
      return _generateFallbackAdvice(vitalSign);
    }
    
    try {
      // Create a prompt with the vital sign data
      final prompt = _createHealthAdvicePrompt(vitalSign);
      
      // Send the prompt to Gemini
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      // Extract and return the response text
      return response.text ?? 
          'Unable to generate health advice at this time. Please consult with a healthcare professional for advice.';
    } catch (e) {
      print('Error generating health advice: $e');
      
      // Fallback response if Gemini fails
      return _generateFallbackAdvice(vitalSign);
    }
  }
  
  // Create a full health summary using Gemini
  Future<HealthSummaryModel> generateHealthSummary(
    VitalSignModel vitalSign, 
    String userId,
    List<VitalSignModel> recentVitals,
  ) async {
    try {
      // Generate advice using Gemini
      final adviceText = await generateHealthAdvice(vitalSign);
      
      // Determine health status based on vital signs
      final status = _determineHealthStatus(vitalSign);
      
      // Generate alerts based on vital signs
      final alerts = _generateAlerts(vitalSign);
      
      // Generate a summary text
      final summaryText = _generateSummaryText(vitalSign, alerts);
      
      // Create the health summary
      return HealthSummaryModel(
        id: 'hs_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        generatedBy: _model != null ? 'gemini_ai' : 'fallback_system',
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
    } catch (e) {
      print('Error generating health summary: $e');
      
      // Fall back to the basic summary generator if Gemini fails
      return HealthSummaryModel.fromVitalSign(vitalSign, userId);
    }
  }
  
  // Create a prompt for Gemini based on vital signs
  String _createHealthAdvicePrompt(VitalSignModel vitalSign) {
    return '''
You are a health monitoring assistant integrated with a medical wearable patch. The patch has sent the following vital signs:
- Temperature: ${vitalSign.temperature.toStringAsFixed(1)}°C
- Heart Rate: ${vitalSign.heartRate} bpm
- Hydration Level: ${vitalSign.hydrationLevel}
- Timestamp: ${vitalSign.timestamp}

Based on these vital signs:
1. Provide a brief health assessment
2. Offer practical advice the user should follow
3. Mention when they should check again or seek medical attention if needed
4. Keep your response concise and easy to understand
5. Use a compassionate and helpful tone
6. Don't mention that you're an AI, just provide the advice directly
7. If values are normal, reassure the user
8. If values show minor concerns, provide cautionary advice
9. If values indicate potential health issues, suggest appropriate actions without causing alarm

Return only the advice text, no introduction or extra formatting.
''';
  }
  
  // Generate fallback advice if Gemini is unavailable
  String _generateFallbackAdvice(VitalSignModel vitalSign) {
    if (vitalSign.temperature >= 38.0 || vitalSign.heartRate >= 100 || vitalSign.hydrationLevel == 'Dehydrated') {
      return 'Your vital signs show some concerning patterns that may require attention. Your temperature is elevated, and your heart rate is above normal resting range. Ensure you stay hydrated, rest, and monitor for any additional symptoms. If your condition persists or worsens, consider consulting a healthcare professional.';
    } else if (vitalSign.temperature >= 37.2 || vitalSign.heartRate >= 90 || vitalSign.hydrationLevel == 'Borderline') {
      return 'Your body may be responding to early stress, fatigue, or the beginning of an infection. This is not urgent but worth monitoring. Drink water regularly and get adequate rest. If symptoms develop or vital signs worsen, consider consulting a healthcare professional.';
    } else {
      return 'Your vital signs look good! Continue maintaining healthy habits including proper hydration, regular exercise, and adequate sleep. Your next check-in is recommended in 24 hours or as needed.';
    }
  }
  
  // Determine health status from vital signs
  HealthStatus _determineHealthStatus(VitalSignModel vitalSign) {
    if (vitalSign.temperature >= 38.0 || vitalSign.heartRate >= 100) {
      return HealthStatus.red;
    } else if (vitalSign.temperature >= 37.2 || vitalSign.heartRate >= 90 || vitalSign.hydrationLevel != 'Normal') {
      return HealthStatus.yellow;
    } else {
      return HealthStatus.green;
    }
  }
  
  // Generate alerts based on vital signs
  List<String> _generateAlerts(VitalSignModel vitalSign) {
    final alerts = <String>[];
    
    if (vitalSign.temperature >= 38.0) {
      alerts.add('High temperature');
    } else if (vitalSign.temperature >= 37.2) {
      alerts.add('Slightly elevated temperature');
    }
    
    if (vitalSign.heartRate >= 100) {
      alerts.add('Elevated heart rate');
    } else if (vitalSign.heartRate >= 90) {
      alerts.add('Slightly elevated heart rate');
    }
    
    if (vitalSign.hydrationLevel != 'Normal') {
      alerts.add('Hydration concerns');
    }
    
    return alerts;
  }
  
  // Generate summary text based on vital signs and alerts
  String _generateSummaryText(VitalSignModel vitalSign, List<String> alerts) {
    if (alerts.isEmpty) {
      return 'Your vitals look healthy.';
    } else if (alerts.length == 1) {
      if (alerts[0].contains('temperature')) {
        return 'Elevated temperature detected.';
      } else if (alerts[0].contains('heart rate')) {
        return 'Elevated heart rate detected.';
      } else {
        return 'Hydration levels need attention.';
      }
    } else {
      return 'Multiple warning signs detected.';
    }
  }
}