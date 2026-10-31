import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin, operator }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime? createdAt;
  final String? photoUrl;
  final String? fcmToken;

  bool get isPartnerOrAdmin => role == UserRole.admin || role == UserRole.operator;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.user,
    this.createdAt,
    this.photoUrl,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final email = (map['email'] ?? '').toString().toLowerCase().trim();
    final rawRole = (map['role'] ?? 'user').toString().toLowerCase().trim();

    UserRole resolvedRole = UserRole.user;
    if (email == 'messkhojooperator@gmail.com' || rawRole == 'operator') {
      resolvedRole = UserRole.operator;
    } else if (rawRole == 'admin' || rawRole == 'partner' || rawRole == 'owner') {
      resolvedRole = UserRole.admin;
    }

    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: resolvedRole,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    String? photoUrl,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role &&
          createdAt == other.createdAt &&
          photoUrl == other.photoUrl &&
          fcmToken == other.fcmToken;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      role.hashCode ^
      createdAt.hashCode ^
      photoUrl.hashCode ^
      fcmToken.hashCode;
}
