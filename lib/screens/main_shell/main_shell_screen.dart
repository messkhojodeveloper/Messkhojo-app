import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/contextual_search_sheet.dart';

/// Shell screen providing a persistent bottom navigation bar
/// with an elevated center Search button and tabs for Home and Profile.
class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _calculateIndexFromRoute(String path) {
    if (path == '/home' || path == '/') {
      return 0;
    }
    if (path == '/profile') {
      return 2;
    }
    // Sub-routes and detail pages (/city/..., /mess/..., /room/..., /explorer, etc.)
    // do not highlight any top-level tab.
    return -1;
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      HapticFeedback.selectionClick();
      // Pop any pushed screens (e.g. CityScreen, MessDetailsScreen) back to root
      while (context.canPop()) {
        context.pop();
      }
      context.go('/home');
      return;
    }

    if (index == 2) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      if (!isLoggedIn) {
        context.push('/login');
        return;
      }
      HapticFeedback.selectionClick();
      while (context.canPop()) {
        context.pop();
      }
      context.go('/profile');
      return;
    }
  }

  void _onSearchTapped() {
    HapticFeedback.selectionClick();
    final state = GoRouterState.of(context);
    final location = state.matchedLocation;

    if (location.startsWith('/city/')) {
      final districtId = state.pathParameters['districtId'] ?? '';
      final cityId = state.pathParameters['cityId'] ?? '';
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CitySearchSheet(
          districtId: districtId,
          cityId: cityId,
        ),
      );
    } else {
      // Home page or any other page
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const HomeSearchSheet(),
      );
    }
  }

  bool _shouldShowBottomBar(String path) {
    if (path.startsWith('/admin') ||
        path.startsWith('/register-mess') ||
        path.startsWith('/partner-login') ||
        path.startsWith('/find-your-room/results')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _calculateIndexFromRoute(location);
    final showBottomBar = _shouldShowBottomBar(location);

    return PopScope(
      canPop: location == '/home' || location == '/',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: widget.child,
        extendBody: false,
        bottomNavigationBar: showBottomBar
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Nav Bar Background & Outer Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    border: const Border(
                      top: BorderSide(
                        color: Color(0xFFEDEAF4), // AppTheme.lightGray
                        width: 0.8,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        // Tab 0: Home
                        Expanded(
                          child: _NavBarItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Home',
                            isSelected: currentIndex == 0,
                            onTap: () => _onTabTapped(0),
                          ),
                        ),

                        // Center Spacer reserved for Elevated Search Button
                        const SizedBox(width: 80),

                        // Tab 2: Profile
                        Expanded(
                          child: _NavBarItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                            isSelected: currentIndex == 2,
                            onTap: () => _onTabTapped(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Elevated Center Search Action Button
                Positioned(
                  top: -15,
                  child: _ElevatedSearchButton(
                    onTap: _onSearchTapped,
                  ),
                ),
              ],
            )
          : null,
      ),
    );
  }
}

/// Elevated floating circular button for the Search action.
class _ElevatedSearchButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ElevatedSearchButton({required this.onTap});

  @override
  State<_ElevatedSearchButton> createState() => _ElevatedSearchButtonState();
}

class _ElevatedSearchButtonState extends State<_ElevatedSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Search',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual navigation bar item with scale and indicator animations.
class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppTheme.primary : AppTheme.textGray;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 3,
            width: widget.isSelected ? 20 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon with bounce animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.isSelected ? widget.activeIcon : widget.icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          // Label
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
