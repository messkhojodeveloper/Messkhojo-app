import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_tracker.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore;

  WishlistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<WishlistModel?> watchUserWishlist(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return WishlistModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> toggleMessInWishlist(String userId, String messId) async {
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'wishlistedMesses': [messId],
        'wishlistedRooms': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AnalyticsTracker.instance.trackWishlistToggle(messId, isAdded: true);
      return;
    }

    final data = doc.data()!;
    final List<String> messes = List<String>.from(data['wishlistedMesses'] ?? []);
    final bool isAdded = !messes.contains(messId);

    if (messes.contains(messId)) {
      messes.remove(messId);
    } else {
      messes.add(messId);
    }

    await docRef.update({
      'wishlistedMesses': messes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AnalyticsTracker.instance.trackWishlistToggle(messId, isAdded: isAdded);
  }

  Future<void> toggleRoomInWishlist(String userId, String roomId) async {
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'wishlistedMesses': [],
        'wishlistedRooms': [roomId],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = doc.data()!;
    final List<String> rooms = List<String>.from(data['wishlistedRooms'] ?? []);

    if (rooms.contains(roomId)) {
      rooms.remove(roomId);
    } else {
      rooms.add(roomId);
    }

    await docRef.update({
      'wishlistedRooms': rooms,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
