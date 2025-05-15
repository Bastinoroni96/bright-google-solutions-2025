// lib/models/patch_model.dart
class PatchModel {
  final String id;
  final String userId;
  final PatchStatus status;
  final DateTime startDate;
  final DateTime? endDate;

  PatchModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startDate,
    this.endDate,
  });

  factory PatchModel.fromMap(Map<String, dynamic> map) {
    return PatchModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      status: _statusFromString(map['status'] ?? 'inactive'),
      startDate: map['startDate'] != null 
          ? (map['startDate'] is DateTime 
              ? map['startDate'] 
              : DateTime.parse(map['startDate']))
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? (map['endDate'] is DateTime 
              ? map['endDate'] 
              : DateTime.parse(map['endDate']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'status': status == PatchStatus.active ? 'active' : 'inactive',
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  static PatchStatus _statusFromString(String status) {
    return status.toLowerCase() == 'active' ? PatchStatus.active : PatchStatus.inactive;
  }
}

enum PatchStatus {
  active,
  inactive,
}