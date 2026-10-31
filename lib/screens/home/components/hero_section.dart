import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final bool carouselEnabled;
  final int messCount;
  final VoidCallback? onGpsPressed;
  final bool loadingLocation;
  final bool hasLocation;
  final String? locationAddress;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onLocationReset;

  const HeroSection({
    super.key,
    this.carouselEnabled = false,
    this.messCount = 0,
    this.onGpsPressed,
    this.loadingLocation = false,
    this.hasLocation = false,
    this.locationAddress,
    this.onLocationPressed,
    this.onLocationReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Action Cards matching screenshot exactly
        _buildQuickActions(context),
        const SizedBox(height: 8),
        // Carousel or Spotlight section
        if (carouselEnabled) 
          _buildCarousel(context) 
        else 
          _buildSpotlight(context),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Mess Explorer Card
          Expanded(
            child: _buildQuickCard(
              context: context,
              icon: Icons.location_on_rounded,
              title: 'Mess Explorer',
              subtitle: 'View interactive map',
              onTap: () {
                context.push('/explorer');
              },
            ),
          ),
          const SizedBox(width: 12),
          // Register Your Mess Card
          Expanded(
            child: _buildQuickCard(
              context: context,
              icon: Icons.home_rounded,
              title: 'Register Your Mess',
              subtitle: 'Free registration closing soon!',
              blobColor: const Color(0xFF10B981), // Green blob
              onTap: () {
                try {
                  context.push('/register-mess');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Mess Registration...')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color blobColor = const Color(0xFF3B82F6), // Blue-ish default
  }) {
    return AnimatedQuickCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      blobColor: blobColor,
    );
  }

  Widget _buildSpotlight(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, const Color(0xFF4A1580)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant RichText header with vibrant neon green "Stay"
          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
              children: [
                TextSpan(text: 'Find Your Comfortable '),
                TextSpan(
                  text: 'Stay',
                  style: TextStyle(color: Color(0xFF22C55E)), // Vibrant green as in screenshot
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mess Dhundo, Ghar Baithe',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Row of Buttons: changes based on GPS state
          if (hasLocation)
            // GPS acquired: show single "Your Location" pill
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLocationReset,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF22C55E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Location',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              if (locationAddress != null)
                                Text(
                                  locationAddress!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'Outfit',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onLocationReset,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use GPS Button
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: loadingLocation ? null : onGpsPressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (loadingLocation)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.location_on, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              loadingLocation ? 'Locating...' : 'Use GPS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Map Button
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF321A5F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Map View is coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          
          // Metadata Footer Section: 80+ Messes Listed | Free Bookings
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    messCount >= 10 
                      ? '${((messCount ~/ 10) * 10)}+ Messes Listed'
                      : '$messCount Messes Listed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '|',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✨', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    'Free Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'Carousel Ads (Coming Soon)',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class AnimatedQuickCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color blobColor;

  const AnimatedQuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.blobColor,
  });

  @override
  State<AnimatedQuickCard> createState() => _AnimatedQuickCardState();
}

class _AnimatedQuickCardState extends State<AnimatedQuickCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            height: 125,
            transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered 
                    ? AppTheme.primary.withValues(alpha: 0.2) 
                    : const Color(0xFFF3F4F6),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon in gradient container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppTheme.primary, const Color(0xFF4A1580)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              transform: Matrix4.translationValues(0, 0, 0)
                                ..scaleByDouble(_isHovered ? 1.05 : 1.0, _isHovered ? 1.05 : 1.0, 1.0, 1.0),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            // Circular arrow button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isHovered 
                                    ? AppTheme.primary.withValues(alpha: 0.05) 
                                    : const Color(0xFFF9FAFB),
                                border: Border.all(
                                  color: _isHovered 
                                      ? AppTheme.primary.withValues(alpha: 0.2) 
                                      : const Color(0xFFF3F4F6),
                                ),
                              ),
                              transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.primary,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _isHovered ? AppTheme.primary : const Color(0xFF1F2937),
                                fontFamily: 'Outfit',
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Outfit',
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
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
}