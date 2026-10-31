import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/inquiry_repository.dart';
import 'mess_provider.dart';

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return InquiryRepository(firestore: firestore);
});
