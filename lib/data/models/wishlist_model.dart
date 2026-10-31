import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WishlistModel {
  final String id; // This is usually the userId
  final List<String> messes;
  final List<String> rooms;
  final DateTime? updatedAt;

  static const Object _sentinel = Object();

  WishlistModel({
    required this.id,
    this.messes = const [],
    this.rooms = const [],
    this.updatedAt,
  });

  factory WishlistModel.fromMap(Map<String, dynamic> map, String id) {
    return WishlistModel(
      id: id,
      messes: List<String>.from(map['wishlistedMesses'] ?? []),
      rooms: List<String>.from(map['wishlistedRooms'] ?? []),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wishlistedMesses': messes,
      'wishlistedRooms': rooms,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  WishlistModel copyWith({
    String? id,
    List<String>? messes,
    List<String>? rooms,
    Object? updatedAt = _sentinel,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      messes: messes ?? this.messes,
      rooms: rooms ?? this.rooms,
      updatedAt: updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(messes, other.messes) &&
          listEquals(rooms, other.rooms) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      messes.hashCode ^
      rooms.hashCode ^
      updatedAt.hashCode;
}
