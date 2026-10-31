import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUrlService {
  final FirebaseStorage _storage;
  static final Map<String, String> _staticCache = {};

  ImageUrlService(this._storage);

  /// Synchronous fast-path: returns path if already a direct URL (http/https),
  /// or if it was previously resolved and cached. Returns null if async resolution is required.
  static String? getDirectOrCached(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.toLowerCase().contains('.heic')) return null;

    if (path.startsWith('https://') || path.startsWith('http://')) {
      return path;
    }

    return _staticCache[path];
  }

  Future<String?> resolveUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.toLowerCase().contains('.heic')) return null;

    if (path.startsWith('https://') || path.startsWith('http://')) {
      return path;
    }

    if (_staticCache.containsKey(path)) {
      return _staticCache[path];
    }

    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();
      _staticCache[path] = url;
      return url;
    } catch (e) {
      return null;
    }
  }

  String? getCachedUrl(String path) {
    return _staticCache[path];
  }
}

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final imageUrlServiceProvider = Provider<ImageUrlService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return ImageUrlService(storage);
});

// A FutureProvider family to resolve image URLs asynchronously in the UI
final resolvedImageUrlProvider = FutureProvider.family<String?, String?>((ref, path) async {
  final service = ref.watch(imageUrlServiceProvider);
  return service.resolveUrl(path);
});
