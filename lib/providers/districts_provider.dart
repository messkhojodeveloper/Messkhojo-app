import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants/districts_config.dart';

/// Watches `app_config/districts` in Firestore.
/// Shape: { districts: { districtId: { id, name, active, order, gpsCenter, cities, landmarks, ... } } }
///
/// This is the same document the website's DistrictContext reads from.
/// The Operational Dashboard (LocationManagerTab) writes to this document.
///
/// Falls back to the static [DistrictsConfig.all] if:
///   - The document doesn't exist yet
///   - A specific district isn't in Firestore yet
final districtsStreamProvider =
    StreamProvider<Map<String, DistrictConfig>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('districts')
      .snapshots()
      .map((snap) {
    // Start with the bundled static config
    final fallback = Map<String, DistrictConfig>.from(DistrictsConfig.all);

    if (!snap.exists || snap.data() == null) return fallback;

    final rawDistricts = snap.data()!['districts'];
    if (rawDistricts == null || rawDistricts is! Map) return fallback;

    final data = Map<String, dynamic>.from(rawDistricts);
    final merged = Map<String, DistrictConfig>.from(fallback);

    // Merge Firestore data on top of static fallback
    data.forEach((key, value) {
      if (value is Map) {
        final val = Map<String, dynamic>.from(value);
        merged[key] = _parseDistrictConfig(key, val, fallback[key]);
      }
    });

    // Cache to SharedPreferences for offline boot
    _cacheDistricts(merged);

    // Sync to global DistrictsConfig so legacy/non-Riverpod callers immediately get updates
    DistrictsConfig.setDynamicDistricts(merged);

    return merged;
  });
});

/// A synchronous provider that immediately returns cached or static config.
/// This ensures widgets never see a loading state for district data.
final cachedDistrictsProvider = Provider<Map<String, DistrictConfig>>((ref) {
  final asyncValue = ref.watch(districtsStreamProvider);
  return asyncValue.when(
    data: (data) => data,
    loading: () => DistrictsConfig.all,
    error: (_, __) => DistrictsConfig.all,
  );
});

/// List of active districts, sorted by order.
final activeDistrictsProvider = Provider<List<DistrictConfig>>((ref) {
  final all = ref.watch(cachedDistrictsProvider);
  final active = all.values.where((d) => d.active).toList();
  active.sort((a, b) => (a.order ?? 99).compareTo(b.order ?? 99));
  return active;
});

/// Get display name for a city across all loaded districts.
final cityDisplayNameProvider = Provider.family<String, String>((ref, cityId) {
  final all = ref.watch(cachedDistrictsProvider);
  if (cityId == 'baleshwar') return 'Balasore';
  if (cityId == 'other') return 'Other Localities';
  for (final district in all.values) {
    final matches = district.cities.where((c) => c.id == cityId).toList();
    if (matches.isNotEmpty) return matches.first.name;
  }
  return cityId.isNotEmpty
      ? cityId[0].toUpperCase() + cityId.substring(1)
      : cityId;
});

/// Get districtId for a cityId across all loaded districts.
final districtForCityProvider = Provider.family<String?, String>((ref, cityId) {
  final all = ref.watch(cachedDistrictsProvider);
  for (final entry in all.entries) {
    if (entry.value.cities.any((c) => c.id == cityId)) {
      return entry.key;
    }
  }
  return null;
});

/// City display order – dynamic based on loaded config.
final cityDisplayOrderProvider = Provider<List<String>>((ref) {
  final all = ref.watch(cachedDistrictsProvider);
  final sorted = all.values.toList()
    ..sort((a, b) => (a.order ?? 99).compareTo(b.order ?? 99));
  final order = <String>[];
  for (final district in sorted) {
    for (final city in district.cities) {
      order.add(city.id);
    }
  }
  order.add('other');
  return order;
});

// ─── Private helpers ─────────────────────────────────────────────────────────

DistrictConfig _parseDistrictConfig(
    String key, Map<String, dynamic> val, DistrictConfig? fallback) {
  // Parse cities
  final rawCities = val['cities'];
  List<DistrictCity> cities;
  if (rawCities is List) {
    cities = rawCities.map((c) {
      if (c is Map) {
        return DistrictCity(
          id: c['id']?.toString() ?? '',
          name: c['name']?.toString() ?? '',
        );
      }
      return const DistrictCity(id: '', name: '');
    }).where((c) => c.id.isNotEmpty).toList();
  } else {
    cities = fallback?.cities ?? [];
  }

  // Parse landmarks
  final rawLandmarks = val['landmarks'];
  List<String> landmarks;
  if (rawLandmarks is List) {
    landmarks = rawLandmarks.map((l) {
      if (l is Map) return l['name']?.toString() ?? '';
      return l.toString();
    }).where((s) => s.isNotEmpty).toList();
  } else {
    landmarks = fallback?.landmarks ?? [];
  }

  // Parse GPS center
  final rawGps = val['gpsCenter'];
  double lat = fallback?.gpsCenterLat ?? 0;
  double lng = fallback?.gpsCenterLng ?? 0;
  if (rawGps is Map) {
    lat = (rawGps['lat'] as num?)?.toDouble() ?? lat;
    lng = (rawGps['lng'] as num?)?.toDouble() ?? lng;
  }

  return DistrictConfig(
    id: key,
    name: val['name']?.toString() ?? fallback?.name ?? key,
    active: val['active'] as bool? ?? fallback?.active ?? true,
    order: val['order'] as int? ?? fallback?.order,
    heroTitle: val['heroTitle']?.toString() ?? fallback?.heroTitle,
    heroSubtitle: val['heroSubtitle']?.toString() ?? fallback?.heroSubtitle,
    cities: cities,
    landmarks: landmarks,
    gpsCenterLat: lat,
    gpsCenterLng: lng,
  );
}

Future<void> _cacheDistricts(Map<String, DistrictConfig> districts) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = <String, dynamic>{};
    districts.forEach((key, dist) {
      jsonMap[key] = {
        'id': dist.id,
        'name': dist.name,
        'active': dist.active,
        'order': dist.order,
        'gpsCenterLat': dist.gpsCenterLat,
        'gpsCenterLng': dist.gpsCenterLng,
        'heroTitle': dist.heroTitle,
        'heroSubtitle': dist.heroSubtitle,
        'cities': dist.cities
            .map((c) => {'id': c.id, 'name': c.name})
            .toList(),
        'landmarks': dist.landmarks,
      };
    });
    await prefs.setString('_mk_districts_cache', jsonEncode(jsonMap));
  } catch (_) {
    // Quota exceeded or other issue — ignore
  }
}
