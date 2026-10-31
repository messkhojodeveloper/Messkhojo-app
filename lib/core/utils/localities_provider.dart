import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/districts_config.dart';

/// Watches `app_config/localities` in Firestore.
/// Shape: { cityId: ['Locality A', 'Locality B', ...] }
///
/// This is the same document the website's DistrictContext reads from.
/// The Operational Dashboard (LocalitiesTab) writes to this document.
///
/// Falls back to the static [DistrictsConfig.getLandmarksForCity] if:
///   - The document doesn't exist yet
///   - A specific city isn't in Firestore yet
final localitiesStreamProvider =
    StreamProvider<Map<String, List<String>>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('localities')
      .snapshots()
      .map((snap) {
    // Build fallback map from static config
    final fallback = _buildFallbackMap();

    if (!snap.exists || snap.data() == null) return fallback;

    final data = snap.data()!;
    final merged = Map<String, List<String>>.from(fallback);

    // Merge Firestore data — Firestore values take priority
    data.forEach((key, value) {
      if (value is List) {
        final list = value.map((e) => e.toString()).toList();
        if (list.isNotEmpty) {
          merged[key] = list;
        }
      }
    });

    return merged;
  });
});

Map<String, List<String>> _buildFallbackMap() {
  final map = <String, List<String>>{};
  for (final district in DistrictsConfig.all.values) {
    for (final city in district.cities) {
      map[city.id] = DistrictsConfig.getLandmarksForCity(city.id);
    }
  }
  return map;
}

/// Helper: get localities for a specific city from the merged config.
/// Returns an empty list if city is not found.
List<String> getLocalitiesForCity(
    String cityId, Map<String, List<String>> localitiesConfig) {
  if (localitiesConfig.containsKey(cityId) &&
      localitiesConfig[cityId]!.isNotEmpty) {
    return localitiesConfig[cityId]!;
  }
  return DistrictsConfig.getLandmarksForCity(cityId);
}
