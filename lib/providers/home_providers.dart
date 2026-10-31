import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/districts_config.dart';
import '../core/utils/fuzzy_search.dart';
import '../data/models/mess_model.dart';
import '../data/models/room_model.dart';

class FilterState {
  final String location;
  final int? minPrice;
  final int? maxPrice;
  final Map<String, bool> amenities;
  final bool availableOnly;
  final String messType;
  final String messName;

  static const Object _sentinel = Object();

  const FilterState({
    this.location = '',
    this.minPrice,
    this.maxPrice,
    this.amenities = const {
      'wifi': false,
      'ac': false,
      'food': false,
      'inverter': false,
      'tableChair': false,
    },
    this.availableOnly = false,
    this.messType = '',
    this.messName = '',
  });

  FilterState copyWith({
    String? location,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Map<String, bool>? amenities,
    bool? availableOnly,
    String? messType,
    String? messName,
  }) {
    return FilterState(
      location: location ?? this.location,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as int?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
      amenities: amenities ?? this.amenities,
      availableOnly: availableOnly ?? this.availableOnly,
      messType: messType ?? this.messType,
      messName: messName ?? this.messName,
    );
  }

  bool get hasFilters =>
      location.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      amenities.values.any((v) => v) ||
      availableOnly ||
      messType.isNotEmpty;
}

class UserLocation {
  final double lat;
  final double lng;
  final String? address;

  const UserLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  factory UserLocation.fromPosition(Position position) {
    return UserLocation(
      lat: position.latitude,
      lng: position.longitude,
      address: 'Your Location',
    );
  }

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'],
    );
  }
}

final messesStreamProvider = FutureProvider<List<MessModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(AppConstants.messesCollection)
      .get();
  debugPrint('messesProvider fetch completed: ${snapshot.docs.length} docs');
  final list = snapshot.docs.map((doc) {
    try {
      return MessModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Error parsing mess ${doc.id}: $e');
      return null;
    }
  }).whereType<MessModel>().where((m) => !m.hidden).toList();
  debugPrint('messesProvider parsed & filtered (hidden=false): ${list.length} messes');
  return list;
});

final messesProvider = messesStreamProvider;

final roomsStreamProvider = FutureProvider<List<RoomModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(AppConstants.roomsCollection)
      .get();
  debugPrint('roomsProvider fetch completed: ${snapshot.docs.length} docs');
  final list = snapshot.docs.map((doc) {
    try {
      return RoomModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Error parsing room ${doc.id}: $e');
      return null;
    }
  }).whereType<RoomModel>().toList();
  debugPrint('roomsProvider parsed: ${list.length} rooms');
  return list;
});

final roomsProvider = roomsStreamProvider;

/// O(1) room lookup map: `Map<String, List<RoomModel>>`.
/// Precomputed once so filtering and grouping never do O(N*M) nested loops.
final roomsByMessProvider = Provider<Map<String, List<RoomModel>>>((ref) {
  final rooms = ref.watch(roomsStreamProvider).value ?? [];
  final map = <String, List<RoomModel>>{};
  for (final room in rooms) {
    map.putIfAbsent(room.messId, () => []).add(room);
  }
  return map;
});

final carouselEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance.doc('app_config/hero').get();
    if (doc.exists) {
      return doc.data()?['carouselEnabled'] ?? false;
    }
  } catch (_) {}
  return false;
});

class HomeFiltersNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void updateFilters(FilterState filters) {
    state = filters;
  }

  void updateLocation(UserLocation location) {
    state = state.copyWith(location: location.address ?? '');
  }

  void clearLocation() {
    state = state.copyWith(location: '');
  }

  void reset() {
    state = const FilterState();
  }
}

final homeFiltersProvider = NotifierProvider<HomeFiltersNotifier, FilterState>(() {
  return HomeFiltersNotifier();
});

class UserLocationNotifier extends Notifier<UserLocation?> {
  @override
  UserLocation? build() => null;

  void setLocation(UserLocation location) {
    state = location;
  }

  void clearLocation() {
    state = null;
  }

  Future<String> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permission denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      double lat = position.latitude;
      double lng = position.longitude;

      state = UserLocation(lat: lat, lng: lng, address: 'Your Location');
      return 'GPS location captured successfully!';
    } catch (e) {
      return 'Failed to get location: ${e.toString()}';
    }
  }
}

final userLocationProvider = NotifierProvider<UserLocationNotifier, UserLocation?>(() {
  return UserLocationNotifier();
});

final displayCountProvider = NotifierProvider<DisplayCountNotifier, int>(DisplayCountNotifier.new);

class DisplayCountNotifier extends Notifier<int> {
  @override
  int build() => 12;
  
  void increment() => state += 12;
  void reset() => state = 12;
}

final filteredMessesProvider = Provider<List<MessModel>>((ref) {
  final messesAsync = ref.watch(messesStreamProvider);
  final roomsByMess = ref.watch(roomsByMessProvider);
  final filters = ref.watch(homeFiltersProvider);
  final userLocation = ref.watch(userLocationProvider);

  if (messesAsync.hasError) {
    debugPrint('messesStreamProvider error: ${messesAsync.error}');
  }

  final messes = messesAsync.value ?? [];

  final filtered = messes.map((mess) {
    if (mess.hidden) return null;

    double? distance;
    if (userLocation != null && mess.latitude != null && mess.longitude != null) {
      distance = calculateDistance(
        userLocation.lat,
        userLocation.lng,
        mess.latitude!,
        mess.longitude!,
      );
    }

    int searchScore = 0;
    if (filters.location.isNotEmpty) {
      final nameScore = fuzzyScore(filters.location, mess.name);
      final addrScore = fuzzyScore(filters.location, mess.address);
      searchScore = nameScore > addrScore * 0.8 ? nameScore : (addrScore * 0.8).round();
    }

    if (filters.messType.isNotEmpty && mess.messType != filters.messType) {
      return null;
    }

    final messRooms = roomsByMess[mess.id] ?? const <RoomModel>[];

    bool checkAmenity(String key) {
      final val = mess.amenities[key];
      if (val != null) {
        if (val is bool) return val;
        if (val is String) return val.toLowerCase() == 'true';
        if (val is num) return val != 0;
      }
      return messRooms.any((r) {
        final rv = r.amenities[key];
        if (rv == null) return false;
        if (rv is bool) return rv;
        if (rv is String) return rv.toLowerCase() == 'true';
        if (rv is num) return rv != 0;
        return false;
      });
    }

    if (filters.amenities['food'] == true && !checkAmenity('food')) return null;
    if (filters.amenities['wifi'] == true && !checkAmenity('wifi')) return null;
    if (filters.amenities['inverter'] == true && !checkAmenity('inverter')) return null;

    final matchingRooms = messRooms.where((room) {
      final price = room.price;
      final amenities = room.amenities;

      if (filters.minPrice != null && price < filters.minPrice!) return false;
      if (filters.maxPrice != null && price > filters.maxPrice!) return false;
      if (filters.amenities['ac'] == true && amenities['ac'] != true) return false;
      if (filters.availableOnly == true &&
          (room.availableCount == 0 || room.available == false)) {
        return false;
      }
      return true;
    }).toList();

    final hasRoomCriteria = filters.minPrice != null ||
        filters.maxPrice != null ||
        filters.availableOnly ||
        filters.amenities['ac'] == true;

    if (hasRoomCriteria && matchingRooms.isEmpty) return null;

    final matchingBeds = matchingRooms.fold<int>(0, (acc, room) => acc + room.availableCount);

    final prices = messRooms.map((r) => r.price).where((p) => p > 0).toList();
    final int? minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : null;
    final int? maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : null;

    int totalImages = 0;
    if (mess.galleryUrls.isNotEmpty) {
      totalImages += mess.galleryUrls
          .where((url) => url.isNotEmpty && url.length > 10 && !url.contains('placeholder'))
          .length;
    }
    for (final room in messRooms) {
      if (room.imageUrls.isNotEmpty) {
        totalImages += room.imageUrls
            .where((url) => url.isNotEmpty && url.length > 10 && !url.contains('placeholder'))
            .length;
      }
    }

    final isFiltered = filters.location.isNotEmpty ||
        filters.minPrice != null ||
        filters.maxPrice != null ||
        filters.availableOnly ||
        filters.messType.isNotEmpty ||
        filters.amenities.values.any((v) => v);

    final result = mess.copyWith(
      distance: distance,
      searchScore: searchScore,
      matchingBeds: matchingBeds,
      isFiltered: isFiltered,
      minPrice: minPrice,
      maxPrice: maxPrice,
      totalImages: totalImages,
    );
    return result;
  }).whereType<MessModel>().toList();

  debugPrint('Filtered count before sort: ${filtered.length}');

  if (filters.location.isNotEmpty) {
    final exactMatches = filtered.where((m) => m.searchScore >= 100).toList();
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    } else {
      final fuzzyMatches = filtered.where((m) => m.searchScore > 0).toList()
        ..sort((a, b) => b.searchScore - a.searchScore);
      return fuzzyMatches.take(10).toList();
    }
  } else if (userLocation != null) {
    filtered.sort((a, b) {
      final distA = a.distance ?? double.infinity;
      final distB = b.distance ?? double.infinity;
      return distA.compareTo(distB);
    });
  } else {
    filtered.sort((a, b) {
      if (a.isSponsored && b.isSponsored) {
        return (a.sponsorRank ?? 999) - (b.sponsorRank ?? 999);
      }
      if (a.isSponsored != b.isSponsored) return a.isSponsored ? -1 : 1;

      if (a.isUserSourced != b.isUserSourced) {
        return a.isUserSourced ? 1 : -1;
      }

      final hasPosterA = (a.posterUrl?.length ?? 0) > 5;
      final hasPosterB = (b.posterUrl?.length ?? 0) > 5;
      if (hasPosterA != hasPosterB) return hasPosterB ? 1 : -1;

      if (a.totalImages != b.totalImages) return b.totalImages - a.totalImages;

      return a.name.compareTo(b.name);
    });
  }

  return filtered;
});

final displayedMessesProvider = Provider<List<MessModel>>((ref) {
  final messes = ref.watch(filteredMessesProvider);
  final displayCount = ref.watch(displayCountProvider);
  return messes.take(displayCount).toList();
});

final hasMoreMessesProvider = Provider<bool>((ref) {
  final messes = ref.watch(filteredMessesProvider);
  final displayCount = ref.watch(displayCountProvider);
  return displayCount < messes.length;
});

final isFuzzySearchProvider = Provider<bool>((ref) {
  final filters = ref.watch(homeFiltersProvider);
  final messes = ref.watch(filteredMessesProvider);
  if (filters.location.isEmpty) return false;
  return messes.any((m) => m.searchScore > 0 && m.searchScore < 100);
});

final messCountProvider = Provider<int>((ref) {
  final messes = ref.watch(messesStreamProvider);
  return messes.value?.length ?? 0;
});

/// Groups all (non-hidden) messes by their city field, enriches each mess
/// with price range, and sorts within each group using the same ranking
/// as the React website's useAllCityMesses hook.
final messesByCityProvider = Provider<Map<String, List<MessModel>>>((ref) {
  final messesAsync = ref.watch(messesStreamProvider);
  final roomsByMess = ref.watch(roomsByMessProvider);

  final messes = messesAsync.value ?? [];
  final Map<String, List<MessModel>> groups = {};

  for (final mess in messes) {
    if (mess.hidden) continue;

    final messRooms = roomsByMess[mess.id] ?? const <RoomModel>[];

    // Enrich with price range
    final prices = messRooms.map((r) => r.price).where((p) => p > 0).toList();
    final int? minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : null;
    final int? maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : null;

    // Total real images (gallery + room images, excluding placeholders)
    int totalImages = mess.galleryUrls
        .where((u) => u.isNotEmpty && u.length > 10 && !u.contains('placeholder'))
        .length;
    for (final room in messRooms) {
      totalImages += room.imageUrls
          .where((u) => u.isNotEmpty && u.length > 10 && !u.contains('placeholder'))
          .length;
    }

    final enriched = mess.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      totalImages: totalImages,
    );

    final cityKey = mess.city.trim().toLowerCase().isEmpty ? 'other' : mess.city.trim().toLowerCase();
    groups.putIfAbsent(cityKey, () => []).add(enriched);
  }

  // Sort within each city group (mirrors React ranking logic)
  for (final key in groups.keys) {
    groups[key]!.sort((a, b) {
      // 1. Sponsored first
      if (a.isSponsored != b.isSponsored) return a.isSponsored ? -1 : 1;
      if (a.isSponsored && b.isSponsored) {
        return (a.sponsorRank ?? 999).compareTo(b.sponsorRank ?? 999);
      }
      // 2. User-sourced last
      if (a.isUserSourced != b.isUserSourced) return a.isUserSourced ? 1 : -1;
      // 3. Has poster image
      final hasPosterA = (a.posterUrl?.length ?? 0) > 5;
      final hasPosterB = (b.posterUrl?.length ?? 0) > 5;
      if (hasPosterA != hasPosterB) return hasPosterB ? 1 : -1;
      // 4. Image count
      if (a.totalImages != b.totalImages) return b.totalImages - a.totalImages;
      // 5. Alphabetical
      return a.name.compareTo(b.name);
    });
  }

  return groups;
});

/// All unique landmark strings from DistrictsConfig + mess addresses/landmarks.
final allLandmarksProvider = Provider<List<String>>((ref) {
  final messesAsync = ref.watch(messesStreamProvider);
  final messes = messesAsync.value ?? [];

  final set = <String>{};
  // Predefined landmarks from config
  set.addAll(DistrictsConfig.allLandmarks);
  // Dynamic landmarks from mess data
  for (final mess in messes) {
    if (mess.address.isNotEmpty) set.add(mess.address.trim());
  }
  return set.toList();
});

/// Structured search suggestions (districts, messes, landmarks, cities)
/// based on current search query.
class SearchSuggestions {
  final List<Map<String, String>> districts;
  final List<MessModel> messes;
  final List<String> landmarks;
  final List<Map<String, String>> cities;

  const SearchSuggestions({
    this.districts = const [],
    this.messes = const [],
    this.landmarks = const [],
    this.cities = const [],
  });

  int get count => districts.length + messes.length + landmarks.length + cities.length;
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class CitySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final citySearchQueryProvider = NotifierProvider<CitySearchQueryNotifier, String>(CitySearchQueryNotifier.new);

final searchSuggestionsProvider = Provider<SearchSuggestions>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final messesAsync = ref.watch(messesStreamProvider);
  final landmarks = ref.watch(allLandmarksProvider);
  final messes = messesAsync.value ?? [];

  if (query.isEmpty) {
    // Show all districts when no query
    final districts = DistrictsConfig.activeDistricts
        .map((d) => {'id': d.id, 'name': d.name})
        .toList();
    return SearchSuggestions(districts: districts);
  }

  // 1. Districts (max 3)
  final matchedDistricts = DistrictsConfig.activeDistricts
      .where((d) => d.name.toLowerCase().contains(query))
      .take(3)
      .map((d) => {'id': d.id, 'name': d.name})
      .toList();

  // 2. Messes (max 5)
  final matchedMesses = messes
      .where((m) => !m.hidden && m.name.toLowerCase().contains(query))
      .take(5)
      .toList();

  // 3. Landmarks (max 3)
  final matchedLandmarks = landmarks
      .where((lm) => lm.toLowerCase().contains(query))
      .take(3)
      .toList();

  // 4. Cities (max 3)
  final matchedCities = <Map<String, String>>[];
  for (final district in DistrictsConfig.all.values) {
    for (final city in district.cities) {
      if (city.name.toLowerCase().contains(query) || city.id.toLowerCase().contains(query)) {
        matchedCities.add({
          'id': city.id,
          'name': DistrictsConfig.getCityDisplayName(city.id),
          'districtId': district.id,
        });
        if (matchedCities.length >= 3) break;
      }
    }
    if (matchedCities.length >= 3) break;
  }

  return SearchSuggestions(
    districts: matchedDistricts,
    messes: matchedMesses,
    landmarks: matchedLandmarks,
    cities: matchedCities,
  );
});

void loadMoreMesses(WidgetRef ref) {
  ref.read(displayCountProvider.notifier).increment();
}

void resetDisplayCount(WidgetRef ref) {
  ref.read(displayCountProvider.notifier).reset();
}