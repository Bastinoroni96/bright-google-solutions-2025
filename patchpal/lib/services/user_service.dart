// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Reference to users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create a new user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
      print('User document created successfully in Firestore');
    } catch (e) {
      print('Error creating user: $e');
      // Don't throw exception here, just log it and continue
      // This allows the app to function even if Firestore operations fail
    }
  }

  // Update an existing user in Firestore
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
      print('User document updated successfully in Firestore');
    } catch (e) {
      print('Error updating user: $e');
      // Check if document doesn't exist
      if (e is FirebaseException && e.code == 'not-found') {
        // Create the document if it doesn't exist
        await createUser(user);
      }
      // For other errors, just log and continue
    }
  }

  // Get a user by ID with fallback
  Future<UserModel?> getUserById(String uid) async {
    try {
      // First try to get from Firestore
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      
      // If not in Firestore, create from Auth data
      User? authUser = _auth.currentUser;
      if (authUser != null && authUser.uid == uid) {
        UserModel newUser = UserModel(
          uid: uid,
          email: authUser.email ?? '',
          fullName: authUser.displayName ?? 'User',
          accountType: 'personal', // Default type
          additionalInfo: {},
        );
        
        // Try to create in Firestore (don't await so it happens in background)
        createUser(newUser).then((_) {
          print('Created missing user document in Firestore');
        }).catchError((e) {
          print('Failed to create missing user document: $e');
        });
        
        return newUser;
      }
      
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      
      // Provide fallback from Auth data
      User? authUser = _auth.currentUser;
      if (authUser != null && authUser.uid == uid) {
        return UserModel(
          uid: uid,
          email: authUser.email ?? '',
          fullName: authUser.displayName ?? 'User',
          accountType: 'personal', // Default type
          additionalInfo: {},
        );
      }
      
      // If we can't create a fallback, return null instead of throwing
      return null;
    }
  }

  // Get the current logged-in user with fallback
  Future<UserModel?> getCurrentUser() async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      
      return await getUserById(uid);
    } catch (e) {
      print('Error getting current user: $e');
      
      // Fallback to basic info from Auth
      User? authUser = _auth.currentUser;
      if (authUser != null) {
        return UserModel(
          uid: authUser.uid,
          email: authUser.email ?? '',
          fullName: authUser.displayName ?? 'User',
          accountType: 'personal', // Default
          additionalInfo: {},
        );
      }
      
      return null;
    }
  }
}