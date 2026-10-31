import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mess_model.dart';
import '../../../providers/home_providers.dart';

/// A floating overlay dropdown that shows grouped search suggestions below the search bar.
/// Mirrors the React website's search suggestions in CityLandingPage.jsx.
class SearchSuggestionsDropdown extends ConsumerWidget {
  final void Function(String districtId, String districtName) onDistrictSelected;
  final void Function(String messId) onMessSelected;
  final void Function(String landmark) onLandmarkSelected;
  final void Function(String cityId, String districtId) onCitySelected;

  const SearchSuggestionsDropdown({
    super.key,
    required this.onDistrictSelected,
    required this.onMessSelected,
    required this.onLandmarkSelected,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider);

    if (suggestions.count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 0), // 80 = AppBar + search bar offset
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Districts
                  if (suggestions.districts.isNotEmpty) ...[
                    _SectionLabel(label: 'Districts', color: const Color(0xFF7C3AED), bg: const Color(0xFFF5F3FF)),
                    ...suggestions.districts.map((d) => _SuggestionTile(
                          leading: const _IconBubble(icon: Icons.map_rounded, color: Color(0xFF7C3AED), bg: Color(0xFFF5F3FF)),
                          title: d['name']!,
                          subtitle: 'Filter results by this district',
                          onTap: () => onDistrictSelected(d['id']!, d['name']!),
                        )),
                    const SizedBox(height: 4),
                  ],

                  // 2. Messes
                  if (suggestions.messes.isNotEmpty) ...[
                    _SectionLabel(label: 'Messes', color: AppTheme.primary, bg: const Color(0xFFF3F0FF)),
                    ...suggestions.messes.map((mess) => _MessSuggestionTile(
                          mess: mess,
                          onTap: () => onMessSelected(mess.id),
                        )),
                    const SizedBox(height: 4),
                  ],

                  // 3. Landmarks
                  if (suggestions.landmarks.isNotEmpty) ...[
                    _SectionLabel(label: 'Landmarks & Areas', color: const Color(0xFF16A34A), bg: const Color(0xFFF0FDF4)),
                    ...suggestions.landmarks.map((lm) => _SuggestionTile(
                          leading: const _IconBubble(icon: Icons.location_on_rounded, color: Color(0xFF16A34A), bg: Color(0xFFF0FDF4)),
                          title: lm,
                          subtitle: 'Search in this area',
                          onTap: () => onLandmarkSelected(lm),
                        )),
                    const SizedBox(height: 4),
                  ],

                  // 4. Cities
                  if (suggestions.cities.isNotEmpty) ...[
                    _SectionLabel(label: 'Cities', color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF)),
                    ...suggestions.cities.map((city) => _SuggestionTile(
                          leading: const _IconBubble(icon: Icons.explore_rounded, color: Color(0xFF2563EB), bg: Color(0xFFEFF6FF)),
                          title: city['name']!,
                          subtitle: 'View city page',
                          onTap: () => onCitySelected(city['id']!, city['districtId']!),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _SectionLabel({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _IconBubble({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'Outfit',
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded, size: 14, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

class _MessSuggestionTile extends StatelessWidget {
  final MessModel mess;
  final VoidCallback onTap;

  const _MessSuggestionTile({required this.mess, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🏡', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mess.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          mess.address.isNotEmpty ? mess.address : 'Balasore',
                          style: const TextStyle(fontSize: 10, fontFamily: 'Outfit', color: Color(0xFF9CA3AF)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded, size: 14, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}
