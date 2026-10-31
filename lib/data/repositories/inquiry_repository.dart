import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inquiry_model.dart';

/// Repository for `inquiries` and `room_inquiries` Firestore collections.
/// These are written when users tap "Contact Owner" on Mess or Room detail screens.
class InquiryRepository {
  final FirebaseFirestore _firestore;

  InquiryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit a new mess contact-owner inquiry.
  Future<DocumentReference> addInquiry(Map<String, dynamic> data) async {
    return await _firestore.collection('inquiries').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Legacy helper for InquiryBottomSheet
  Future<DocumentReference> submitInquiry({
    required String name,
    required String phone,
    required String seating,
    required bool consent,
    required String messId,
    required String messName,
    String? message,
  }) async {
    return await addInquiry({
      'userName': name,
      'userPhone': phone,
      'seating': seating,
      'consent': consent,
      'messId': messId,
      'messName': messName,
      'message': message,
      'status': 'pending',
    });
  }

  /// Submit a new room contact-owner inquiry.
  Future<DocumentReference> addRoomInquiry(Map<String, dynamic> data) async {
    return await _firestore.collection('room_inquiries').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Watch all inquiries for a specific mess (for owner/admin use).
  Stream<List<InquiryModel>> watchInquiriesForMess(String messId) {
    return _firestore
        .collection('inquiries')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InquiryModel.fromMap(d.data(), d.id)).toList());
  }

  /// Watch all room inquiries for a specific mess (for owner/admin use).
  Stream<List<RoomInquiryModel>> watchRoomInquiriesForMess(String messId) {
    return _firestore
        .collection('room_inquiries')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RoomInquiryModel.fromMap(d.data(), d.id))
            .toList());
  }
}
