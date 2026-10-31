import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream bookings for a specific mess, sorted by createdAt descending
  Stream<List<BookingModel>> watchBookingsForMess(String messId) {
    return _firestore
        .collection('bookings')
        .where('messId', isEqualTo: messId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Client-side sort to ensure descending order if index is building or not yet created
      bookings.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return bookings;
    });
  }

  // Stream bookings for a specific user, sorted by createdAt descending
  Stream<List<BookingModel>> watchBookingsForUser(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      // Client-side sort to ensure descending order
      bookings.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return bookings;
    });
  }

  // Update a booking status and add optional remark
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? remark,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status.name,
        'respondedAt': FieldValue.serverTimestamp(),
      };
      if (remark != null) {
        updates['remark'] = remark;
      }
      await _firestore.collection('bookings').doc(bookingId).update(updates);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }
}
