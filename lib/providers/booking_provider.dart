import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import 'mess_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BookingRepository(firestore: firestore);
});

// A family stream provider to get all bookings for a specific mess
final messBookingsProvider = StreamProvider.family<List<BookingModel>, String>((ref, messId) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookingsForMess(messId);
});

// A family stream provider to get all bookings for a specific user
final userBookingsProvider = StreamProvider.family<List<BookingModel>, String>((ref, userId) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.watchBookingsForUser(userId);
});

