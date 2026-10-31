/// Dart port of the React website's DISTRICTS_CONFIG.
/// Defines all active districts, their cities, landmarks, and GPS centers.
class DistrictCity {
  final String id;
  final String name;

  const DistrictCity({required this.id, required this.name});
}

class DistrictConfig {
  final String id;
  final String name;
  final bool active;
  final int? order;
  final String? heroTitle;
  final String? heroSubtitle;
  final List<DistrictCity> cities;
  final List<String> landmarks;
  final double gpsCenterLat;
  final double gpsCenterLng;

  const DistrictConfig({
    required this.id,
    required this.name,
    required this.active,
    this.order,
    this.heroTitle,
    this.heroSubtitle,
    required this.cities,
    required this.landmarks,
    required this.gpsCenterLat,
    required this.gpsCenterLng,
  });

  String? cityName(String cityId) {
    try {
      return cities.firstWhere((c) => c.id == cityId).name;
    } catch (_) {
      return null;
    }
  }
}

class DistrictsConfig {
  static const Map<String, DistrictConfig> _defaults = {
    'balasore': DistrictConfig(
      id: 'balasore',
      name: 'Balasore',
      active: true,
      gpsCenterLat: 21.4934,
      gpsCenterLng: 86.9294,
      cities: [
        DistrictCity(id: 'baleshwar', name: 'Baleshwar (Balasore City)'),
        DistrictCity(id: 'remuna', name: 'Remuna'),
      ],
      landmarks: [
        'Mansingh Bazar',
        'Fakir Mohan Golei',
        'Station Square',
        'Remuna',
        'Sahadev Khuntha',
        'Azimabad',
        'ITB',
        'Balasore',
      ],
    ),
    'bhadrak': DistrictConfig(
      id: 'bhadrak',
      name: 'Bhadrak',
      active: true,
      gpsCenterLat: 21.0672,
      gpsCenterLng: 86.4886,
      cities: [
        DistrictCity(id: 'bhadrak', name: 'Bhadrak'),
        DistrictCity(id: 'basudevpur', name: 'Basudevpur'),
      ],
      landmarks: [
        'Bhadrak Station',
        'Charampa',
        'Bhadrak College',
        'By Pass',
        'Dakshinakali',
        'Bhadrak',
      ],
    ),
    'mayurbhanj': DistrictConfig(
      id: 'mayurbhanj',
      name: 'Mayurbhanj',
      active: true,
      gpsCenterLat: 21.9320,
      gpsCenterLng: 86.7513,
      cities: [
        DistrictCity(id: 'baripada', name: 'Baripada'),
      ],
      landmarks: [
        'Baripada Station',
        'Lal Bazar',
        'Palbani',
        'Baghra Road',
        'MKC High School',
        'Baripada',
      ],
    ),
    'jajpur': DistrictConfig(
      id: 'jajpur',
      name: 'Jajpur',
      active: true,
      gpsCenterLat: 20.8502,
      gpsCenterLng: 86.3361,
      cities: [
        DistrictCity(id: 'jajpur_road', name: 'Jajpur Road (Vyasanagar)'),
        DistrictCity(id: 'jajpur_town', name: 'Jajpur Town'),
      ],
      landmarks: [
        'Jajpur Road',
        'Vyasanagar',
        'Chorda Bypass',
        'NC College Road',
        'Biraja Temple',
        'Jajpur Town',
        'Jajpur',
      ],
    ),
    'khorda': DistrictConfig(
      id: 'khorda',
      name: 'Khorda',
      active: true,
      gpsCenterLat: 20.2961,
      gpsCenterLng: 85.8245,
      cities: [
        DistrictCity(id: 'bhubaneswar', name: 'Bhubaneswar'),
        DistrictCity(id: 'khordha_town', name: 'Khordha Town'),
      ],
      landmarks: [
        'Patia',
        'Khandagiri',
        'Jayadev Vihar',
        'Saheed Nagar',
        'Nayapalli',
        'Chandrasekharpur',
        'Master Canteen',
        'Baramunda',
        'Acharya Vihar',
        'Rasulgarh',
        'Infocity',
        'Kalinga Nagar',
        'Vani Vihar',
        'Old Town',
        'Bhubaneswar',
        'Khorda New Bus Stand',
        'Gurujang',
        'Khorda Town',
      ],
    ),
  };

  static Map<String, DistrictConfig> _current =
      Map<String, DistrictConfig>.from(_defaults);

  static Map<String, DistrictConfig> get all => _current;

  static void setDynamicDistricts(Map<String, DistrictConfig> updated) {
    _current = Map<String, DistrictConfig>.from(updated);
  }

  static const List<String> cityDisplayOrder = [
    'baleshwar',
    'remuna',
    'bhadrak',
    'basudevpur',
    'baripada',
    'jajpur_road',
    'jajpur_town',
    'bhubaneswar',
    'khordha_town',
    'other',
  ];

  static List<DistrictConfig> get activeDistricts =>
      all.values.where((d) => d.active).toList();

  static String getCityDisplayName(String cityId) {
    if (cityId == 'baleshwar') return 'Balasore';
    if (cityId == 'other') return 'Other Localities';
    for (final district in all.values) {
      final matches = district.cities.where((c) => c.id == cityId).toList();
      if (matches.isNotEmpty) return matches.first.name;
    }
    return cityId[0].toUpperCase() + cityId.substring(1);
  }

  static String? getDistrictForCity(String cityId) {
    for (final entry in all.entries) {
      if (entry.value.cities.any((c) => c.id == cityId)) {
        return entry.key;
      }
    }
    return null;
  }

  static List<String> getLandmarksForCity(String cityId) {
    // Bhubaneswar has city-specific landmarks
    if (cityId == 'bhubaneswar') {
      return [
        'Patia', 'Khandagiri', 'Jayadev Vihar', 'Saheed Nagar', 'Nayapalli',
        'Chandrasekharpur', 'Master Canteen', 'Baramunda', 'Acharya Vihar',
        'Rasulgarh', 'Infocity', 'Kalinga Nagar', 'Vani Vihar', 'Old Town',
        'Bhubaneswar',
      ];
    }
    if (cityId == 'khordha_town') {
      return [
        'Khorda New Bus Stand', 'Khorda Old Bus Stand', 'Gurujang',
        'Collectorate Road', 'Khordha Road Junction', 'Khorda Town',
      ];
    }
    // For all other cities, use district landmarks
    final districtId = getDistrictForCity(cityId);
    if (districtId != null && all.containsKey(districtId)) {
      return all[districtId]!.landmarks;
    }
    return [];
  }

  static List<String> get allLandmarks {
    final set = <String>{};
    for (final district in all.values) {
      set.addAll(district.landmarks);
    }
    return set.toList();
  }
}
