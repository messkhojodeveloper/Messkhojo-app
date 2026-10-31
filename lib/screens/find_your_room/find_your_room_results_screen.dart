import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/suggestion_engine.dart';
import '../../providers/home_providers.dart';
import '../../widgets/firebase_image.dart';

class FindYourRoomResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> inquiry;

  const FindYourRoomResultsScreen({
    super.key,
    required this.inquiry,
  });

  @override
  ConsumerState<FindYourRoomResultsScreen> createState() => _FindYourRoomResultsScreenState();
}

class _FindYourRoomResultsScreenState extends ConsumerState<FindYourRoomResultsScreen> {

  String _formatCityName(String? cityId) {
    if (cityId == null || cityId.isEmpty) return '';
    if (cityId.toLowerCase() == 'baleshwar') return 'Balasore';
    return cityId[0].toUpperCase() + cityId.substring(1);
  }

  String _formatOccupancyLabel(String? occ) {
    if (occ == null || occ.isEmpty) return '';
    final clean = occ.replaceAll('-seater', '');
    if (clean == '4') return '4+ Seater';
    return '$clean-Seater';
  }

  @override
  Widget build(BuildContext context) {
    final messesAsync = ref.watch(messesStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);

    final isLoading = messesAsync.isLoading || roomsAsync.isLoading;
    final messes = messesAsync.value ?? [];
    final rooms = roomsAsync.value ?? [];

    final suggestions = SuggestionEngine.getSuggestions(
      messes: messes,
      rooms: rooms,
      inquiry: widget.inquiry,
    );

    final city = _formatCityName(widget.inquiry['city'] as String?);
    final location = widget.inquiry['location'] as String? ?? '';
    final gender = widget.inquiry['gender'] as String? ?? '';
    final genderLabel = gender.isNotEmpty ? gender[0].toUpperCase() + gender.substring(1) : '';
    final occupancy = widget.inquiry['occupancy'] as String? ?? '';
    final occupancyLabel = _formatOccupancyLabel(occupancy);
    final budget = widget.inquiry['budget'] as String? ?? '';
    final budgetLabel = budget.isNotEmpty ? '₹$budget/mo' : '';

    // Subtitle string: Locality · City · Gender
    final subtitleParts = <String>[];
    if (location.isNotEmpty) subtitleParts.add(location);
    if (city.isNotEmpty) subtitleParts.add(city);
    if (genderLabel.isNotEmpty) subtitleParts.add(genderLabel);
    final subtitleText = subtitleParts.join(' · ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/find-your-room');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Matched Messes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Outfit',
              ),
            ),
            if (subtitleText.isNotEmpty)
              Text(
                subtitleText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Outfit',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Home Button
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            onPressed: () => context.go('/home'),
            tooltip: 'Home',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Filter Chips Row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (location.isNotEmpty) _buildFilterChip(Icons.location_on_outlined, location),
                    if (genderLabel.isNotEmpty) _buildFilterChip(Icons.person_outline_rounded, genderLabel),
                    if (occupancyLabel.isNotEmpty) _buildFilterChip(Icons.group_outlined, occupancyLabel),
                    if (budgetLabel.isNotEmpty) _buildFilterChip(Icons.account_balance_wallet_outlined, budgetLabel),
                    if (city.isNotEmpty && city != location) _buildFilterChip(Icons.location_city_outlined, city),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Results Header
                  if (!isLoading)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          suggestions.isNotEmpty
                              ? '${suggestions.length} Best Matches Found'
                              : 'No Matches Found',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Outfit',
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (suggestions.isNotEmpty)
                          const Text(
                            'Showing up to 6',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Loading State
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    )
                  // Suggestions List
                  else if (suggestions.isEmpty)
                    _buildEmptyState(context)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        return _buildMessCard(context, suggestions[index], index + 1);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFilterChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessCard(BuildContext context, MessSuggestion suggestion, int rank) {
    final mess = suggestion.mess;
    final priceLabel = suggestion.minPrice == suggestion.maxPrice
        ? '₹${suggestion.minPrice.toInt()}/mo'
        : '₹${suggestion.minPrice.toInt()}–₹${suggestion.maxPrice.toInt()}/mo';

    // Extract occupancy clean numbers e.g. "1"
    final occList = suggestion.matchedRooms
        .map((r) => SuggestionEngine.cleanOccupancy(r.occupancy))
        .toSet()
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: (mess.posterUrl != null && mess.posterUrl!.isNotEmpty)
                      ? FirebaseImage(
                          imagePath: mess.posterUrl!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFF3F0FF),
                          child: const Icon(
                            Icons.bed_rounded,
                            size: 52,
                            color: Color(0xFFC4B5FD),
                          ),
                        ),
                ),
              ),

              // Left Pill: Rooms Available
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: suggestion.hasAvailability
                        ? const Color(0xFF10B981) // Emerald Green
                        : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        suggestion.hasAvailability
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion.hasAvailability ? 'Rooms Available' : 'Check Availability',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Badge: Rank Number
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B0764), // Dark purple rank badge
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mess Title
                Text(
                  mess.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit',
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),

                // Location / Address
                if (mess.address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mess.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontFamily: 'Outfit',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),

                // PRICE & ROOM TYPE Info Boxes
                Row(
                  children: [
                    // Price Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'PRICE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'Outfit',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669), // Emerald Green
                                fontFamily: 'Outfit',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Room Type Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ROOM TYPE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'Outfit',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              occList.isNotEmpty ? occList : '1',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                fontFamily: 'Outfit',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full-width Dark Purple Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/mess/${mess.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B0764), // Dark Purple
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Mess Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Request Received!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No instant matches were found in our online database yet, but our ground team is manually finding rooms for you. We will contact you on WhatsApp/Phone shortly!',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Outfit',
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
