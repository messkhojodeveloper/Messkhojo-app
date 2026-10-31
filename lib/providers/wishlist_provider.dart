import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/models/wishlist_model.dart';
import 'auth_provider.dart';
import 'mess_provider.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return WishlistRepository(firestore: firestore);
});

final userWishlistProvider = StreamProvider<WishlistModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final repository = ref.watch(wishlistRepositoryProvider);
      return repository.watchUserWishlist(user.uid);
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});

final wishlistedMessIdsProvider = Provider<Set<String>>((ref) {
  final wishlist = ref.watch(userWishlistProvider).value;
  return wishlist?.messes.toSet() ?? {};
});

final wishlistedRoomIdsProvider = Provider<Set<String>>((ref) {
  final wishlist = ref.watch(userWishlistProvider).value;
  return wishlist?.rooms.toSet() ?? {};
});
