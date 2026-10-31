import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/districts_config.dart';
import '../../data/models/room_model.dart';
import '../../providers/home_providers.dart';
import '../../widgets/room_card.dart';
import '../home/components/filter_bar.dart';
import '../home/components/shimmer_loading.dart';
import 'components/horizontal_mess_card.dart';
import '../../core/services/analytics_tracker.dart';

class CityScreen extends ConsumerStatefulWidget {
  final String districtId;
  final String cityId;

  const CityScreen({super.key, required this.districtId, required this.cityId});

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends ConsumerState<CityScreen> {
  final ScrollController _seaterScrollController = ScrollController();
  bool _loadingLocation = false;
  String _selectedOccupancy = ''; // '' for All, '1', '2', '3', '4' etc.
  int _displayCount = 10;

  @override
  void initState() {
    super.initState();
    AnalyticsTracker.instance.trackLocationUsage('city_page', district: widget.districtId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(citySearchQueryProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _seaterScrollController.dispose();
    super.dispose();
  }

  int _getActiveFilterCount(FilterState filters, UserLocation? location) {
    int count = 0;
    if (filters.availableOnly) count++;
    count += filters.amenities.values.where((v) => v).length;
    if (filters.messType.isNotEmpty) count++;
    if (location != null) count++;
    return count;
  }

  void _showFilterSheet(FilterState filters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filters: filters,
        onApply: (newFilters) {
          ref.read(homeFiltersProvider.notifier).updateFilters(newFilters);
          setState(() {
            _displayCount = 10;
          });
        },
      ),
    );
  }

  Future<void> _handleGps() async {
    setState(() {
      _loadingLocation = true;
    });
    final result = await ref.read(userLocationProvider.notifier).getCurrentLocation();
    if (mounted) {
      setState(() {
        _loadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final districtName = DistrictsConfig.all[widget.districtId]?.name ?? '';
    final cityName = DistrictsConfig.getCityDisplayName(widget.cityId);

    // Watch providers
    final messesAsync = ref.watch(messesStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);
    final roomsByMess = ref.watch(roomsByMessProvider);
    final filters = ref.watch(homeFiltersProvider);
    final userLocation = ref.watch(userLocationProvider);

    final loading = messesAsync.isLoading || roomsAsync.isLoading;
    final messes = messesAsync.value ?? [];
    final rooms = roomsAsync.value ?? [];

    // 1. Filter messes to this city
    final cityMesses = messes.where((m) {
      if (m.hidden) return false;
      return m.city.trim().toLowerCase() == widget.cityId.toLowerCase();
    }).toList();


    // 3. Search query from bottom bar contextual search
    final citySearchQuery = ref.watch(citySearchQueryProvider);
    final q = citySearchQuery.trim().toLowerCase();

    // 4. Search matcher: Mess Name, Locality/Landmark, Address, and Description
    var filteredMesses = cityMesses.where((mess) {
      if (q.isEmpty) return true;

      // 4.1 Mess Name, Address, & Locality
      if (mess.name.toLowerCase().contains(q) ||
          mess.address.toLowerCase().contains(q) ||
          (mess.locality != null && mess.locality!.toLowerCase().contains(q))) {
        return true;
      }

      // 4.2 Mess Description
      if (mess.description.toLowerCase().contains(q)) {
        return true;
      }

      return false;
    }).toList();

    // 3. Apply Gender toggle filter
    if (filters.messType.isNotEmpty) {
      filteredMesses = filteredMesses.where((mess) {
        return mess.messType.toLowerCase() == filters.messType.toLowerCase();
      }).toList();
    }

    // 4. Apply Room/Mess price and amenity criteria using O(1) roomsByMess map
    filteredMesses = filteredMesses.where((mess) {
      final messRooms = roomsByMess[mess.id] ?? const <RoomModel>[];

      // Pricing filter
      final prices = messRooms.map((r) => r.price).where((p) => p > 0).toList();
      final minP = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : null;
      final maxP = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : null;

      if (filters.minPrice != null && minP != null && minP < filters.minPrice!) return false;
      if (filters.maxPrice != null && maxP != null && maxP > filters.maxPrice!) return false;

      // Amenities filter
      bool checkAmenity(String key) {
        if (mess.amenities[key] == true) return true;
        return messRooms.any((r) => r.amenities[key] == true);
      }

      if (filters.amenities['wifi'] == true && !checkAmenity('wifi')) return false;
      if (filters.amenities['ac'] == true && !checkAmenity('ac')) return false;
      if (filters.amenities['food'] == true && !checkAmenity('food')) return false;
      if (filters.amenities['inverter'] == true && !checkAmenity('inverter')) return false;

      return true;
    }).toList();

    // 5. Gather Rooms if Occupancy filter is active
    final filteredRooms = <RoomModel>[];
    if (_selectedOccupancy.isNotEmpty) {
      final cityMessIds = filteredMesses.map((m) => m.id).toSet();
      final messMap = {for (final m in messes) m.id: m};
      for (final room in rooms) {
        if (!cityMessIds.contains(room.messId)) continue;

        // Check occupancy matching (e.g. '1 Seater' contains '1')
        final cleanOcc = room.occupancy.toLowerCase();
        if (!cleanOcc.contains(_selectedOccupancy)) continue;

        // Apply price filters
        if (filters.minPrice != null && room.price < filters.minPrice!) continue;
        if (filters.maxPrice != null && room.price > filters.maxPrice!) continue;

        // Apply amenities filter
        bool checkRoomAmenity(String key) {
          if (room.amenities[key] == true) return true;
          final parentMess = messMap[room.messId];
          return parentMess?.amenities[key] == true;
        }

        if (filters.amenities['wifi'] == true && !checkRoomAmenity('wifi')) continue;
        if (filters.amenities['ac'] == true && !checkRoomAmenity('ac')) continue;
        if (filters.amenities['food'] == true && !checkRoomAmenity('food')) continue;
        if (filters.amenities['inverter'] == true && !checkRoomAmenity('inverter')) continue;

        filteredRooms.add(room);
      }
    }

    final int totalCount = _selectedOccupancy.isNotEmpty ? filteredRooms.length : filteredMesses.length;
    final int activeFiltersCount = _getActiveFilterCount(filters, userLocation);

    final displayItemsCount = totalCount > _displayCount ? _displayCount : totalCount;
    final hasMore = totalCount > _displayCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(messesStreamProvider);
            ref.invalidate(roomsStreamProvider);
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // 1. Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      // Circular rounded back button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4B5563), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title & Subtitle details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messes in $cityName ($districtName City)',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Outfit',
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Showing $totalCount verified listings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Outfit',
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // GPS Location Button
                      GestureDetector(
                        onTap: _handleGps,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _loadingLocation
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Button with Badge
                      GestureDetector(
                        onTap: () => _showFilterSheet(filters),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune_rounded, color: Colors.white, size: 19),
                              if (activeFiltersCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$activeFiltersCount',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Active Search Filter Chip (if search is active from bottom bar)
              if (citySearchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_rounded, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Search: "$citySearchQuery" ($totalCount listings)',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  ref.read(citySearchQueryProvider.notifier).clear();
                                  setState(() => _displayCount = 10);
                                },
                                child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref.read(citySearchQueryProvider.notifier).clear();
                            setState(() => _displayCount = 10);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Clear', style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textGray)),
                        ),
                      ],
                    ),
                  ),
                ),


              // 3. Quick Action Card (Mess Explorer)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GestureDetector(
                    onTap: () => context.push('/explorer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mess Explorer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View Interactive Map',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Category Switcher (ALL, BOYS, GIRLS)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['', 'boys', 'girls'].map((type) {
                          final label = type.isEmpty ? 'ALL' : type.toUpperCase();
                          final isActive = filters.messType.toLowerCase() == type.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              ref.read(homeFiltersProvider.notifier).updateFilters(
                                    filters.copyWith(messType: type),
                                  );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Outfit',
                                  color: isActive ? Colors.white : const Color(0xFF6B7280),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Occupancy Selector (All Rooms, 1 Seater, 2 Seater, etc.)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      controller: _seaterScrollController,
                      scrollDirection: Axis.horizontal,
                      children: [
                        { 'id': '', 'label': 'All Rooms' },
                        { 'id': '1', 'label': '1 Seater' },
                        { 'id': '2', 'label': '2 Seater' },
                        { 'id': '3', 'label': '3 Seater' },
                        { 'id': '4', 'label': '4 Seater' },
                        { 'id': '5', 'label': '5 Seater' },
                        { 'id': '6', 'label': '6 Seater' },
                        { 'id': '7', 'label': '7 Seater' },
                      ].map((opt) {
                        final id = opt['id']!;
                        final label = opt['label']!;
                        final isActive = _selectedOccupancy == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedOccupancy = id;
                                _displayCount = 10;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primary : Colors.white,
                                border: Border.all(
                                  color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Outfit',
                                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 6. Messes or Rooms list
              if (loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ShimmerGrid(count: 4),
                  ),
                )
              else if (totalCount == 0)
                SliverToBoxAdapter(child: _buildEmptyState(cityName))
              else if (_selectedOccupancy.isNotEmpty)
                // Render Rooms list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 280,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = filteredRooms[index];
                        return RoomCard(
                          room: room,
                        );
                      },
                      childCount: displayItemsCount,
                    ),
                  ),
                )
              else
                // Render Messes list using HorizontalMessCard
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final mess = filteredMesses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HorizontalMessCard(mess: mess),
                        );
                      },
                      childCount: displayItemsCount,
                    ),
                  ),
                ),

              // 7. Load more
              if (hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: GestureDetector(
                      onTap: () => setState(() => _displayCount += 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'View More',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String cityName) {
    final filters = ref.watch(homeFiltersProvider);
    final citySearchQuery = ref.watch(citySearchQueryProvider);
    final hasActive = filters.hasFilters || _selectedOccupancy.isNotEmpty || citySearchQuery.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            citySearchQuery.isNotEmpty ? 'No Matches Found' : 'No Listings Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            citySearchQuery.isNotEmpty
                ? 'No messes or rooms match "$citySearchQuery" in $cityName. Try checking for typos or searching a different area.'
                : hasActive
                    ? 'No properties match your current filters in $cityName. Try clearing your filters.'
                    : 'No mess listings are currently registered in $cityName. Check nearby locations or explore other cities.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontFamily: 'Outfit', color: Color(0xFF6B7280), height: 1.5),
          ),
          if (hasActive) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(citySearchQueryProvider.notifier).clear();
                ref.read(homeFiltersProvider.notifier).reset();
                setState(() {
                  _selectedOccupancy = '';
                  _displayCount = 10;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: Text(citySearchQuery.isNotEmpty ? 'Clear Search & Filters' : 'Clear All Filters'),
            ),
          ],
        ],
      ),
    );
  }
}
