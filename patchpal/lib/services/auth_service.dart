// lib/services/auth_service.dart (corrected)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'data_generator.dart'; // Update this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user is a personal user and initialize data if needed
      try {
        UserModel? userModel = await _userService.getUserById(userCredential.user!.uid);
        if (userModel?.accountType == 'personal') {
          // Initialize sample data for personal users
          SampleDataGenerator().generateDataIfNeeded(); // Updated this line
        }
      } catch (e) {
        print('Non-critical error checking user type: $e');
        // Continue even if we couldn't check user type
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email & password
  Future<UserCredential?> registerWithEmailPassword({
    required String email, 
    required String password,
    required String fullName,
    required String accountType,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Create the user account in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create the user profile in Firestore
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          fullName: fullName,
          accountType: accountType,
          additionalInfo: additionalInfo,
        );
        
        await _userService.createUser(newUser);
        
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(fullName);
        
        // Initialize sample data for personal users
        if (accountType == 'personal') {
          print('New personal user registered. Initializing sample data...');
          await SampleDataGenerator().generateDataIfNeeded(); // Updated this line
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Error in registration: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions and return user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      default:
        message = 'An error occurred. Please try again.';
    }
    
    return Exception(message);
  }
}

// Auth Provider using Provider package
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      
      if (user != null) {
        // Load user data from Firestore
        _isLoading = true;
        notifyListeners();
        
        try {
          _userModel = await _userService.getUserById(user.uid);
          
          // Initialize sample data for personal users
          if (_userModel?.accountType == 'personal') {
            print('Auth state changed: User is personal type. Checking for sample data...');
            SampleDataGenerator().generateDataIfNeeded(); // Updated this line
          }
        } catch (e) {
          print('Error loading user data: $e');
          _userModel = null;
        }
        
        _isLoading = false;
      } else {
        _userModel = null;
      }
      
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signInWithEmailPassword(email, password);
      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email, 
    required String password,
    required String fullName,
    required String accountType,
    Map<String, dynamic>? additionalInfo,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        accountType: accountType,
        additionalInfo: additionalInfo,
      );
      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } on Exception catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}