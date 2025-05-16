// lib/services/patch_service.dart 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patch_model.dart';
import '../models/vital_sign_model.dart';
import '../models/health_summary_model.dart';
import 'service_provider.dart'; // Change this import

class PatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the GeminiService through the service provider instead of directly initializing
  // This ensures we're using the securely configured instance
  get _geminiService => ServiceProvider.geminiService;

  // Flag to use Firestore or local data
  final bool useFirestore = false;
  
  // Flag to use Gemini AI or simulated responses
  final bool useGeminiAI = true; // Set to false to use simulated responses

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _patchesCollection => _firestore.collection('patches');
  CollectionReference get _vitalsCollection => _firestore.collection('vitals');
  CollectionReference get _summariesCollection => _firestore.collection('health_summaries');

  // Get active patch for current user
  Future<PatchModel?> getActivePatch() async {
    if (!useFirestore) {
      // Return a simulated patch during development
      if (currentUserId == null) return null;
      
      return PatchModel(
        id: 'patch_simulated',
        userId: currentUserId!,
        status: PatchStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );
    }
    
    try {
      if (currentUserId == null) return null;

      final querySnapshot = await _patchesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return PatchModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting active patch: $e');
      
      // Return a simulated patch if Firestore fails
      if (currentUserId != null) {
        return PatchModel(
          id: 'patch_fallback',
          userId: currentUserId!,
          status: PatchStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
        );
      }
      
      return null;
    }
  }

  // Get latest vital signs for a patch
  Future<VitalSignModel?> getLatestVitalSigns(String patchId) async {
    if (!useFirestore) {
      // Return simulated vital signs during development
      return VitalSignModel.simulated(patchId);
    }
    
    try {
      final querySnapshot = await _vitalsCollection
          .where('patchId', isEqualTo: patchId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return VitalSignModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting latest vital signs: $e');
      
      // Return simulated vital signs if Firestore fails
      return VitalSignModel.simulated(patchId);
    }
  }
  
  // Save a health summary
  Future<void> saveHealthSummary(HealthSummaryModel summary) async {
    if (!useFirestore) return; // Skip saving during development
    
    try {
      await _summariesCollection.doc(summary.id).set(summary.toMap());
    } catch (e) {
      print('Error saving health summary: $e');
      throw Exception('Failed to save health summary');
    }
  }
  
  // Get health summaries for user
  Future<List<HealthSummaryModel>> getHealthSummaries({int limit = 7}) async {
    if (!useFirestore) {
      // Return simulated summaries during development
      if (currentUserId == null) return [];
      
      final List<HealthSummaryModel> summaries = [];
      final now = DateTime.now();
      
      for (int i = 0; i < limit; i++) {
        final date = now.subtract(Duration(days: i));
        summaries.add(await getHealthSummaryForDate(date) ?? 
                      await generateSimulatedHealthSummary(date: date));
      }
      
      return summaries;
    }
    
    try {
      if (currentUserId == null) return [];

      final querySnapshot = await _summariesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        return HealthSummaryModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting health summaries: $e');
      return [];
    }
  }
  
  // Get health summary for a specific date
  Future<HealthSummaryModel?> getHealthSummaryForDate(DateTime date) async {
    if (!useFirestore) {
      // For development, just generate simulated data
      // Allow certain dates to always have specific health states
      final isApril14 = date.month == 4 && date.day == 14;
      final isMay12 = date.month == 5 && date.day == 12;
      
      String healthState = 'normal';
      if (isApril14 || isMay12) {
        healthState = 'warning';
      }
      
      // Generate a simulated summary with the appropriate health state
      return generateSimulatedHealthSummary(
        date: date,
        healthState: healthState,
      );
    }
    
    try {
      if (currentUserId == null) return null;

      // Create date range (start of day to end of day)
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _summariesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return HealthSummaryModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting health summary for date: $e');
      
      // If there's a permission error, try to generate simulated data
      if (e.toString().contains('permission-denied')) {
        if (currentUserId == null) return null;
        
        // Generate simulated data as fallback
        final isApril14 = date.month == 4 && date.day == 14;
        final healthState = isApril14 ? 'warning' : 'normal';
        return generateSimulatedHealthSummary(
          date: date,
          healthState: healthState,
        );
      }
      
      return null;
    }
  }
  
  // Generate simulated data for demo purposes
  Future<HealthSummaryModel> generateSimulatedHealthSummary({
    String? healthState,
    DateTime? date,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Use provided date or now
    final timestamp = date ?? DateTime.now();
    
    // Create a simulated patch if none exists
    final patch = await getActivePatch() ?? PatchModel(
      id: 'patch_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId!,
      status: PatchStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
    );
    
    // Create simulated vital signs
    final vitalSign = VitalSignModel.simulated(
      patch.id, 
      timestamp: timestamp,
      healthState: healthState,
    );
    
    // Get previous 3 days of vitals for trend analysis
    final recentVitals = <VitalSignModel>[];
    for (int i = 1; i <= 3; i++) {
      final pastDate = timestamp.subtract(Duration(days: i));
      recentVitals.add(VitalSignModel.simulated(patch.id, timestamp: pastDate));
    }
    
    // If using Gemini AI, generate summary with it
    if (useGeminiAI) {
      try {
        // Use Gemini to generate health summary
        final summary = await _geminiService.generateHealthSummary(
          vitalSign, 
          currentUserId!,
          recentVitals,
        );
        
        // Save to Firestore if enabled
        if (useFirestore) {
          try {
            await saveHealthSummary(summary);
          } catch (e) {
            print('Error saving Gemini-generated summary: $e');
          }
        }
        
        return summary;
      } catch (e) {
        print('Error generating summary with Gemini: $e');
        // Fall back to basic summary if Gemini fails
      }
    }
    
    // Generate health summary from vital signs without Gemini
    final summary = HealthSummaryModel.fromVitalSign(vitalSign, currentUserId!);
    
    // Save to Firestore if needed
    if (useFirestore) {
      try {
        // Save the patch if it's a new one
        if (!(await getActivePatch() != null)) {
          await _patchesCollection.doc(patch.id).set(patch.toMap());
        }
        
        // Save the vital sign
        await _vitalsCollection.doc(vitalSign.id).set(vitalSign.toMap());
        
        // Save the health summary
        await _summariesCollection.doc(summary.id).set(summary.toMap());
      } catch (e) {
        print('Error saving simulated data: $e');
      }
    }
    
    return summary;
  }
}