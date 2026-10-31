import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, contacted, confirmed, rejected, cancelled }

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String messId;
  final String messName;
  final String roomId;
  final String roomType;
  final int price;
  final BookingStatus status;
  final DateTime? createdAt;
  final String? remark;
  final String rentCycle; // 'monthly' or 'yearly'

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.messId,
    required this.messName,
    required this.roomId,
    required this.roomType,
    required this.price,
    this.status = BookingStatus.pending,
    this.createdAt,
    this.remark,
    this.rentCycle = 'monthly',
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userPhone: map['userPhone']?.toString() ?? '',
      messId: map['messId']?.toString() ?? '',
      messName: map['messName']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      roomType: map['roomType']?.toString() ?? '',
      price: () {
        final p = map['price'];
        if (p is num) return p.toInt();
        if (p is String) return int.tryParse(p) ?? 0;
        return 0;
      }(),
      status: () {
        final rawStatus = (map['status'] ?? 'pending').toString().toLowerCase();
        if (rawStatus == 'rejected' || rawStatus == 'cancelled') return BookingStatus.rejected;
        if (rawStatus == 'confirmed') return BookingStatus.confirmed;
        if (rawStatus == 'contacted') return BookingStatus.contacted;
        return BookingStatus.pending;
      }(),
      createdAt: () {
        final c = map['createdAt'];
        if (c is Timestamp) return c.toDate();
        if (c is DateTime) return c;
        if (c is int) return DateTime.fromMillisecondsSinceEpoch(c);
        if (c is String) return DateTime.tryParse(c);
        return null;
      }(),
      remark: map['remark']?.toString(),
      rentCycle: map['rentCycle']?.toString() ?? 'monthly',
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
      'price': price,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'remark': remark,
      'rentCycle': rentCycle,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? messId,
    String? messName,
    String? roomId,
    String? roomType,
    int? price,
    BookingStatus? status,
    DateTime? createdAt,
    String? remark,
    String? rentCycle,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      messId: messId ?? this.messId,
      messName: messName ?? this.messName,
      roomId: roomId ?? this.roomId,
      roomType: roomType ?? this.roomType,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      remark: remark ?? this.remark,
      rentCycle: rentCycle ?? this.rentCycle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          userName == other.userName &&
          userPhone == other.userPhone &&
          messId == other.messId &&
          messName == other.messName &&
          roomId == other.roomId &&
          roomType == other.roomType &&
          price == other.price &&
          status == other.status &&
          createdAt == other.createdAt &&
          remark == other.remark;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      userName.hashCode ^
      userPhone.hashCode ^
      messId.hashCode ^
      messName.hashCode ^
      roomId.hashCode ^
      roomType.hashCode ^
      price.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      remark.hashCode;
}
