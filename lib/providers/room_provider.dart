import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/room_model.dart';
import '../data/repositories/room_repository.dart';
import 'mess_provider.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return RoomRepository(firestore: firestore);
});

// A family stream provider to get all rooms for a specific mess
final messRoomsProvider = StreamProvider.family<List<RoomModel>, String>((ref, messId) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.watchRoomsForMess(messId);
});

// A family stream provider to get a single room by its ID
final roomDetailsProvider = StreamProvider.family<RoomModel?, String>((ref, roomId) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.watchRoomById(roomId);
});
