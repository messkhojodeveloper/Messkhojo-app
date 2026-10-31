/// Model for `hero_ads_home` / `hero_ads_city` Firestore collections.
/// Displayed as a rotating banner carousel on the Home screen when enabled.
class HeroAdModel {
  final String id;
  final String? imageUrl;        // Generic / fallback image
  final String? desktopUrl;      // Desktop-optimised image
  final String? mobileUrl;       // Mobile-optimised image
  final String? linkUrl;         // CTA URL when tapped
  final bool active;             // Whether this ad is shown
  final int order;               // Display order (ascending)
  final String section;          // 'home' | 'city'
  final String? title;           // Optional overlay title
  final String? subtitle;        // Optional overlay subtitle

  HeroAdModel({
    required this.id,
    this.imageUrl,
    this.desktopUrl,
    this.mobileUrl,
    this.linkUrl,
    this.active = true,
    this.order = 0,
    this.section = 'home',
    this.title,
    this.subtitle,
  });

  /// Returns the best image URL to show (prefers mobileUrl, falls back to imageUrl)
  String? get displayUrl => mobileUrl ?? imageUrl ?? desktopUrl;

  factory HeroAdModel.fromMap(Map<String, dynamic> map, String id) {
    return HeroAdModel(
      id: id,
      imageUrl: map['imageUrl']?.toString(),
      desktopUrl: map['desktopUrl']?.toString(),
      mobileUrl: map['mobileUrl']?.toString(),
      linkUrl: map['linkUrl']?.toString(),
      active: map['active'] is bool ? map['active'] as bool : true,
      order: map['order'] is int
          ? map['order'] as int
          : int.tryParse(map['order']?.toString() ?? '') ?? 0,
      section: map['section']?.toString() ?? 'home',
      title: map['title']?.toString(),
      subtitle: map['subtitle']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'desktopUrl': desktopUrl,
      'mobileUrl': mobileUrl,
      'linkUrl': linkUrl,
      'active': active,
      'order': order,
      'section': section,
      'title': title,
      'subtitle': subtitle,
    };
  }
}
