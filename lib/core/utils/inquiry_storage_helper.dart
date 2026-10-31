import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InquiryStorageHelper {
  static const String _keyLastInquiry = 'mk_last_inquiry';
  static const String _keyPastInquiries = 'mk_past_inquiries';

  static Map<String, dynamic> _cleanMap(Map<String, dynamic> raw) {
    final Map<String, dynamic> cleaned = {};
    raw.forEach((key, value) {
      if (value is String || value is num || value is bool || value == null) {
        cleaned[key] = value;
      } else if (value is List) {
        cleaned[key] = value.map((e) => e is String || e is num || e is bool ? e : e.toString()).toList();
      } else if (value is Map) {
        cleaned[key] = _cleanMap(Map<String, dynamic>.from(value));
      } else {
        // Drop non-json encodable objects like FieldValue sentinels or convert to String
        cleaned[key] = value.toString();
      }
    });
    return cleaned;
  }

  /// Save a new inquiry to local storage
  static Future<void> saveInquiry(Map<String, dynamic> inquiryData) async {
    final prefs = await SharedPreferences.getInstance();
    final nowIso = DateTime.now().toIso8601String();

    final cleanInquiry = _cleanMap(inquiryData);

    final entry = {
      'submittedAt': nowIso,
      'inquiry': cleanInquiry,
    };

    // Save as last inquiry
    await prefs.setString(_keyLastInquiry, jsonEncode(entry));

    // Append to past inquiries (max 15 items)
    final pastList = await getPastInquiries();
    pastList.insert(0, entry);
    if (pastList.length > 15) {
      pastList.removeRange(15, pastList.length);
    }

    await prefs.setString(_keyPastInquiries, jsonEncode(pastList));
  }

  /// Check if an inquiry was already submitted today
  static Future<bool> hasSubmittedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLast = prefs.getString(_keyLastInquiry);
    if (rawLast == null || rawLast.isEmpty) return false;

    try {
      final Map<String, dynamic> parsed = jsonDecode(rawLast);
      final submittedAtStr = parsed['submittedAt'] as String?;
      if (submittedAtStr != null) {
        final submittedDate = DateTime.parse(submittedAtStr).toLocal();
        final now = DateTime.now();

        return submittedDate.year == now.year &&
            submittedDate.month == now.month &&
            submittedDate.day == now.day;
      }
    } catch (_) {}

    return false;
  }

  /// Get list of past inquiries
  static Future<List<Map<String, dynamic>>> getPastInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPast = prefs.getString(_keyPastInquiries);
    if (rawPast == null || rawPast.isEmpty) return [];

    try {
      final List<dynamic> parsed = jsonDecode(rawPast);
      return parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}

    return [];
  }

  /// Delete a single past inquiry item
  static Future<void> deleteInquiryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final pastList = await getPastInquiries();

    if (index >= 0 && index < pastList.length) {
      pastList.removeAt(index);
      await prefs.setString(_keyPastInquiries, jsonEncode(pastList));

      if (pastList.isEmpty) {
        await prefs.remove(_keyLastInquiry);
      } else {
        await prefs.setString(_keyLastInquiry, jsonEncode(pastList.first));
      }
    }
  }

  /// Clear all past inquiries
  static Future<void> clearAllInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastInquiry);
    await prefs.remove(_keyPastInquiries);
  }
}
