import 'package:cloud_firestore/cloud_firestore.dart';

class MessModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final String messType; // Boys, Girls, Both
  final String? posterUrl;
  final List<String> galleryUrls;
  final Map<String, dynamic> amenities;
  final GeoPoint? location;
  final String? locationUrl;
  final bool hidden;
  final bool isUserSourced;
  final bool isSponsored;
  final int? sponsorRank;
  final DateTime? lastUpdatedDate;
  final String? foodFacility;
  final String? security;
  final String? extraAppliances;
  final String? advanceDeposit;
  final String district;
  final String city; // city id like 'baleshwar', 'remuna', 'bhadrak'
  final String contact;
  final bool hideContact;
  final String rentCycle; // 'monthly' or 'yearly'
  final String? adminId; // partner user ID who owns this listing

  // Locality / landmark within a city
  final String? locality; // e.g. 'Patia', 'Saheed Nagar'

  // "About & Facilities" fields
  final String? managedBy;
  final Map<String, dynamic>? advancePayment;
  final Map<String, dynamic>? maintenanceCharge;
  final List<String>? includedInRent;
  final List<String>? facilities;

  // Food fields
  final String? foodAvailability;   // 'Food Available' | 'Self Cook' | 'No Food'
  final String? mealsPerDay;         // '3 Meals' | '2 Meals' | etc.
  final String? foodType;            // 'Veg + Non-Veg' | 'Veg Only' | etc.
  final String? foodBill;            // 'Included in Rent' | 'Separate' | 'Self Cook'
  final String? utensilsCharges;     // 'Provided' | 'Chargeable' | 'Bring Own'

  // Water & Cleaning
  final String? waterFacility;       // 'Borewell' | 'Municipal' | 'Both'
  final String? laundryFacility;     // 'Washing Machine' | 'Manual' | 'Both' | 'None'
  final String? cleaningService;     // 'Both' | 'Rooms Only' | 'Common Area Only' | 'None'

  // Security amenities
  final bool? cctv;
  final bool? wardenWatchman;

  // Extra space
  final List<String>? extraSpace;   // ['Parking', 'Terrace', 'Study Room', ...]

  // Charges
  final String? securityDeposit;    // '1 Month' | '2 Months' | 'No Deposit' | 'Custom'
  final String? electricityBill;    // 'Included in Rent' | 'As per Meter' | 'Extra Fixed'
  final String? electricityBillAmount;
  final String? maintenanceFee;     // 'Included' | 'Extra Charge'
  final String? maintenanceFeeAmount;
  final String? cleaningCharges;    // 'Included in Rent' | 'Extra Charge' | 'None'

  // Notice period & history
  final String? noticePeriod;       // '1 Month' | '2 Months' | '15 Days' | etc.
  final String? operatingSince;     // e.g. '2018'

  // Building/exterior photos
  final List<String>? buildingPhotoUrls;

  // Legacy rent info for backwards-compat (written by website registration form)
  final Map<String, dynamic>? rentInfo;  // { 'Single': 3500, 'Double': 5000, ... }
  final List<String>? vacantRooms;       // ['Single', 'Double']

  // Computed fields (added after fetching)
  final double? latitude;
  final double? longitude;
  final double? distance;
  final int? minPrice;
  final int? maxPrice;
  final int matchingBeds;
  final bool isFiltered;
  final int totalImages;
  final int searchScore;

  static const Object _sentinel = Object();

  MessModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.messType,
    this.posterUrl,
    this.galleryUrls = const [],
    this.amenities = const {},
    this.location,
    this.locationUrl,
    this.hidden = false,
    this.isUserSourced = false,
    this.isSponsored = false,
    this.sponsorRank,
    this.lastUpdatedDate,
    this.foodFacility,
    this.security,
    this.extraAppliances,
    this.advanceDeposit,
    this.district = 'balasore',
    this.city = 'other',
    this.contact = '',
    this.hideContact = false,
    this.rentCycle = 'monthly',
    this.adminId,
    this.locality,
    this.managedBy,
    this.advancePayment,
    this.maintenanceCharge,
    this.includedInRent,
    this.facilities,
    this.foodAvailability,
    this.mealsPerDay,
    this.foodType,
    this.foodBill,
    this.utensilsCharges,
    this.waterFacility,
    this.laundryFacility,
    this.cleaningService,
    this.cctv,
    this.wardenWatchman,
    this.extraSpace,
    this.securityDeposit,
    this.electricityBill,
    this.electricityBillAmount,
    this.maintenanceFee,
    this.maintenanceFeeAmount,
    this.cleaningCharges,
    this.noticePeriod,
    this.operatingSince,
    this.buildingPhotoUrls,
    this.rentInfo,
    this.vacantRooms,
    this.latitude,
    this.longitude,
    this.distance,
    this.minPrice,
    this.maxPrice,
    this.matchingBeds = 0,
    this.isFiltered = false,
    this.totalImages = 0,
    this.searchScore = 0,
  });

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static bool? _parseNullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

  static String _parseMessType(dynamic raw) {
    if (raw == null) return 'Unknown';
    if (raw is List) {
      if (raw.isEmpty) return 'Unknown';
      final cleanedList = raw
          .map((e) => _cleanTypeString(e?.toString() ?? ''))
          .where((e) => e.isNotEmpty && e != 'Unknown')
          .toSet()
          .toList();
      if (cleanedList.isEmpty) return 'Unknown';
      if (cleanedList.length == 1) return cleanedList.first;
      return cleanedList.join(' & ');
    }
    return _cleanTypeString(raw.toString());
  }

  static String _cleanTypeString(String s) {
    String clean = s
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .trim();
    if (clean.isEmpty) return 'Unknown';

    if (clean.contains(',')) {
      final parts = clean
          .split(',')
          .map(_cleanTypeString)
          .where((e) => e.isNotEmpty && e != 'Unknown')
          .toSet()
          .toList();
      if (parts.isNotEmpty) return parts.join(' & ');
    }

    final lower = clean.toLowerCase();
    if (lower.contains('girl')) return 'Girls';
    if (lower.contains('boy')) return 'Boys';
    if (lower == 'both' || lower == 'co-ed' || lower == 'coed' || lower == 'mixed') return 'Both';
    return clean[0].toUpperCase() + clean.substring(1);
  }

  factory MessModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedDate;
    try {
      if (map['lastUpdatedDate'] != null) {
        if (map['lastUpdatedDate'] is Timestamp) {
          parsedDate = (map['lastUpdatedDate'] as Timestamp).toDate();
        } else if (map['lastUpdatedDate'] is String) {
          parsedDate = DateTime.tryParse(map['lastUpdatedDate'] as String);
        }
      }
    } catch (_) {}

    // Extract latitude/longitude from location GeoPoint or separate fields
    double? lat;
    double? lng;
    if (map['location'] is GeoPoint) {
      lat = (map['location'] as GeoPoint).latitude;
      lng = (map['location'] as GeoPoint).longitude;
    } else {
      final rawLat = map['latitude'];
      if (rawLat is num) {
        lat = rawLat.toDouble();
      } else if (rawLat is String) {
        lat = double.tryParse(rawLat);
      }

      final rawLng = map['longitude'];
      if (rawLng is num) {
        lng = rawLng.toDouble();
      } else if (rawLng is String) {
        lng = double.tryParse(rawLng);
      }
    }

    return MessModel(
      id: id,
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      messType: _parseMessType(map['messType'] ?? map['gender']),
      posterUrl: map['posterUrl']?.toString(),
      galleryUrls: (map['galleryUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      amenities: map['amenities'] is Map ? Map<String, dynamic>.from(map['amenities']) : {},
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      locationUrl: map['locationUrl']?.toString(),
      hidden: _parseBool(map['hidden']),
      isUserSourced: _parseBool(map['isUserSourced']),
      isSponsored: _parseBool(map['isSponsored']),
      sponsorRank: map['sponsorRank'] is int ? map['sponsorRank'] : int.tryParse(map['sponsorRank']?.toString() ?? ''),
      lastUpdatedDate: parsedDate,
      foodFacility: map['foodFacility']?.toString(),
      security: map['security']?.toString(),
      extraAppliances: map['extraAppliances']?.toString(),
      advanceDeposit: map['advanceDeposit']?.toString(),
      district: map['district']?.toString() ?? 'balasore',
      city: map['city']?.toString() ?? 'other',
      contact: map['contact']?.toString() ?? '',
      hideContact: map['hideContact'] != null ? _parseBool(map['hideContact']) : false,
      rentCycle: map['rentCycle']?.toString() ?? 'monthly',
      adminId: map['adminId']?.toString(),
      locality: map['locality']?.toString() ?? map['landmark']?.toString(), // 'landmark' is legacy alias
      managedBy: map['managedBy']?.toString(),
      advancePayment: map['advancePayment'] is Map ? Map<String, dynamic>.from(map['advancePayment']) : null,
      maintenanceCharge: map['maintenanceCharge'] is Map ? Map<String, dynamic>.from(map['maintenanceCharge']) : null,
      includedInRent: (map['includedInRent'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      facilities: (map['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      foodAvailability: map['foodAvailability']?.toString(),
      mealsPerDay: map['mealsPerDay']?.toString(),
      foodType: map['foodType']?.toString(),
      foodBill: map['foodBill']?.toString(),
      utensilsCharges: map['utensilsCharges']?.toString(),
      waterFacility: map['waterFacility']?.toString(),
      laundryFacility: map['laundryFacility']?.toString(),
      cleaningService: map['cleaningService']?.toString(),
      cctv: _parseNullableBool(map['cctv']),
      wardenWatchman: _parseNullableBool(map['wardenWatchman']),
      extraSpace: (map['extraSpace'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      securityDeposit: map['securityDeposit']?.toString(),
      electricityBill: map['electricityBill']?.toString(),
      electricityBillAmount: map['electricityBillAmount']?.toString(),
      maintenanceFee: map['maintenanceFee']?.toString(),
      maintenanceFeeAmount: map['maintenanceFeeAmount']?.toString(),
      cleaningCharges: map['cleaningCharges']?.toString(),
      noticePeriod: map['noticePeriod']?.toString(),
      operatingSince: map['operatingSince']?.toString(),
      buildingPhotoUrls: (map['buildingPhotoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      rentInfo: map['rentInfo'] is Map ? Map<String, dynamic>.from(map['rentInfo']) : null,
      vacantRooms: (map['vacantRooms'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'messType': messType,
      'posterUrl': posterUrl,
      'galleryUrls': galleryUrls,
      'amenities': amenities,
      'location': location,
      'locationUrl': locationUrl,
      'hidden': hidden,
      'isUserSourced': isUserSourced,
      'isSponsored': isSponsored,
      'sponsorRank': sponsorRank,
      'lastUpdatedDate': lastUpdatedDate != null ? Timestamp.fromDate(lastUpdatedDate!) : null,
      'foodFacility': foodFacility,
      'security': security,
      'extraAppliances': extraAppliances,
      'advanceDeposit': advanceDeposit,
      'district': district,
      'city': city,
      'contact': contact,
      'hideContact': hideContact,
      'rentCycle': rentCycle,
      'adminId': adminId,
      'locality': locality,
      'managedBy': managedBy,
      'advancePayment': advancePayment,
      'maintenanceCharge': maintenanceCharge,
      'includedInRent': includedInRent,
      'facilities': facilities,
      'foodAvailability': foodAvailability,
      'mealsPerDay': mealsPerDay,
      'foodType': foodType,
      'foodBill': foodBill,
      'utensilsCharges': utensilsCharges,
      'waterFacility': waterFacility,
      'laundryFacility': laundryFacility,
      'cleaningService': cleaningService,
      'cctv': cctv,
      'wardenWatchman': wardenWatchman,
      'extraSpace': extraSpace,
      'securityDeposit': securityDeposit,
      'electricityBill': electricityBill,
      'electricityBillAmount': electricityBillAmount,
      'maintenanceFee': maintenanceFee,
      'maintenanceFeeAmount': maintenanceFeeAmount,
      'cleaningCharges': cleaningCharges,
      'noticePeriod': noticePeriod,
      'operatingSince': operatingSince,
      'buildingPhotoUrls': buildingPhotoUrls,
      'rentInfo': rentInfo,
      'vacantRooms': vacantRooms,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  MessModel copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    String? messType,
    Object? posterUrl = _sentinel,
    List<String>? galleryUrls,
    Map<String, dynamic>? amenities,
    Object? location = _sentinel,
    Object? locationUrl = _sentinel,
    bool? hidden,
    bool? isUserSourced,
    bool? isSponsored,
    Object? sponsorRank = _sentinel,
    Object? lastUpdatedDate = _sentinel,
    Object? foodFacility = _sentinel,
    Object? security = _sentinel,
    Object? extraAppliances = _sentinel,
    Object? advanceDeposit = _sentinel,
    String? district,
    String? city,
    Object? contact = _sentinel,
    Object? hideContact = _sentinel,
    String? rentCycle,
    Object? adminId = _sentinel,
    Object? locality = _sentinel,
    Object? managedBy = _sentinel,
    Object? advancePayment = _sentinel,
    Object? maintenanceCharge = _sentinel,
    Object? includedInRent = _sentinel,
    Object? facilities = _sentinel,
    Object? foodAvailability = _sentinel,
    Object? mealsPerDay = _sentinel,
    Object? foodType = _sentinel,
    Object? foodBill = _sentinel,
    Object? utensilsCharges = _sentinel,
    Object? waterFacility = _sentinel,
    Object? laundryFacility = _sentinel,
    Object? cleaningService = _sentinel,
    Object? cctv = _sentinel,
    Object? wardenWatchman = _sentinel,
    Object? extraSpace = _sentinel,
    Object? securityDeposit = _sentinel,
    Object? electricityBill = _sentinel,
    Object? electricityBillAmount = _sentinel,
    Object? maintenanceFee = _sentinel,
    Object? maintenanceFeeAmount = _sentinel,
    Object? cleaningCharges = _sentinel,
    Object? noticePeriod = _sentinel,
    Object? operatingSince = _sentinel,
    Object? buildingPhotoUrls = _sentinel,
    Object? rentInfo = _sentinel,
    Object? vacantRooms = _sentinel,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? distance = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    int? matchingBeds,
    bool? isFiltered,
    int? totalImages,
    int? searchScore,
  }) {
    return MessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      messType: messType ?? this.messType,
      posterUrl: posterUrl == _sentinel ? this.posterUrl : posterUrl as String?,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      amenities: amenities ?? this.amenities,
      location: location == _sentinel ? this.location : location as GeoPoint?,
      locationUrl: locationUrl == _sentinel ? this.locationUrl : locationUrl as String?,
      hidden: hidden ?? this.hidden,
      isUserSourced: isUserSourced ?? this.isUserSourced,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorRank: sponsorRank == _sentinel ? this.sponsorRank : sponsorRank as int?,
      lastUpdatedDate: lastUpdatedDate == _sentinel ? this.lastUpdatedDate : lastUpdatedDate as DateTime?,
      foodFacility: foodFacility == _sentinel ? this.foodFacility : foodFacility as String?,
      security: security == _sentinel ? this.security : security as String?,
      extraAppliances: extraAppliances == _sentinel ? this.extraAppliances : extraAppliances as String?,
      advanceDeposit: advanceDeposit == _sentinel ? this.advanceDeposit : advanceDeposit as String?,
      district: district ?? this.district,
      city: city ?? this.city,
      contact: contact == _sentinel ? this.contact : contact as String,
      hideContact: hideContact == _sentinel ? this.hideContact : hideContact as bool,
      rentCycle: rentCycle ?? this.rentCycle,
      adminId: adminId == _sentinel ? this.adminId : adminId as String?,
      locality: locality == _sentinel ? this.locality : locality as String?,
      managedBy: managedBy == _sentinel ? this.managedBy : managedBy as String?,
      advancePayment: advancePayment == _sentinel ? this.advancePayment : advancePayment as Map<String, dynamic>?,
      maintenanceCharge: maintenanceCharge == _sentinel ? this.maintenanceCharge : maintenanceCharge as Map<String, dynamic>?,
      includedInRent: includedInRent == _sentinel ? this.includedInRent : includedInRent as List<String>?,
      facilities: facilities == _sentinel ? this.facilities : facilities as List<String>?,
      foodAvailability: foodAvailability == _sentinel ? this.foodAvailability : foodAvailability as String?,
      mealsPerDay: mealsPerDay == _sentinel ? this.mealsPerDay : mealsPerDay as String?,
      foodType: foodType == _sentinel ? this.foodType : foodType as String?,
      foodBill: foodBill == _sentinel ? this.foodBill : foodBill as String?,
      utensilsCharges: utensilsCharges == _sentinel ? this.utensilsCharges : utensilsCharges as String?,
      waterFacility: waterFacility == _sentinel ? this.waterFacility : waterFacility as String?,
      laundryFacility: laundryFacility == _sentinel ? this.laundryFacility : laundryFacility as String?,
      cleaningService: cleaningService == _sentinel ? this.cleaningService : cleaningService as String?,
      cctv: cctv == _sentinel ? this.cctv : cctv as bool?,
      wardenWatchman: wardenWatchman == _sentinel ? this.wardenWatchman : wardenWatchman as bool?,
      extraSpace: extraSpace == _sentinel ? this.extraSpace : extraSpace as List<String>?,
      securityDeposit: securityDeposit == _sentinel ? this.securityDeposit : securityDeposit as String?,
      electricityBill: electricityBill == _sentinel ? this.electricityBill : electricityBill as String?,
      electricityBillAmount: electricityBillAmount == _sentinel ? this.electricityBillAmount : electricityBillAmount as String?,
      maintenanceFee: maintenanceFee == _sentinel ? this.maintenanceFee : maintenanceFee as String?,
      maintenanceFeeAmount: maintenanceFeeAmount == _sentinel ? this.maintenanceFeeAmount : maintenanceFeeAmount as String?,
      cleaningCharges: cleaningCharges == _sentinel ? this.cleaningCharges : cleaningCharges as String?,
      noticePeriod: noticePeriod == _sentinel ? this.noticePeriod : noticePeriod as String?,
      operatingSince: operatingSince == _sentinel ? this.operatingSince : operatingSince as String?,
      buildingPhotoUrls: buildingPhotoUrls == _sentinel ? this.buildingPhotoUrls : buildingPhotoUrls as List<String>?,
      rentInfo: rentInfo == _sentinel ? this.rentInfo : rentInfo as Map<String, dynamic>?,
      vacantRooms: vacantRooms == _sentinel ? this.vacantRooms : vacantRooms as List<String>?,
      latitude: latitude == _sentinel ? this.latitude : latitude as double?,
      longitude: longitude == _sentinel ? this.longitude : longitude as double?,
      distance: distance == _sentinel ? this.distance : distance as double?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as int?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
      matchingBeds: matchingBeds ?? this.matchingBeds,
      isFiltered: isFiltered ?? this.isFiltered,
      totalImages: totalImages ?? this.totalImages,
      searchScore: searchScore ?? this.searchScore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
