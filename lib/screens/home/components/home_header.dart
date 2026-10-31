import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/home_providers.dart';
import 'filter_bar.dart';

class HomeHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String searchTerm;
  final ValueChanged<String> onSearchChange;
  final VoidCallback onMenuPressed;

  const HomeHeader({
    super.key,
    this.searchTerm = '',
    required this.onSearchChange,
    required this.onMenuPressed,
  });

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(61);
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchTerm);
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTerm != widget.searchTerm && _controller.text != widget.searchTerm) {
      _controller.text = widget.searchTerm;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // A reusable, premium glassmorphic button widget
  Widget _buildGlassButton({
    required Widget icon,
    required VoidCallback onTap,
    bool hasActiveIndicator = false,
    Color indicatorColor = const Color(0xFF22C55E),
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  icon,
                  if (hasActiveIndicator)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF334155); // Slate 700 for high-contrast crisp text/icons

    final filters = ref.watch(homeFiltersProvider);
    final userLocation = ref.watch(userLocationProvider);
    final bool hasActiveFilters = filters.hasFilters || userLocation != null;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      actions: [const SizedBox.shrink()], // Guarantees Flutter does not automatically inject its own end-drawer button
      flexibleSpace: SafeArea(
        child: Container(
          height: 61,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Left Section: Sticky Search Bar styled as light-frosted capsule
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onSearchChange,
                        style: const TextStyle(
                          color: darkSlate,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Outfit',
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          hintText: 'Search landmark or mess...',
                          hintStyle: TextStyle(
                            color: darkSlate.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontFamily: 'Outfit',
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: darkSlate,
                            size: 18,
                          ),
                          suffixIcon: widget.searchTerm.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    widget.onSearchChange('');
                                    _controller.clear();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: darkSlate,
                                    size: 16,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Filter Button
              _buildGlassButton(
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  color: darkSlate,
                  size: 20,
                ),
                hasActiveIndicator: hasActiveFilters,
                onTap: () {
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
                },
              ),

              const SizedBox(width: 8),

              // Notification Bell
              _buildGlassButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: darkSlate,
                  size: 20,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),

              const SizedBox(width: 8),

              // Hamburger Menu (Drawer Toggle)
              _buildGlassButton(
                icon: const Icon(
                  Icons.menu,
                  color: darkSlate,
                  size: 20,
                ),
                onTap: widget.onMenuPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}