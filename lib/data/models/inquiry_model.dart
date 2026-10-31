import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the `inquiries` Firestore collection.
/// Written when a user taps "Contact Owner" on a MessDetails page.
class InquiryModel {
  final String id;
  final String? userId;
  final String userName;
  final String userPhone;
  final String messId;
  final String messName;
  final String? message;
  final String status; // 'pending' | 'resolved' | 'spam'
  final DateTime? createdAt;
  final String? district;

  InquiryModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.messId,
    required this.messName,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.district,
  });

  factory InquiryModel.fromMap(Map<String, dynamic> map, String id) {
    return InquiryModel(
      id: id,
      userId: map['userId']?.toString(),
      userName: map['userName']?.toString() ?? '',
      userPhone: map['userPhone']?.toString() ?? '',
      messId: map['messId']?.toString() ?? '',
      messName: map['messName']?.toString() ?? '',
      message: map['message']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null),
      district: map['district']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'messId': messId,
      'messName': messName,
      'message': message,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'district': district,
    };
  }
}

/// Model for the `room_inquiries` Firestore collection.
/// Written when a user taps "Contact Owner" on a RoomDetails page.
class RoomInquiryModel {
  final String id;
  final String? userId;
  final String userName;
  final String userPhone;
  final String messId;
  final String messName;
  final String roomId;
  final String roomType;
  final String? message;
  final String status; // 'pending' | 'resolved' | 'spam'
  final DateTime? createdAt;

  RoomInquiryModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.messId,
    required this.messName,
    required this.roomId,
    required this.roomType,
    this.message,
    this.status = 'pending',
    this.createdAt,
  });

  factory RoomInquiryModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomInquiryModel(
      id: id,
      userId: map['userId']?.toString(),
      userName: map['userName']?.toString() ?? '',
      userPhone: map['userPhone']?.toString() ?? '',
      messId: map['messId']?.toString() ?? '',
      messName: map['messName']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      roomType: map['roomType']?.toString() ?? '',
      message: map['message']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'messId': messId,
      'messName': messName,
      'roomId': roomId,
      'roomType': roomType,
      'message': message,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
