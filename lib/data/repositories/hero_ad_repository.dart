import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hero_ad_model.dart';

/// Repository for hero ads from `hero_ads_home` Firestore collection.
/// The carousel is shown on the Home screen ONLY when `carouselEnabled = true`
/// in the `app_config/hero_ads` Firestore document (controlled by Operational Dashboard).
class HeroAdRepository {
  final FirebaseFirestore _firestore;

  HeroAdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Watches the carouselEnabled flag from app_config.
  /// Returns a stream of bool — true means the carousel should be shown.
  Stream<bool> watchCarouselEnabled() {
    return _firestore
        .collection('app_config')
        .doc('hero_ads')
        .snapshots()
        .map((snap) {
      if (!snap.exists) return false;
      final data = snap.data();
      final val = data?['carouselEnabled'];
      if (val is bool) return val;
      return false;
    });
  }

  /// Watches active hero ads for the home section, ordered by `order` ascending.
  Stream<List<HeroAdModel>> watchActiveHomeAds() {
    return _firestore
        .collection('hero_ads_home')
        .where('active', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HeroAdModel.fromMap(d.data(), d.id)).toList());
  }

  /// One-shot fetch for carouselEnabled flag to eliminate unnecessary Firestore streaming listener
  Future<bool> getCarouselEnabled() async {
    try {
      final snap = await _firestore.collection('app_config').doc('hero_ads').get();
      if (!snap.exists) return false;
      final data = snap.data();
      final val = data?['carouselEnabled'];
      if (val is bool) return val;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// One-shot fetch for active hero ads
  Future<List<HeroAdModel>> getActiveHomeAds() async {
    try {
      final snap = await _firestore
          .collection('hero_ads_home')
          .where('active', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();
      return snap.docs.map((d) => HeroAdModel.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }
}
