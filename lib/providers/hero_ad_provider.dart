import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/hero_ad_model.dart';
import '../data/repositories/hero_ad_repository.dart';

/// Whether the hero ads carousel is enabled (from app_config/hero_ads doc).
/// Only shows the carousel if this is true — controlled by Operational Dashboard.
final heroAdsCarouselEnabledProvider = FutureProvider<bool>((ref) {
  return HeroAdRepository().getCarouselEnabled();
});

/// Active, ordered hero ads from hero_ads_home collection.
final homeHeroAdsProvider = FutureProvider<List<HeroAdModel>>((ref) async {
  // Only fetch if carousel is enabled
  final enabled = ref.watch(heroAdsCarouselEnabledProvider).asData?.value ?? false;
  if (!enabled) return [];
  return HeroAdRepository().getActiveHomeAds();
});
