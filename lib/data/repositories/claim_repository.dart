import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/claim_model.dart';

/// Repository for `claims` Firestore collection.
/// Written when a user submits "Claim This Listing" for a mess.
class ClaimRepository {
  final FirebaseFirestore _firestore;

  ClaimRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit a new mess ownership claim.
  Future<DocumentReference> addClaim(Map<String, dynamic> data) async {
    return await _firestore.collection('claims').add({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if there's already a pending claim by this user for this mess.
  Future<bool> hasPendingClaim({
    required String messId,
    required String userPhone,
  }) async {
    final snap = await _firestore
        .collection('claims')
        .where('messId', isEqualTo: messId)
        .where('userPhone', isEqualTo: userPhone)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Watch claims for a specific mess (admin use).
  Stream<List<ClaimModel>> watchClaimsForMess(String messId) {
    return _firestore
        .collection('claims')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList());
  }
}
