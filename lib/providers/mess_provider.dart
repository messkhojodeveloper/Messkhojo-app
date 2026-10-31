import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/mess_model.dart';
import '../data/repositories/mess_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final messRepositoryProvider = Provider<MessRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return MessRepository(firestore: firestore);
});

// A stream provider to get all messes in real-time
final allMessesProvider = StreamProvider<List<MessModel>>((ref) {
  final repository = ref.watch(messRepositoryProvider);
  return repository.watchAllMesses();
});

// A future provider for featured messes
final featuredMessesProvider = FutureProvider<List<MessModel>>((ref) async {
  final repository = ref.watch(messRepositoryProvider);
  return await repository.getFeaturedMesses();
});

// A family provider to fetch a single mess by its ID in real-time
final messDetailsProvider = StreamProvider.family<MessModel?, String>((ref, id) {
  final repository = ref.watch(messRepositoryProvider);
  return repository.watchMessById(id);
});

// A stream provider for a host's mess profile
final hostMessProfileProvider = StreamProvider.family<MessModel?, String>((ref, adminId) {
  final repository = ref.watch(messRepositoryProvider);
  return repository.watchMessByAdmin(adminId);
});
