// lib/services/service_provider.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'gemini_service.dart';

/// A simple service provider to access app-wide services
class ServiceProvider {
  // Private constructor prevents instantiation
  ServiceProvider._();
  
  // Static instances of services
  static GeminiService? _geminiService;
  
  /// Get the GeminiService instance
  static GeminiService get geminiService {
    // Create instance if it doesn't exist yet
    _geminiService ??= GeminiService(
      // Try to get API key from environment variables first
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? 
              const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );
    return _geminiService!;
  }
}