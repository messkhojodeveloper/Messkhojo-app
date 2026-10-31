import '../../data/models/mess_model.dart';
import '../../data/models/room_model.dart';

class MessSuggestion {
  final MessModel mess;
  final List<RoomModel> matchedRooms;
  final bool hasAvailability;
  final double minPrice;
  final double maxPrice;
  final double areaScore;

  MessSuggestion({
    required this.mess,
    required this.matchedRooms,
    required this.hasAvailability,
    required this.minPrice,
    required this.maxPrice,
    required this.areaScore,
  });
}

class SuggestionEngine {
  /// Parse max budget from budget string (e.g. "<2000", "2000-3000", "5000+")
  static double parseMaxBudget(String budgetStr) {
    if (budgetStr.isEmpty) return double.infinity;
    final clean = budgetStr.replaceAll(' ', '').replaceAll('₹', '');

    if (clean.startsWith('<')) {
      return double.tryParse(clean.substring(1)) ?? double.infinity;
    }

    if (clean.endsWith('+')) {
      return double.infinity;
    }

    if (clean.contains('-')) {
      final parts = clean.split('-');
      return double.tryParse(parts.last) ?? double.infinity;
    }

    return double.tryParse(clean) ?? double.infinity;
  }

  /// Check if messType accommodates user preference
  static bool matchesGender(String messType, String prefGender) {
    if (prefGender.isEmpty) return true;
    final pref = prefGender.toLowerCase();
    final mess = messType.toLowerCase();

    if (pref == 'boys') {
      return mess.contains('boys') || mess.contains('both') || mess.contains('coed');
    }
    if (pref == 'girls') {
      return mess.contains('girls') || mess.contains('both') || mess.contains('coed');
    }
    return true;
  }

  /// Clean occupancy string e.g. "1-seater" -> "1"
  static String cleanOccupancy(String occ) {
    final digits = RegExp(r'\d+').firstMatch(occ);
    return digits != null ? digits.group(0)! : occ;
  }

  /// Build occupancy search ladder from preferred occupancy
  static List<String>? getOccupancyLadder(String occupancyPref) {
    if (occupancyPref == 'any' || occupancyPref.isEmpty) return null;
    final clean = cleanOccupancy(occupancyPref);
    final startNum = int.tryParse(clean);
    if (startNum == null) return null;

    final ladder = <String>[];
    for (int n = startNum; n <= 8; n++) {
      ladder.add(n.toString());
    }
    return ladder;
  }

  /// Calculate area match score between mess address and target location
  static double scoreAreaMatch(MessModel mess, String targetLocation) {
    if (targetLocation.trim().isEmpty) return 0.5;
    final target = targetLocation.toLowerCase();
    final address = mess.address.toLowerCase();

    if (address.contains(target) || target.contains(address)) {
      return 1.0;
    }
    return 0.2;
  }

  /// Core suggestion algorithm
  static List<MessSuggestion> getSuggestions({
    required List<MessModel> messes,
    required List<RoomModel> rooms,
    required Map<String, dynamic> inquiry,
  }) {
    final targetCity = (inquiry['city'] as String? ?? '').toLowerCase();
    final targetGender = (inquiry['gender'] as String? ?? '').toLowerCase();
    final targetOccupancy = (inquiry['occupancy'] as String? ?? '').toLowerCase();
    final targetBudget = inquiry['budget'] as String? ?? '';
    final targetLocation = inquiry['location'] as String? ?? '';

    final maxBudget = parseMaxBudget(targetBudget);
    final occLadder = getOccupancyLadder(targetOccupancy);

    final suggestions = <MessSuggestion>[];

    // Pre-index rooms by messId for O(1) lookup
    final roomsByMess = <String, List<RoomModel>>{};
    for (final r in rooms) {
      roomsByMess.putIfAbsent(r.messId, () => []).add(r);
    }

    for (final mess in messes) {
      // 1. City hard filter
      if (targetCity.isNotEmpty && mess.city.toLowerCase() != targetCity) {
        continue;
      }

      // 2. Gender hard filter
      if (!matchesGender(mess.messType, targetGender)) {
        continue;
      }

      // Find rooms for this mess
      final messRooms = roomsByMess[mess.id] ?? const <RoomModel>[];
      if (messRooms.isEmpty) continue;

      // 3. Room filter: occupancy & budget
      List<RoomModel> matchedRooms = [];

      if (occLadder != null && occLadder.isNotEmpty) {
        // Try ladder in order
        for (final occStep in occLadder) {
          final levelRooms = messRooms.where((r) {
            final rOccClean = cleanOccupancy(r.occupancy);
            final occMatches = rOccClean == occStep;
            final price = r.price.toDouble();
            final budgetMatches = price <= maxBudget;
            return occMatches && budgetMatches;
          }).toList();

          if (levelRooms.isNotEmpty) {
            matchedRooms = levelRooms;
            break; // take best matching occupancy tier
          }
        }
      } else {
        // Any occupancy preference
        matchedRooms = messRooms.where((r) {
          final price = r.price.toDouble();
          return price <= maxBudget;
        }).toList();
      }

      // Fallback: if budget filtered out all rooms, relax budget to show options
      if (matchedRooms.isEmpty && messRooms.isNotEmpty) {
        matchedRooms = messRooms;
      }

      if (matchedRooms.isEmpty) continue;

      // Calculate availability and price range
      bool hasAvailability = matchedRooms.any((r) => r.availableCount > 0);
      final prices = matchedRooms.map((r) => r.price.toDouble()).toList();
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final areaScore = scoreAreaMatch(mess, targetLocation);

      suggestions.add(MessSuggestion(
        mess: mess,
        matchedRooms: matchedRooms,
        hasAvailability: hasAvailability,
        minPrice: minPrice,
        maxPrice: maxPrice,
        areaScore: areaScore,
      ));
    }

    // Sort suggestions:
    // 1. Available rooms first
    // 2. Higher area score
    // 3. Lower min price
    suggestions.sort((a, b) {
      if (a.hasAvailability != b.hasAvailability) {
        return a.hasAvailability ? -1 : 1;
      }
      if ((a.areaScore - b.areaScore).abs() > 0.01) {
        return b.areaScore.compareTo(a.areaScore);
      }
      return a.minPrice.compareTo(b.minPrice);
    });

    return suggestions.take(6).toList();
  }
}
