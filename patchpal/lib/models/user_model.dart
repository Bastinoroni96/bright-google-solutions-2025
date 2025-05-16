// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String accountType; // "personal" or "healthcare_professional"
  final Map<String, dynamic>? additionalInfo; // For any additional user type specific data

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.accountType,
    this.additionalInfo,
  });

  // Create a UserModel from Firebase auth data
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      accountType: map['accountType'] ?? 'personal',
      additionalInfo: map['additionalInfo'],
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'accountType': accountType,
      'additionalInfo': additionalInfo,
    };
  }

  // Create a copy of this UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? accountType,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      accountType: accountType ?? this.accountType,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}