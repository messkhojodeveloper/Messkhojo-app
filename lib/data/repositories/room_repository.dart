import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../../core/constants/app_constants.dart';

class RoomRepository {
  final FirebaseFirestore _firestore;

  RoomRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<RoomModel>> watchRoomsForMess(String messId) {
    return _firestore
        .collection(AppConstants.roomsCollection)
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RoomModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<RoomModel?> getRoomById(String id) async {
    try {
      final doc = await _firestore.collection(AppConstants.roomsCollection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return RoomModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch room details: $e');
    }
  }

  Stream<RoomModel?> watchRoomById(String id) {
    return _firestore
        .collection(AppConstants.roomsCollection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return RoomModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<DocumentReference> addRoom(Map<String, dynamic> data) async {
    return await _firestore.collection(AppConstants.roomsCollection).add(data);
  }

  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.roomsCollection).doc(id).update(data);
  }

  Future<void> deleteRoom(String id) async {
    await _firestore.collection(AppConstants.roomsCollection).doc(id).delete();
  }
}
