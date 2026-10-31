import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/home_providers.dart';
import '../../../core/theme/app_theme.dart';

class FilterBar extends ConsumerStatefulWidget {
  final VoidCallback? onGps;
  final bool loadingLocation;

  const FilterBar({
    super.key,
    this.onGps,
    this.loadingLocation = false,
  });

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(homeFiltersProvider);
    final userLocation = ref.watch(userLocationProvider);

    // Sync controller with state without jumping cursor
    if (_searchController.text != filters.location) {
      _searchController.text = filters.location;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    final bool hasActiveFilters = filters.hasFilters || userLocation != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Outer elevated white card matching screenshot
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search Input with light gray border - exactly matches screenshot
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              ref.read(homeFiltersProvider.notifier).updateFilters(
                                    filters.copyWith(location: value),
                                  );
                              resetDisplayCount(ref);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search by landmark or mess name...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontFamily: 'Outfit',
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                              isDense: true,
                            ),
                          ),
                        ),
                        // GPS icon inside the search bar (when available)
                        if (widget.onGps != null)
                          IconButton(
                            onPressed: widget.loadingLocation ? null : widget.onGps,
                            icon: widget.loadingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : const Icon(Icons.my_location,
                                    color: Color(0xFF94A3B8), size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Purple filter button - matches screenshot
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B51E0), // Vibrant medium purple as in screenshot
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showFilterBottomSheet(context, filters);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          // Active filter indicator dot
                          if (hasActiveFilters)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location chip - shows when GPS is active
          if (userLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          userLocation.address ?? 'Using GPS Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => ref.read(userLocationProvider.notifier).clearLocation(),
                          child: Icon(Icons.close, size: 14, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, FilterState filters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filters: filters,
        onApply: (newFilters) {
          ref.read(homeFiltersProvider.notifier).updateFilters(newFilters);
          resetDisplayCount(ref);
        },
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterState filters;
  final ValueChanged<FilterState> onApply;

  const FilterBottomSheet({
    super.key,
    required this.filters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterState _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_currentFilters.availableOnly) count++;
    count += _currentFilters.amenities.values.where((v) => v).length;
    if (_currentFilters.messType.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, const Color(0xFF4A1580)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _currentFilters = const FilterState()),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Mess Type ──────────────────────────────────────────
                    _buildSectionLabel('Mess Type'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTypeCard('Boys', '👦', const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                        const SizedBox(width: 10),
                        _buildTypeCard('Girls', '👧', const Color(0xFFEC4899), const Color(0xFFFDF2F8)),
                        const SizedBox(width: 10),
                        _buildTypeCard('Both', '👥', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Amenities ──────────────────────────────────────────
                    _buildSectionLabel('Amenities'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: [
                        _buildAmenityToggle('wifi', '📶', 'WiFi'),
                        _buildAmenityToggle('ac', '❄️', 'AC'),
                        _buildAmenityToggle('food', '🍽️', 'Food'),
                        _buildAmenityToggle('inverter', '⚡', 'Power Backup'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Availability ───────────────────────────────────────
                    _buildSectionLabel('Availability'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _currentFilters = _currentFilters.copyWith(availableOnly: !_currentFilters.availableOnly)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _currentFilters.availableOnly ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _currentFilters.availableOnly ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                            width: _currentFilters.availableOnly ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '🏠',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Available Beds Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937))),
                                  Text('Hide full messes', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _currentFilters.availableOnly ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: _currentFilters.availableOnly ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Apply Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onApply(_currentFilters);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, const Color(0xFF4A1580)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _activeFilterCount > 0 ? 'Apply $_activeFilterCount Filter${_activeFilterCount > 1 ? 's' : ''}' : 'Apply Filters',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTypeCard(String type, String emoji, Color activeColor, Color activeBg) {
    final isSelected = _currentFilters.messType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentFilters = _currentFilters.copyWith(messType: isSelected ? '' : type));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityToggle(String key, String emoji, String label) {
    final isActive = _currentFilters.amenities[key] ?? false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          final newAmenities = Map<String, bool>.from(_currentFilters.amenities);
          newAmenities[key] = !isActive;
          _currentFilters = _currentFilters.copyWith(amenities: newAmenities);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.primary : const Color(0xFF6B7280),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF7C3AED)),
            ],
          ],
        ),
      ),
    );
  }
}