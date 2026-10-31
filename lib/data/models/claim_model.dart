import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus { pending, approved, rejected }

/// Model for the `claims` Firestore collection.
/// Written when a mess owner taps "Claim This Listing".
class ClaimModel {
  final String id;
  final String messId;
  final String messName;
  final String? userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String? proofDescription;  // How they prove ownership
  final ClaimStatus status;
  final DateTime? createdAt;
  final String? district;

  ClaimModel({
    required this.id,
    required this.messId,
    required this.messName,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.proofDescription,
    this.status = ClaimStatus.pending,
    this.createdAt,
    this.district,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> map, String id) {
    return ClaimModel(
      id: id,
      messId: map['messId']?.toString() ?? '',
      messName: map['messName']?.toString() ?? '',
      userId: map['userId']?.toString(),
      userName: map['userName']?.toString() ?? '',
      userPhone: map['userPhone']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      proofDescription: map['proofDescription']?.toString(),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == (map['status']?.toString() ?? 'pending'),
        orElse: () => ClaimStatus.pending,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null),
      district: map['district']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messId': messId,
      'messName': messName,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'proofDescription': proofDescription,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'district': district,
    };
  }
}
