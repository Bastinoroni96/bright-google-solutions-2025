// lib/services/ai_service.dart
// Note: This is a simulated Gemini API service
// In a real implementation, you would connect to the Gemini API

import '../models/vital_sign_model.dart';
import '../models/health_summary_model.dart';

class AiService {
  // Simulate generating health advice using Gemini
  Future<String> generateHealthAdvice(VitalSignModel vitalSign) async {
    // This would be a call to the Gemini API in a real implementation
    // For now, we'll return predefined responses based on the vital signs
    
    // Wait to simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Determine health state
    if (vitalSign.temperature >= 38.0 || vitalSign.heartRate >= 100 || vitalSign.hydrationLevel == 'Dehydrated') {
      return '''Your body is showing signs that require attention. Based on your vital signs:
      
- Your elevated temperature of ${vitalSign.temperature.toStringAsFixed(1)}°C suggests your body may be fighting an infection
- Your heart rate of ${vitalSign.heartRate} bpm is above resting range
- Your hydration levels need immediate attention

I recommend:
1. Rest and stay hydrated with regular water intake
2. Avoid strenuous activities until your vitals normalize
3. Monitor for additional symptoms like headaches or muscle aches
4. Consider taking over-the-counter fever reducers if appropriate
5. If symptoms persist for more than 24 hours or worsen, consult with a healthcare provider

Continue monitoring your vital signs and schedule a follow-up scan in 4-6 hours.''';
    } else if (vitalSign.temperature >= 37.2 || vitalSign.heartRate >= 90 || vitalSign.hydrationLevel == 'Borderline') {
      return '''Your body may be responding to early stress, fatigue, or the beginning of an infection. This is not urgent but worth monitoring.

Based on your vital signs showing slight elevations:
- Temperature: ${vitalSign.temperature.toStringAsFixed(1)}°C (slightly above normal)
- Heart rate: ${vitalSign.heartRate} bpm (mildly elevated)
- Hydration: Your hydration status shows early signs of dehydration

My recommendations:
- Drink water regularly throughout the day
- Get adequate rest tonight
- Avoid intense physical activity for the next 12-24 hours
- Monitor for developing symptoms like headache, chills, or general discomfort

If your temperature rises above 38°C or your symptoms worsen, consider contacting your healthcare provider. Otherwise, your next check-in is recommended in 24 hours.''';
    } else {
      return '''Your vital signs look healthy and within normal ranges. Your body is functioning well!

- Temperature: ${vitalSign.temperature.toStringAsFixed(1)}°C (normal range)
- Heart rate: ${vitalSign.heartRate} bpm (normal resting rate)
- Hydration: Properly hydrated

Keep doing what you're doing! Maintain a balanced diet, stay hydrated, get regular exercise, and ensure adequate sleep (7-9 hours per night). These healthy habits are clearly working for you.

Your next health check-in is recommended in 24 hours or as needed. If you experience any changes in how you feel, you can always check back sooner.''';
    }
  }
  
  // Simulate generating a more comprehensive health summary using Gemini
  Future<HealthSummaryModel> generateHealthSummary(
    VitalSignModel vitalSign, 
    String userId,
    List<VitalSignModel> recentVitals,
  ) async {
    // This would integrate with the Gemini API in a real implementation
    
    // Wait to simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a basic summary
    final basicSummary = HealthSummaryModel.fromVitalSign(vitalSign, userId);
    
    // Add trend analysis (simulated AI enhancement)
    if (recentVitals.isNotEmpty) {
      // Check for trends in the data
      final temperatures = recentVitals.map((v) => v.temperature).toList();
      final heartRates = recentVitals.map((v) => v.heartRate).toList();
      
      bool risingTemperature = false;
      bool risingHeartRate = false;
      
      if (temperatures.length >= 3) {
        risingTemperature = temperatures[0] < temperatures[1] && temperatures[1] < temperatures[2];
      }
      
      if (heartRates.length >= 3) {
        risingHeartRate = heartRates[0] < heartRates[1] && heartRates[1] < heartRates[2];
      }
      
      // Enhance advice based on trends
      if (risingTemperature && risingHeartRate) {
        return HealthSummaryModel(
          id: basicSummary.id,
          userId: basicSummary.userId,
          generatedBy: 'gemini_ai',
          timestamp: basicSummary.timestamp,
          status: basicSummary.status,
          alertsTriggered: [...basicSummary.alertsTriggered, "Rising trend detected"],
          vitalSigns: basicSummary.vitalSigns,
          summaryText: "I've detected a consistent upward trend in your vital signs over the past readings.",
          adviceText: '''Based on the pattern analysis of your recent vital signs, I've noticed a consistent upward trend in both temperature and heart rate.

${basicSummary.adviceText}

Additionally, since this is part of an ongoing trend rather than an isolated reading, I recommend:
1. Taking note of any activities, diet changes, or stressors that might be contributing
2. Ensuring you're getting adequate rest in a cool environment
3. Considering a video consultation with your healthcare provider if this trend continues for another 24 hours

I'll continue monitoring for any significant changes.''',
        );
      }
    }
    
    // Return enhanced summary with AI-generated advice
    return HealthSummaryModel(
      id: basicSummary.id,
      userId: basicSummary.userId,
      generatedBy: 'gemini_ai',
      timestamp: basicSummary.timestamp,
      status: basicSummary.status,
      alertsTriggered: basicSummary.alertsTriggered,
      vitalSigns: basicSummary.vitalSigns,
      summaryText: basicSummary.summaryText,
      adviceText: await generateHealthAdvice(vitalSign),
    );
  }
}