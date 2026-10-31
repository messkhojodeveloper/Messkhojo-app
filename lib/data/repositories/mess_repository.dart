import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/mess_model.dart';

class MessRepository {
  final FirebaseFirestore _firestore;

  MessRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream all messes for real-time updates (useful for availability changes)
  Stream<List<MessModel>> watchAllMesses() {
    return _firestore
        .collection(AppConstants.messesCollection)
        .where('hidden', isEqualTo: false) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Fetch messes once (better for performance if real-time is not strictly needed)
  Future<List<MessModel>> getAllMesses() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messesCollection)
          .where('hidden', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) => MessModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messes: $e');
    }
  }

  // Fetch a specific mess by ID
  Future<MessModel?> getMessById(String id) async {
    try {
      final doc = await _firestore.collection(AppConstants.messesCollection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return MessModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch mess details: $e');
    }
  }

  // Stream a specific mess by ID (for real-time updates)
  Stream<MessModel?> watchMessById(String id) {
    return _firestore
        .collection(AppConstants.messesCollection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return MessModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Fetch featured / sponsored messes
  Future<List<MessModel>> getFeaturedMesses() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messesCollection)
          .where('hidden', isEqualTo: false)
          .where('isSponsored', isEqualTo: true)
          .orderBy('sponsorRank', descending: false)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => MessModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      // Fallback if index is building or no sponsored messes exist
      try {
        final snapshot = await _firestore
            .collection(AppConstants.messesCollection)
            .where('hidden', isEqualTo: false)
            .limit(5)
            .get();
        return snapshot.docs.map((doc) => MessModel.fromMap(doc.data(), doc.id)).toList();
      } catch (inner) {
        throw Exception('Failed to fetch featured messes: $inner');
      }
    }
  }

  // Watch mess owned by a specific host (adminId)
  Stream<MessModel?> watchMessByAdmin(String adminId) {
    return _firestore
        .collection(AppConstants.messesCollection)
        .where('adminId', isEqualTo: adminId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return MessModel.fromMap(doc.data(), doc.id);
      }
      return null;
    });
  }

  // Admin and host write methods
  Future<DocumentReference> addMess(Map<String, dynamic> data) async {
    return await _firestore.collection(AppConstants.messesCollection).add(data);
  }

  Future<void> updateMess(String id, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.messesCollection).doc(id).update(data);
  }

  Future<void> deleteMess(String id) async {
    await _firestore.collection(AppConstants.messesCollection).doc(id).delete();
  }
}
