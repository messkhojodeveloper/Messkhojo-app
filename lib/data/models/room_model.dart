import 'package:flutter/foundation.dart';

class RoomModel {
  final String id;
  final String messId;
  final String roomType;
  final String occupancy;
  final int price;
  final int? rent;
  final List<String> imageUrls;
  final List<String> images;
  final Map<String, dynamic> amenities;
  final int availableCount;
  final bool? available;
  final String district;
  final String rentCycle; // 'monthly' or 'yearly'

  // New fields synced from website
  final String? label;       // Room specificity e.g. 'AC Room', 'Attached Washroom'
  final int totalInventory; // Total number of rooms of this type
  final bool isVacant;       // Has vacancies (from registration form)
  final String? otherInfo;   // Extra room description text
  final String? category;    // 'Standard' | 'Deluxe' | 'AC' | etc.
  final String? name;        // Room display name (sometimes used instead of occupancy)

  static const Object _sentinel = Object();

  RoomModel({
    required this.id,
    required this.messId,
    required this.roomType,
    required this.occupancy,
    required this.price,
    this.rent,
    this.imageUrls = const [],
    this.images = const [],
    this.amenities = const {},
    this.availableCount = 0,
    this.totalInventory = 1,
    this.available,
    this.district = 'balasore',
    this.rentCycle = 'monthly',
    this.label,
    this.isVacant = true,
    this.otherInfo,
    this.category,
    this.name,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    // Combine all image sources
    final imageUrlsList = (map['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final imagesList = (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    // Also support mediaUrls (new format from registration: list of {url, type} objects)
    final mediaUrls = <String>[];
    if (map['mediaUrls'] is List) {
      for (final item in (map['mediaUrls'] as List)) {
        if (item is Map && item['url'] != null) {
          mediaUrls.add(item['url'].toString());
        } else if (item is String) {
          mediaUrls.add(item);
        }
      }
    }

    return RoomModel(
      id: id,
      messId: map['messId']?.toString() ?? '',
      roomType: map['roomType']?.toString() ?? 'Unknown',
      occupancy: map['occupancy']?.toString() ?? map['name']?.toString() ?? 'Other',
      price: _toInt(map['price'] ?? map['rent']),
      rent: _toNullableInt(map['rent']),
      imageUrls: [...imageUrlsList, ...mediaUrls],
      images: imagesList,
      amenities: map['amenities'] is Map ? Map<String, dynamic>.from(map['amenities']) : {},
      availableCount: _toInt(map['availableCount']),
      totalInventory: _toInt(map['totalInventory']) > 0 ? _toInt(map['totalInventory']) : 1,
      available: map['available'] != null ? _parseBool(map['available']) : null,
      district: map['district']?.toString() ?? 'balasore',
      rentCycle: map['rentCycle']?.toString() ?? 'monthly',
      label: map['label']?.toString(),
      isVacant: _parseBool(map['isVacant'], defaultValue: true),
      otherInfo: map['otherInfo']?.toString(),
      category: map['category']?.toString(),
      name: map['name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messId': messId,
      'roomType': roomType,
      'occupancy': occupancy,
      'price': price,
      'rent': rent,
      'imageUrls': imageUrls,
      'images': images,
      'amenities': amenities,
      'availableCount': availableCount,
      'totalInventory': totalInventory,
      'available': available,
      'district': district,
      'rentCycle': rentCycle,
      'label': label,
      'isVacant': isVacant,
      'otherInfo': otherInfo,
      'category': category,
      'name': name,
    };
  }

  /// Returns the best display name for this room type
  String get displayName => label ?? occupancy;

  /// Effective vacancy: use isVacant flag, then availableCount, then available bool
  bool get hasVacancy {
    if (!isVacant) return false;
    if (available != null) return available!;
    return availableCount > 0;
  }

  RoomModel copyWith({
    String? id,
    String? messId,
    String? roomType,
    String? occupancy,
    int? price,
    Object? rent = _sentinel,
    List<String>? imageUrls,
    List<String>? images,
    Map<String, dynamic>? amenities,
    int? availableCount,
    Object? available = _sentinel,
    String? district,
    String? rentCycle,
    Object? label = _sentinel,
    bool? isVacant,
    Object? otherInfo = _sentinel,
    Object? category = _sentinel,
    Object? name = _sentinel,
  }) {
    return RoomModel(
      id: id ?? this.id,
      messId: messId ?? this.messId,
      roomType: roomType ?? this.roomType,
      occupancy: occupancy ?? this.occupancy,
      price: price ?? this.price,
      rent: rent == _sentinel ? this.rent : rent as int?,
      imageUrls: imageUrls ?? this.imageUrls,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      availableCount: availableCount ?? this.availableCount,
      available: available == _sentinel ? this.available : available as bool?,
      district: district ?? this.district,
      rentCycle: rentCycle ?? this.rentCycle,
      label: label == _sentinel ? this.label : label as String?,
      isVacant: isVacant ?? this.isVacant,
      otherInfo: otherInfo == _sentinel ? this.otherInfo : otherInfo as String?,
      category: category == _sentinel ? this.category : category as String?,
      name: name == _sentinel ? this.name : name as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messId == other.messId &&
          roomType == other.roomType &&
          occupancy == other.occupancy &&
          price == other.price &&
          rent == other.rent &&
          listEquals(imageUrls, other.imageUrls) &&
          listEquals(images, other.images) &&
          mapEquals(amenities, other.amenities) &&
          availableCount == other.availableCount &&
          available == other.available &&
          district == other.district &&
          rentCycle == other.rentCycle &&
          label == other.label &&
          isVacant == other.isVacant &&
          otherInfo == other.otherInfo;

  @override
  int get hashCode =>
      id.hashCode ^
      messId.hashCode ^
      roomType.hashCode ^
      occupancy.hashCode ^
      price.hashCode ^
      rent.hashCode ^
      imageUrls.hashCode ^
      images.hashCode ^
      amenities.hashCode ^
      availableCount.hashCode ^
      available.hashCode ^
      district.hashCode ^
      rentCycle.hashCode ^
      label.hashCode ^
      isVacant.hashCode;
}
