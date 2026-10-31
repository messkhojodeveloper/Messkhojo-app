import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/home_providers.dart';
import '../../data/models/mess_model.dart';
import '../../data/services/image_url_service.dart';
import '../../core/theme/app_theme.dart';

// Helper function to calculate exact distance in kilometers using the Haversine formula
double _getDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // Earth's radius in km
  final dLat = (lat2 - lat1) * (math.pi / 180);
  final dLon = (lon2 - lon1) * (math.pi / 180);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * (math.pi / 180)) *
          math.cos(lat2 * (math.pi / 180)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

class MessExplorerMapScreen extends ConsumerStatefulWidget {
  const MessExplorerMapScreen({super.key});

  @override
  ConsumerState<MessExplorerMapScreen> createState() =>
      _MessExplorerMapScreenState();
}

class _MessExplorerMapScreenState
    extends ConsumerState<MessExplorerMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  late PageController _pageController;

  // Filter state
  String _activeTypeFilter = 'all'; // 'all', 'Boys', 'Girls'
  Map<String, bool> _amenityFilters = {
    'wifi': false,
    'ac': false,
    'food': false,
  };

  String? _selectedMessId;
  bool _isMapIdle = true;
  bool _showFullMap = false; // Toggle for Full Map view
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchDropdown = false;

  // Custom marker icon cache
  BitmapDescriptor? _unselectedIcon;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _myLocationEnabled = false;

  // Preloads and generates price badges asynchronously
  Future<void> _preloadMarkerIcons(List<MessModel> messes) async {
    if (_unselectedIcon == null) {
      final icon = await _generateUnselectedPin();
      if (mounted) {
        setState(() => _unselectedIcon = icon);
      }
    }

    for (final mess in messes) {
      if (!_markerIconCache.containsKey(mess.id)) {
        String priceText = '₹---';
        if (mess.minPrice != null && mess.maxPrice != null && mess.minPrice != mess.maxPrice) {
          priceText = '₹${mess.minPrice} - ₹${mess.maxPrice}';
        } else if (mess.minPrice != null) {
          priceText = '₹${mess.minPrice}';
        }
        
        final icon = await _generateSelectedBadge(priceText);
        if (mounted) {
          setState(() {
            _markerIconCache[mess.id] = icon;
          });
        }
      }
    }
  }

  // Generates the custom unselected purple pin matching the web MapPin
  Future<BitmapDescriptor> _generateUnselectedPin() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 38.0; // Scaled down to match standard map pin sizes
    
    final Paint purplePaint = Paint()
      ..color = const Color(0xFF7C3AED) // Purple fill matching web #7C3AED
      ..style = PaintingStyle.fill;
      
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5; // Scaled stroke width
      
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size / 2, size * 0.95);
    path.cubicTo(
      size * 0.15, size * 0.65,
      size * 0.1, size * 0.50,
      size * 0.1, size * 0.38,
    );
    path.arcTo(
      Rect.fromCircle(center: Offset(size / 2, size * 0.38), radius: size * 0.4),
      math.pi,
      math.pi,
      false,
    );
    path.cubicTo(
      size * 0.9, size * 0.50,
      size * 0.85, size * 0.65,
      size / 2, size * 0.95,
    );
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 2.0, true);
    canvas.drawPath(path, purplePaint);
    canvas.drawPath(path, whitePaint);
    // Draw white center dot inside pin
    canvas.drawCircle(Offset(size / 2, size * 0.38), size * 0.12, innerCirclePaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // Generates the green price tag badge with downward arrow pointing to coordinates
  Future<BitmapDescriptor> _generateSelectedBadge(String priceText) async {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: priceText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5, // Standard map text size
        fontWeight: FontWeight.w800,
        fontFamily: 'Outfit',
      ),
    );
    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;
    
    const double px = 10.0; // Compact padding
    const double py = 6.0;
    
    final double cardWidth = textWidth + (px * 2);
    final double cardHeight = textHeight + (py * 2);
    const double triangleHeight = 5.0;
    const double triangleWidth = 8.0;
    
    final double totalWidth = cardWidth;
    final double totalHeight = cardHeight + triangleHeight;
    
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas badgeCanvas = Canvas(recorder);
    
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF059669) // Emerald-600 matching web #059669
      ..style = PaintingStyle.fill;
      
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      const Radius.circular(10.0), // Compact border radius
    );
    
    final Path path = Path();
    path.moveTo(cardWidth / 2 - triangleWidth / 2, cardHeight);
    path.lineTo(cardWidth / 2 + triangleWidth / 2, cardHeight);
    path.lineTo(cardWidth / 2, cardHeight + triangleHeight);
    path.close();
    
    final Path badgePath = Path()..addRRect(rrect)..addPath(path, Offset.zero);
    
    badgeCanvas.drawShadow(badgePath, Colors.black.withValues(alpha: 0.3), 3.0, true);
    badgeCanvas.drawPath(badgePath, greenPaint);
    textPainter.paint(badgeCanvas, Offset(px, py));
    
    final ui.Image image = await recorder.endRecording().toImage(totalWidth.toInt(), totalHeight.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // Default center – Balasore / Odisha area
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(21.4934, 86.9294),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        if (mounted) setState(() => _myLocationEnabled = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  List<MessModel> _getFilteredMesses(List<MessModel> all) {
    return all.where((m) {
      // Type filter
      if (_activeTypeFilter != 'all') {
        final filterLower = _activeTypeFilter.toLowerCase();
        final typeLower = m.messType.toLowerCase();
        if (filterLower == 'boys' && !typeLower.contains('boy')) return false;
        if (filterLower == 'girls' && !typeLower.contains('girl')) return false;
      }
      // Amenity filters – use safe bool parsing to avoid TypeError
      bool checkAmenity(String key) {
        final val = m.amenities[key];
        if (val == null) return false;
        return _parseBool(val);
      }

      if (_amenityFilters['wifi'] == true && !checkAmenity('wifi')) {
        return false;
      }
      if (_amenityFilters['ac'] == true && !checkAmenity('ac')) return false;
      if (_amenityFilters['food'] == true && !checkAmenity('food')) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = m.name.toLowerCase().contains(q);
        final addrMatch = m.address.toLowerCase().contains(q);
        if (!nameMatch && !addrMatch) return false;
      }

      return true;
    }).toList();
  }

  // ── Camera helpers ────────────────────────────────────────────────────────

  Future<void> _animateToMess(MessModel mess) async {
    if (mess.latitude == null || mess.longitude == null) return;
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(mess.latitude!, mess.longitude!),
          zoom: 15,
        ),
      ),
    );
  }

  void _onFilterTapped(String filter) {
    setState(() {
      _activeTypeFilter = filter;
      _selectedMessId = null;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    Future.delayed(const Duration(milliseconds: 100), () {
      final messes =
          _getFilteredMesses(ref.read(filteredMessesProvider));
      if (messes.isNotEmpty) _animateToMess(messes.first);
    });
  }

  void _onMarkerTapped(MessModel mess, List<MessModel> list) {
    setState(() => _selectedMessId = mess.id);
    _animateToMess(mess);
    final idx = list.indexWhere((m) => m.id == mess.id);
    if (idx != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index, List<MessModel> list) {
    if (index < 0 || index >= list.length) return;
    final mess = list[index];
    setState(() => _selectedMessId = mess.id);
    if (_isMapIdle) _animateToMess(mess);
  }

  Set<Marker> _buildMarkers(List<MessModel> list) {
    return list
        .where((m) => m.latitude != null && m.longitude != null)
        .map((mess) {
      final isSelected = mess.id == _selectedMessId;
      
      // Load custom marker icon from cache, fallback to defaults while loading
      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
      if (isSelected) {
        icon = _markerIconCache[mess.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      } else {
        icon = _unselectedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }

      return Marker(
        markerId: MarkerId(mess.id),
        position: LatLng(mess.latitude!, mess.longitude!),
        icon: icon,
        zIndexInt: isSelected ? 999 : 1,
        onTap: () => _onMarkerTapped(mess, list),
      );
    }).toSet();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messesAsync = ref.watch(messesStreamProvider);
    final isLoading = messesAsync.isLoading;
    final baseMesses = ref.watch(filteredMessesProvider);
    final displayMesses = _getFilteredMesses(baseMesses);

    // Preload custom marker icons for the matches
    if (displayMesses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadMarkerIcons(displayMesses);
      });
    }

    // Dynamic camera movements handled via listeners to prevent map recreation crashes
    ref.listen<List<MessModel>>(filteredMessesProvider, (previous, next) {
      if ((previous == null || previous.isEmpty) && next.isNotEmpty) {
        final firstMess = _getFilteredMesses(next).firstOrNull;
        if (firstMess != null && firstMess.latitude != null && firstMess.longitude != null) {
          _animateToMess(firstMess);
        }
      }
    });

    ref.listen<UserLocation?>(userLocationProvider, (previous, next) {
      if (previous == null && next != null) {
        _mapController.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(next.lat, next.lng),
                zoom: 14,
              ),
            ),
          );
        });
      }
    });

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Full-screen Google Map ───────────────────────────────────
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _buildMarkers(displayMesses),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
                
                // If data is already loaded when map is created
                if (displayMesses.isNotEmpty && displayMesses.first.latitude != null) {
                  controller.moveCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(displayMesses.first.latitude!, displayMesses.first.longitude!),
                      14,
                    ),
                  );
                } else {
                  final userLoc = ref.read(userLocationProvider);
                  if (userLoc != null) {
                    controller.moveCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(userLoc.lat, userLoc.lng),
                        14,
                      ),
                    );
                  }
                }
              }
            },
            onCameraMoveStarted: () => setState(() => _isMapIdle = false),
            onCameraIdle: () => setState(() => _isMapIdle = true),
            onTap: (_) => setState(() => _selectedMessId = null),
          ),

          // ── 2. Top overlay (Back + toggle button) ───────────────────────
          // ── 2. Top overlay (Back + Search + toggle button matching website) ────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Circular back button (matches website)
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),

                // Search Bar in the middle (matches website)
                Expanded(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                                _showSearchDropdown = _searchQuery.isNotEmpty;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search mess name...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontFamily: 'Outfit',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Outfit',
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _showSearchDropdown = false;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Full Map / Mess View Toggle Button
                GestureDetector(
                  onTap: () => setState(() => _showFullMap = !_showFullMap),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _showFullMap ? 'Mess View' : 'Full Map',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search Dropdown Suggestions ─────────────────────────────────
          if (_showSearchDropdown && _searchQuery.isNotEmpty)
            Positioned(
              top: topPad + 60,
              left: 56,
              right: 56,
              child: Material(
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Builder(
                    builder: (context) {
                      final matches = baseMesses
                          .where((m) =>
                              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              m.address.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .take(5)
                          .toList();
                      if (matches.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No suggestions found for "$_searchQuery"',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Outfit'),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MESSES',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                letterSpacing: 0.5,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(bottom: 6),
                              itemCount: matches.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
                              itemBuilder: (context, idx) {
                                final m = matches[idx];
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.home_rounded, size: 17, color: AppTheme.primary),
                                  ),
                                  title: Text(
                                    m.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
                                  ),
                                  subtitle: Text(
                                    m.address.isNotEmpty ? m.address : 'Address not listed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontFamily: 'Outfit'),
                                  ),
                                  trailing: const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF9CA3AF)),
                                  onTap: () {
                                    setState(() {
                                      _searchController.text = m.name;
                                      _searchQuery = m.name;
                                      _showSearchDropdown = false;
                                      _selectedMessId = m.id;
                                    });
                                    _animateToMess(m);
                                    final targetIndex = displayMesses.indexWhere((item) => item.id == m.id);
                                    if (targetIndex != -1 && _pageController.hasClients) {
                                      _pageController.animateToPage(
                                        targetIndex,
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── 2b. Scrollable filter chips (below back & toggle row) ────────
          Positioned(
            top: topPad + 68,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Type filters
                  ...[
                    ('All', 'all'),
                    ('Boys', 'Boys'),
                    ('Girls', 'Girls'),
                  ].map(
                    (chip) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTypeChip(chip.$1, chip.$2),
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),

                  // Amenity filters
                  ...[
                    ('Wi-Fi', 'wifi'),
                    ('AC', 'ac'),
                    ('Food', 'food'),
                  ].map(
                    (chip) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAmenityChip(chip.$1, chip.$2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Recenter Button (Animates vertically with carousel) ──────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            right: 16,
            bottom: _showFullMap
                ? 16 + MediaQuery.of(context).padding.bottom
                : 184 + MediaQuery.of(context).padding.bottom, // Placed exactly above bottom carousel (16 + 152 + 16)
            child: GestureDetector(
              onTap: () async {
                final controller = await _mapController.future;
                var userLoc = ref.read(userLocationProvider);
                if (userLoc == null) {
                  final msg = await ref.read(userLocationProvider.notifier).getCurrentLocation();
                  userLoc = ref.read(userLocationProvider);
                  if (userLoc == null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                }
                if (userLoc != null) {
                  if (mounted && !_myLocationEnabled) {
                    setState(() => _myLocationEnabled = true);
                  }
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(userLoc.lat, userLoc.lng),
                        zoom: 15,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),

          // ── 4. Bottom carousel (Slides down off-screen) ──────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            bottom: _showFullMap
                ? -168 // Hidden below screen
                : 16 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            height: 152,
            child: displayMesses.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => _onPageChanged(idx, displayMesses),
                    itemCount: displayMesses.length,
                    itemBuilder: (context, index) {
                      final mess = displayMesses[index];
                      final isSelected = mess.id == _selectedMessId;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isSelected ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF059669).withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                          ],
                        ),
                        child: _ExplorerMessCard(
                          mess: mess,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedMessId = mess.id);
                            _animateToMess(mess);
                          },
                          onViewDetails: () => context.push('/mess/${mess.id}'),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),

          // Loading / Empty state
          if (isLoading)
            Positioned(
              bottom: _showFullMap ? 100 : 200,
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            )
          else if (displayMesses.isEmpty)
            Positioned(
              bottom: _showFullMap ? 100 : 200,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'No messes found matching the current filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter chip builders ──────────────────────────────────────────────────

  Widget _buildTypeChip(String label, String value) {
    final isActive = _activeTypeFilter == value;
    return GestureDetector(
      onTap: () => _onFilterTapped(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isActive ? AppTheme.primary : const Color(0xFFE5E7EB),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : const Color(0xFF374151),
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String label, String key) {
    final isActive = _amenityFilters[key] == true;
    return GestureDetector(
      onTap: () => setState(
        () => _amenityFilters = {
          ..._amenityFilters,
          key: !isActive,
        },
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isActive ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : const Color(0xFF374151),
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}

// ── Horizontal Explorer Card (matches website's bottom carousel card) ─────────

class _ExplorerMessCard extends ConsumerStatefulWidget {
  final MessModel mess;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

  const _ExplorerMessCard({
    required this.mess,
    required this.isSelected,
    required this.onTap,
    required this.onViewDetails,
  });

  @override
  ConsumerState<_ExplorerMessCard> createState() => _ExplorerMessCardState();
}

class _ExplorerMessCardState extends ConsumerState<_ExplorerMessCard> {
  String? _imageUrl;
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _ExplorerMessCard old) {
    super.didUpdateWidget(old);
    if (old.mess.posterUrl != widget.mess.posterUrl) _resolveImage();
  }

  Future<void> _resolveImage() async {
    final url = widget.mess.posterUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _loadingImage = false);
      return;
    }
    
    final service = ref.read(imageUrlServiceProvider);
    final resolved = await service.resolveUrl(url);
    if (mounted) {
      setState(() {
        _imageUrl = resolved;
        _loadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mess = widget.mess;
    final isSelected = widget.isSelected;
    final userLocation = ref.watch(userLocationProvider);

    double? distanceKm;
    if (userLocation != null && mess.latitude != null && mess.longitude != null) {
      distanceKm = _getDistanceKm(
        userLocation.lat,
        userLocation.lng,
        mess.latitude!,
        mess.longitude!,
      );
    }

    // Mess-type badge color
    Color badgeBg;
    Color badgeFg;
    final lowerType = mess.messType.toLowerCase();
    if (lowerType.contains('girl')) {
      badgeBg = const Color(0xFFFCE7F3);
      badgeFg = const Color(0xFFBE185D);
    } else if (lowerType.contains('boy')) {
      badgeBg = const Color(0xFFDBEAFE);
      badgeFg = const Color(0xFF1E40AF);
    } else {
      badgeBg = const Color(0xFFE0E7FF);
      badgeFg = const Color(0xFF4338CA);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
              : Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail (Left) ──────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: _loadingImage
                        ? Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                width: 88,
                                height: 88,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => _placeholder(),
                              )
                            : _placeholder(),
                  ),
                ),
                // Mess-type badge
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      mess.messType.isEmpty ? 'MIXED' : mess.messType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: badgeFg,
                        fontFamily: 'Outfit',
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Info + Action (Right) ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and Address
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mess.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontFamily: 'Outfit',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mess.address.isNotEmpty
                            ? mess.address
                            : 'Address not listed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF6B7280),
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),

                  // Distance / Price Row + Full-width View Details button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withValues(alpha: 0.12)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(5),
                                border: isSelected
                                    ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 10,
                                    color: isSelected ? Colors.white : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${distanceKm.toStringAsFixed(1)} km away',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF15803D),
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          if (mess.minPrice != null)
                            Text(
                              mess.minPrice == mess.maxPrice || mess.maxPrice == null
                                  ? '₹${mess.minPrice}${mess.rentCycle == 'yearly' ? '/yr' : '/mo'}'
                                  : '₹${mess.minPrice}–₹${mess.maxPrice}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF059669),
                                fontFamily: 'Outfit',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Full-width "View Details" button matching website exactly
                      GestureDetector(
                        onTap: widget.onViewDetails,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF374151),
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 12,
                                color: isSelected
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF374151),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Text('🏡', style: TextStyle(fontSize: 30)),
      ),
    );
  }
}
