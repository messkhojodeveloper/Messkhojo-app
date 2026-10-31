import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/districts_config.dart';
import '../../core/utils/localities_provider.dart';
import '../../providers/districts_provider.dart';
import '../../core/services/analytics_tracker.dart';

const List<String> roomSpecificityOptions = [
  'Standard Non-AC',
  'AC Room',
  'Attached Washroom',
  'AC + Attached Washroom',
  'With Balcony',
  'Deluxe Room',
  'Ground Floor',
  'Top Floor',
  'Other'
];

// ─────────────────────────────────────────────────────────────────────────────
// EXACT GENDER ICONS MATCHING GenderIcons.jsx
// ─────────────────────────────────────────────────────────────────────────────

class BoysIconWidget extends StatelessWidget {
  final Color color;
  final double size;
  const BoysIconWidget({super.key, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * (28.0 / 36.0), size),
      painter: _BoysPainter(color),
    );
  }
}

class _BoysPainter extends CustomPainter {
  final Color color;
  _BoysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final sx = size.width / 100.0;
    final sy = size.height / 150.0;

    // Head
    canvas.drawCircle(Offset(50 * sx, 20 * sy), 14 * sx, paint);
    // Left Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 * sx, 44 * sy, 14 * sx, 56 * sy), Radius.circular(7 * sx)),
      paint,
    );
    // Right Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(72 * sx, 44 * sy, 14 * sx, 56 * sy), Radius.circular(7 * sx)),
      paint,
    );
    // Upper Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(33 * sx, 42 * sy, 34 * sx, 46 * sy), Radius.circular(7 * sx)),
      paint,
    );
    // Lower Torso
    canvas.drawRect(Rect.fromLTWH(33 * sx, 65 * sy, 34 * sx, 23 * sy), paint);
    // Left Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(33 * sx, 80 * sy, 14 * sx, 62 * sy), Radius.circular(7 * sx)),
      paint,
    );
    // Right Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(53 * sx, 80 * sy, 14 * sx, 62 * sy), Radius.circular(7 * sx)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoysPainter oldDelegate) => oldDelegate.color != color;
}

class GirlsIconWidget extends StatelessWidget {
  final Color color;
  final double size;
  const GirlsIconWidget({super.key, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * (28.0 / 36.0), size),
      painter: _GirlsPainter(color),
    );
  }
}

class _GirlsPainter extends CustomPainter {
  final Color color;
  _GirlsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final sx = size.width / 100.0;
    final sy = size.height / 150.0;

    // Head
    canvas.drawCircle(Offset(50 * sx, 20 * sy), 14 * sx, paint);

    // Left Arm (rotated 7 deg around 20, 70)
    canvas.save();
    canvas.translate(20 * sx, 70 * sy);
    canvas.rotate(7 * 3.1415926535 / 180);
    canvas.translate(-20 * sx, -70 * sy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 * sx, 44 * sy, 12 * sx, 52 * sy), Radius.circular(6 * sx)),
      paint,
    );
    canvas.restore();

    // Right Arm (rotated -7 deg around 80, 70)
    canvas.save();
    canvas.translate(80 * sx, 70 * sy);
    canvas.rotate(-7 * 3.1415926535 / 180);
    canvas.translate(-80 * sx, -70 * sy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(74 * sx, 44 * sy, 12 * sx, 52 * sy), Radius.circular(6 * sx)),
      paint,
    );
    canvas.restore();

    // Trapezium Dress
    final dress = Path()
      ..moveTo(39 * sx, 44 * sy)
      ..lineTo(61 * sx, 44 * sy)
      ..quadraticBezierTo(63.5 * sx, 44 * sy, 64 * sx, 46.5 * sy)
      ..lineTo(70.5 * sx, 94.5 * sy)
      ..quadraticBezierTo(71.5 * sx, 97 * sy, 68.5 * sx, 97 * sy)
      ..lineTo(31.5 * sx, 97 * sy)
      ..quadraticBezierTo(28.5 * sx, 97 * sy, 29.5 * sx, 94.5 * sy)
      ..lineTo(36 * sx, 46.5 * sy)
      ..quadraticBezierTo(36.5 * sx, 44 * sy, 39 * sx, 44 * sy)
      ..close();
    canvas.drawPath(dress, paint);

    // Left Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(36 * sx, 94 * sy, 11 * sx, 48 * sy), Radius.circular(5.5 * sx)),
      paint,
    );
    // Right Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(53 * sx, 94 * sy, 11 * sx, 48 * sy), Radius.circular(5.5 * sx)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GirlsPainter oldDelegate) => oldDelegate.color != color;
}

class CoedIconWidget extends StatelessWidget {
  final Color color;
  final double size;
  const CoedIconWidget({super.key, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * (44.0 / 36.0), size),
      painter: _CoedPainter(color),
    );
  }
}

class _CoedPainter extends CustomPainter {
  final Color color;
  _CoedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final sx = size.width / 190.0;
    final sy = size.height / 150.0;

    // Male Figure on left
    canvas.save();
    canvas.translate(-5 * sx, 0);
    canvas.drawCircle(Offset(50 * sx, 20 * sy), 14 * sx, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 * sx, 44 * sy, 14 * sx, 56 * sy), Radius.circular(7 * sx)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(72 * sx, 44 * sy, 14 * sx, 56 * sy), Radius.circular(7 * sx)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(33 * sx, 42 * sy, 34 * sx, 46 * sy), Radius.circular(7 * sx)),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(33 * sx, 65 * sy, 34 * sx, 23 * sy), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(33 * sx, 80 * sy, 14 * sx, 62 * sy), Radius.circular(7 * sx)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(53 * sx, 80 * sy, 14 * sx, 62 * sy), Radius.circular(7 * sx)),
      paint,
    );
    canvas.restore();

    // Female Figure on right
    canvas.save();
    canvas.translate(95 * sx, 0);
    canvas.drawCircle(Offset(50 * sx, 20 * sy), 14 * sx, paint);

    canvas.save();
    canvas.translate(20 * sx, 70 * sy);
    canvas.rotate(7 * 3.1415926535 / 180);
    canvas.translate(-20 * sx, -70 * sy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 * sx, 44 * sy, 12 * sx, 52 * sy), Radius.circular(6 * sx)),
      paint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(80 * sx, 70 * sy);
    canvas.rotate(-7 * 3.1415926535 / 180);
    canvas.translate(-80 * sx, -70 * sy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(74 * sx, 44 * sy, 12 * sx, 52 * sy), Radius.circular(6 * sx)),
      paint,
    );
    canvas.restore();

    final dress = Path()
      ..moveTo(39 * sx, 44 * sy)
      ..lineTo(61 * sx, 44 * sy)
      ..quadraticBezierTo(63.5 * sx, 44 * sy, 64 * sx, 46.5 * sy)
      ..lineTo(70.5 * sx, 94.5 * sy)
      ..quadraticBezierTo(71.5 * sx, 97 * sy, 68.5 * sx, 97 * sy)
      ..lineTo(31.5 * sx, 97 * sy)
      ..quadraticBezierTo(28.5 * sx, 97 * sy, 29.5 * sx, 94.5 * sy)
      ..lineTo(36 * sx, 46.5 * sy)
      ..quadraticBezierTo(36.5 * sx, 44 * sy, 39 * sx, 44 * sy)
      ..close();
    canvas.drawPath(dress, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(36 * sx, 94 * sy, 11 * sx, 48 * sy), Radius.circular(5.5 * sx)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(53 * sx, 94 * sy, 11 * sx, 48 * sy), Radius.circular(5.5 * sx)),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoedPainter oldDelegate) => oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA STRUCTURES
// ─────────────────────────────────────────────────────────────────────────────

class LocalMediaItem {
  final XFile file;
  final String name;
  final bool isVideo;
  final Uint8List? previewBytes;

  LocalMediaItem({
    required this.file,
    required this.name,
    this.isVideo = false,
    this.previewBytes,
  });
}

class RoomVariantItem {
  String specificityType; // 'Standard Non-AC', etc. or 'Other'
  String customLabel;
  String label;
  String price;
  bool isVacant;
  List<LocalMediaItem> localMedia;

  RoomVariantItem({
    this.specificityType = '',
    this.customLabel = '',
    this.label = '',
    this.price = '',
    this.isVacant = true,
    List<LocalMediaItem>? localMedia,
  }) : localMedia = localMedia ?? [];
}

class MessRegistrationScreen extends ConsumerStatefulWidget {
  const MessRegistrationScreen({super.key});

  @override
  ConsumerState<MessRegistrationScreen> createState() => _MessRegistrationScreenState();
}

class _MessRegistrationScreenState extends ConsumerState<MessRegistrationScreen> {
  int _step = 1;
  final int _totalSteps = 4;
  bool _isLoading = false;
  bool _gpsLoading = false;
  String _uploadProgressText = '';

  // ── Step 1: Mess Details ─────────────────────────────────────────────────
  String _messName = '';
  List<String> _messType = ['Boys']; // 'Boys', 'Girls', 'Co-ed'
  String _district = '';
  String _city = '';
  String _locality = '';
  String _localityType = '';
  String _customLocality = '';
  double? _gpsLatitude;
  double? _gpsLongitude;
  double? _gpsAccuracy;
  String _address = '';
  String _phoneNumber = '';

  // ── Step 2: Room Pricing & Features ──────────────────────────────────────
  String _totalBeds = '';
  final List<LocalMediaItem> _buildingPhotos = [];
  final List<String> _roomTypes = []; // '1 Seater', '2 Seater', etc.
  final Map<String, List<RoomVariantItem>> _roomVariants = {};

  // ── Step 3: Food & Facilities ────────────────────────────────────────────
  String _foodAvailability = 'Food Available'; // 'Food Available', 'Self Cook', 'Both'
  String _managedBy = 'Owner'; // 'Owner', 'Students', 'Warden', 'Nearby Canteen'
  String _mealsPerDay = '3 Meals'; // '1 Meal', '2 Meals', '3 Meals', '4 Meals'
  String _foodType = 'Veg + Non-Veg'; // 'Pure Veg', 'Veg + Non-Veg'
  String _waterFacility = 'Both'; // 'Water Filter', 'Tubewell', 'Both', 'None'
  String _laundryFacility = 'Washing Machine'; // 'Laundry', 'Washing Machine', 'Both', 'None'
  String _cleaningService = 'Both'; // 'Room Cleaning', 'Washroom Cleaning', 'Both', 'None'
  bool _wifi = true;
  bool _powerBackup = true;
  bool _cctv = true;
  bool _wardenWatchman = true;
  final List<String> _extraSpace = []; // 'Parking', 'Access to Terrace', 'Dining Hall', 'Library'

  // ── Step 4: Charges & Extra Details ──────────────────────────────────────
  String _rentCycle = 'monthly'; // 'monthly', 'yearly'
  String _securityDepositType = 'No Deposit'; // 'No Deposit', 'Monthly', 'Custom'
  String _securityDepositMonths = '1 Month';
  String _securityDepositCustom = '';
  String _advancePaymentType = 'No Deposit'; // 'No Deposit', 'Monthly', 'Custom'
  String _advancePaymentMonths = '1 Month';
  String _advancePaymentCustom = '';
  String _electricityBill = 'Included in Rent'; // 'Included in Rent', 'As per Meter', 'Extra Fixed'
  String _electricityBillAmount = '';
  String _maintenanceFee = 'Included'; // 'Included', 'Extra Charge'
  String _maintenanceFeeAmount = '';
  String _cleaningCharges = 'Included in Rent'; // 'Included in Rent', 'Extra Charge', 'None'
  String _cleaningChargesAmount = '';
  String _foodBill = 'Included in Rent'; // 'Included in Rent', 'Separate', 'Self Cook'
  String _utensilsCharges = 'Provided'; // 'Provided', 'Chargeable', 'Bring Own'
  String _noticePeriod = '1 Month'; // 'No Notice', '15 Days', '1 Month', '2 Months', '3 Months', 'Other'
  String _noticePeriodCustom = '';
  String _operatingSince = '';
  String _description = '';
  bool _consent = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsTracker.instance.trackMessRegistration(true, step: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSecurityDepositTypeChange(String type) {
    setState(() {
      _securityDepositType = type;
    });
  }

  void _handleSecurityMonthsChange(String months) {
    setState(() {
      _securityDepositMonths = months;
    });
  }

  void _handleAdvancePaymentTypeChange(String type) {
    setState(() {
      _advancePaymentType = type;
    });
  }

  void _handleAdvanceMonthsChange(String months) {
    setState(() {
      _advancePaymentMonths = months;
    });
  }

  void _handleRoomTypeToggle(String type) {
    setState(() {
      if (_roomTypes.contains(type)) {
        _roomTypes.remove(type);
        _roomVariants.remove(type);
      } else {
        _roomTypes.add(type);
        _roomVariants[type] = [RoomVariantItem()];
      }
    });
  }

  void _addVariant(String room) {
    setState(() {
      _roomVariants[room] = [
        ...(_roomVariants[room] ?? []),
        RoomVariantItem(),
      ];
    });
  }

  void _removeVariant(String room, int index) {
    setState(() {
      final list = _roomVariants[room] ?? [];
      if (list.length > 1) {
        list.removeAt(index);
      }
    });
  }

  void _handleCheckboxToggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  // Pick photos / videos from device memory using image_picker
  void _showMediaPickerSheet({
    required Function(List<LocalMediaItem>) onMediaPicked,
    bool allowVideo = false,
  }) {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload from Device Memory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select photos or videos stored on your device',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                title: const Text('Choose Photos from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Select multiple photos from device memory', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final List<XFile> files = await picker.pickMultiImage(
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (files.isNotEmpty) {
                      final items = <LocalMediaItem>[];
                      for (final f in files) {
                        final bytes = await f.readAsBytes();
                        items.add(LocalMediaItem(file: f, name: f.name, isVideo: false, previewBytes: bytes));
                      }
                      onMediaPicked(items);
                    }
                  } catch (e) {
                    _showSnackBar('Error picking photos: $e');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Capture live building or room photo', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final XFile? file = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      onMediaPicked([LocalMediaItem(file: file, name: file.name, isVideo: false, previewBytes: bytes)]);
                    }
                  } catch (e) {
                    _showSnackBar('Error using camera: $e');
                  }
                },
              ),
              if (allowVideo)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFDF2F8), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFFDB2777), size: 22),
                  ),
                  title: const Text('Choose Video from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Select a room tour video from device memory', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        onMediaPicked([LocalMediaItem(file: file, name: file.name, isVideo: true, previewBytes: bytes)]);
                      }
                    } catch (e) {
                      _showSnackBar('Error picking video: $e');
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGetGPS() async {
    setState(() => _gpsLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are required to auto-fill GPS.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied. Please enable in settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _gpsLatitude = pos.latitude;
        _gpsLongitude = pos.longitude;
        _gpsAccuracy = pos.accuracy;
      });
      _showSnackBar('GPS coordinates captured successfully!');
    } catch (e) {
      _showSnackBar('Unable to capture GPS. Please check location settings.');
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Registration?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111827))),
        content: const Text(
          'Are you sure you want to exit registration? Any unsaved progress will be lost.',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _isStepValid() {
    switch (_step) {
      case 1:
        return _messName.trim().isNotEmpty &&
            _district.isNotEmpty &&
            _city.isNotEmpty &&
            _phoneNumber.length == 10;
      case 2:
        if (_roomTypes.isNotEmpty) {
          return _roomTypes.every((room) {
            final variants = _roomVariants[room] ?? [];
            return variants.every((v) =>
                v.price.isEmpty || (num.tryParse(v.price) != null && num.parse(v.price) >= 0));
          });
        }
        return true;
      case 3:
        return true;
      case 4:
        if (_noticePeriod == 'Other' && _noticePeriodCustom.trim().isEmpty) return false;
        final secType = _securityDepositType;
        if (secType == 'Custom' && _securityDepositCustom.trim().isEmpty) return false;
        final advType = _advancePaymentType;
        if (advType == 'Custom' && _advancePaymentCustom.trim().isEmpty) return false;
        if (_maintenanceFee == 'Extra Charge' && _maintenanceFeeAmount.trim().isEmpty) return false;
        if (_electricityBill == 'Extra Fixed' && _electricityBillAmount.trim().isEmpty) return false;
        if (_cleaningCharges == 'Extra Charge' && _cleaningChargesAmount.trim().isEmpty) return false;
        return _consent;
      default:
        return true;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORM SUBMISSION WITH FIREBASE STORAGE UPLOADS (EXACT PARITY WITH WEBSITE)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_isStepValid() || _isLoading) return;
    setState(() {
      _isLoading = true;
      _uploadProgressText = 'Processing registration...';
    });

    try {
      final sanitizedMessName = (_messName.isNotEmpty ? _messName : 'mess')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toLowerCase();

      final allGalleryUrls = <String>[];
      final uploadedBuildingPhotos = <Map<String, dynamic>>[];
      final buildingPhotoUrls = <String>[];

      // 1. Upload Building Photos to Firebase Storage at mess_registrations/$sanitizedMessName/
      for (int bIdx = 0; bIdx < _buildingPhotos.length; bIdx++) {
        final item = _buildingPhotos[bIdx];
        setState(() {
          _uploadProgressText = 'Uploading building photo (${bIdx + 1}/${_buildingPhotos.length})...';
        });

        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final ext = item.name.split('.').lastOrNull?.toLowerCase() ?? (item.isVideo ? 'mp4' : 'jpg');
          final storagePath = 'mess_registrations/$sanitizedMessName/building_${timestamp}_$bIdx.$ext';
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);

          final bytes = item.previewBytes ?? await item.file.readAsBytes();
          final mimeType = item.isVideo ? 'video/mp4' : 'image/jpeg';
          final metadata = SettableMetadata(contentType: mimeType);

          final uploadTask = await storageRef.putData(bytes, metadata);
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          uploadedBuildingPhotos.add({
            'url': downloadUrl,
            'type': item.isVideo ? 'video' : 'image',
            'name': item.name,
          });
          buildingPhotoUrls.add(downloadUrl);
          allGalleryUrls.add(downloadUrl);
        } catch (uploadErr) {
          debugPrint('Storage upload error for building photo: $uploadErr');
        }
      }

      // 2. Upload Room Variant Photos and Videos to Firebase Storage
      final processedVariants = <String, dynamic>{};
      final rentInfo = <String, dynamic>{};
      final vacantRooms = <String>[];

      for (final room in _roomTypes) {
        final variants = _roomVariants[room] ?? [];
        processedVariants[room] = [];

        for (int vIdx = 0; vIdx < variants.length; vIdx++) {
          final v = variants[vIdx];
          final uploadedMedia = <Map<String, dynamic>>[];

          for (int mIdx = 0; mIdx < v.localMedia.length; mIdx++) {
            final mItem = v.localMedia[mIdx];
            setState(() {
              _uploadProgressText = 'Uploading $room media (${mIdx + 1}/${v.localMedia.length})...';
            });

            try {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final ext = mItem.name.split('.').lastOrNull?.toLowerCase() ?? (mItem.isVideo ? 'mp4' : 'jpg');
              final roomSanitized = room.replaceAll(RegExp(r'\s+'), '_');
              final storagePath = 'mess_registrations/$sanitizedMessName/${roomSanitized}_v${vIdx}_${timestamp}_$mIdx.$ext';
              final storageRef = FirebaseStorage.instance.ref().child(storagePath);

              final bytes = mItem.previewBytes ?? await mItem.file.readAsBytes();
              final mimeType = mItem.isVideo ? 'video/mp4' : 'image/jpeg';
              final metadata = SettableMetadata(contentType: mimeType);

              final uploadTask = await storageRef.putData(bytes, metadata);
              final downloadUrl = await uploadTask.ref.getDownloadURL();

              uploadedMedia.add({
                'url': downloadUrl,
                'type': mItem.isVideo ? 'video' : 'image',
                'name': mItem.name,
              });
              allGalleryUrls.add(downloadUrl);
            } catch (uploadErr) {
              debugPrint('Storage upload error for room media: $uploadErr');
            }
          }

          if (vIdx == 0) {
            rentInfo[room] = num.tryParse(v.price) ?? 0;
            if (v.isVacant && !vacantRooms.contains(room)) {
              vacantRooms.add(room);
            }
          }

          processedVariants[room].add({
            'label': v.label.isNotEmpty ? v.label : 'Standard Non-AC',
            'price': num.tryParse(v.price) ?? 0,
            'isVacant': v.isVacant,
            'mediaUrls': uploadedMedia,
          });
        }
      }

      // Derive legacy facilities
      final derivedFacilities = <String>[];
      if (_wifi) derivedFacilities.add('Wifi');
      if (_foodAvailability != 'Self Cook') derivedFacilities.add('Food Facility');
      if (_powerBackup) derivedFacilities.add('InverterPower');
      if (_cctv) derivedFacilities.add('CCTV');
      if (_extraSpace.contains('Parking')) derivedFacilities.add('Parking');

      // Derive included in rent
      final derivedIncluded = <String>[];
      if (_foodBill == 'Included in Rent') derivedIncluded.add('Food Charges');
      if (_electricityBill == 'Included in Rent') derivedIncluded.add('Electricity Bills');
      if (_cleaningCharges == 'Included in Rent') derivedIncluded.add('Cleaning Charges');
      if (_maintenanceFee == 'Included') derivedIncluded.add('Maintenance Fee');
      if (_utensilsCharges == 'Provided') derivedIncluded.add('Utensils Charges');

      final resolvedLocality = (_localityType == 'Other' || _locality.isEmpty)
          ? (_customLocality.isNotEmpty ? _customLocality : _locality)
          : _locality;

      final resolvedNoticePeriod = _noticePeriod == 'Other'
          ? _noticePeriodCustom.trim()
          : _noticePeriod;

      final bedCount = _totalBeds.trim();

      final registrationData = {
        'messName': _messName.trim(),
        'name': _messName.trim(),
        'messType': _messType,
        'gender': _messType.isNotEmpty ? _messType.first : 'Boys',
        'district': _district,
        'city': _city,
        'locality': resolvedLocality,
        'landmark': resolvedLocality,
        'address': _address.trim(),
        'gpsLatitude': _gpsLatitude,
        'gpsLongitude': _gpsLongitude,
        'gpsAccuracy': _gpsAccuracy,
        'phoneNumber': _phoneNumber.trim(),
        'contact': _phoneNumber.trim(),
        'totalBeds': bedCount,
        'totalRooms': bedCount,
        'buildingPhotos': uploadedBuildingPhotos,
        'buildingPhotoUrls': buildingPhotoUrls,
        'galleryUrls': allGalleryUrls,
        'roomTypes': _roomTypes,
        'roomVariants': processedVariants,
        'rentInfo': rentInfo,
        'vacantRooms': vacantRooms,
        // Step 3: Food & Facilities
        'foodAvailability': _foodAvailability,
        'managedBy': _managedBy,
        'mealsPerDay': _mealsPerDay,
        'foodType': _foodType,
        'waterFacility': _waterFacility,
        'laundryFacility': _laundryFacility,
        'cleaningService': _cleaningService,
        'wifi': _wifi,
        'powerBackup': _powerBackup,
        'cctv': _cctv,
        'wardenWatchman': _wardenWatchman,
        'extraSpace': _extraSpace,
        // Step 4: Charges & Terms
        'description': _description.trim(),
        'rentCycle': _rentCycle,
        'securityDeposit': _securityDepositType == 'Custom'
            ? 'Custom'
            : (_securityDepositType == 'Monthly' ? _securityDepositMonths : 'No Deposit'),
        'securityDepositType': _securityDepositType,
        'securityDepositMonths': _securityDepositMonths,
        'securityDepositCustom': _securityDepositType == 'Custom' ? _securityDepositCustom.trim() : '',
        'advancePayment': {
          'type': _advancePaymentType == 'Custom'
              ? 'Custom'
              : (_advancePaymentType == 'Monthly' ? _advancePaymentMonths : 'No Deposit'),
          'customAmount': _advancePaymentType == 'Custom' ? _advancePaymentCustom.trim() : '',
        },
        'advancePaymentRaw': _advancePaymentType == 'Custom'
            ? 'Custom'
            : (_advancePaymentType == 'Monthly' ? _advancePaymentMonths : 'No Deposit'),
        'advancePaymentType': _advancePaymentType,
        'advancePaymentMonths': _advancePaymentMonths,
        'advancePaymentCustom': _advancePaymentType == 'Custom' ? _advancePaymentCustom.trim() : '',
        'electricityBill': _electricityBill,
        'electricityBillAmount': _electricityBillAmount,
        'maintenanceFee': _maintenanceFee,
        'maintenanceFeeAmount': _maintenanceFeeAmount,
        'maintenanceCharge': {
          'taken': _maintenanceFee == 'Extra Charge',
          'amount': _maintenanceFeeAmount,
          'frequency': 'Per Month',
        },
        'cleaningCharges': _cleaningCharges,
        'cleaningChargesAmount': _cleaningChargesAmount,
        'foodBill': _foodBill,
        'utensilsCharges': _utensilsCharges,
        'noticePeriod': resolvedNoticePeriod,
        'noticePeriodCustom': _noticePeriodCustom,
        'operatingSince': _operatingSince,
        'facilities': derivedFacilities,
        'includedInRent': derivedIncluded,
        'consent': _consent,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('mess_registrations').add(registrationData);

      AnalyticsTracker.instance.trackMessRegistration(
        false,
        messId: docRef.id,
        messName: _messName,
        district: _district,
      );

      setState(() {
        _step = 5; // Success screen
      });
      _scrollToTop();
    } catch (e) {
      _showSnackBar('Failed to submit registration. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgressText = '';
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN UI BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 512),
            height: screenHeight * 0.92,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Pinned Top Progress Bar (6px)
                      if (_step <= _totalSteps)
                        SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: _step / _totalSteps,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF300868)),
                          ),
                        ),

                      // Scrollable Middle Content Area
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: _buildCurrentStep(),
                        ),
                      ),

                      // Pinned Bottom Navigation Bar
                      if (_step <= _totalSteps)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          child: Row(
                            children: [
                              if (_step > 1)
                                InkWell(
                                  onTap: () {
                                    setState(() => _step--);
                                    _scrollToTop();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.transparent,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF6B7280)),
                                        SizedBox(width: 4),
                                        Text('Back', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (_step < _totalSteps)
                                ElevatedButton(
                                  onPressed: _isStepValid()
                                      ? () {
                                          setState(() => _step++);
                                          _scrollToTop();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF300868),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                                    disabledForegroundColor: const Color(0xFF9CA3AF),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    shadowColor: const Color(0xFF300868).withValues(alpha: 0.3),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Next', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      SizedBox(width: 6),
                                      Icon(Icons.chevron_right_rounded, size: 20),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _isStepValid() && !_isLoading ? _handleSubmit : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                                    disabledForegroundColor: const Color(0xFF9CA3AF),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(_uploadProgressText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Submit Form', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                            SizedBox(width: 6),
                                            Icon(Icons.send_rounded, size: 16),
                                          ],
                                        ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Pinned Top-Right Close Button
                  if (_step <= _totalSteps)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: InkWell(
                        onTap: _showExitConfirmation,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0x99F3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)),
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5Success();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: MESS DETAILS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    final localitiesMap = ref.watch(localitiesStreamProvider).value ?? {};
    final districtsMap = ref.watch(cachedDistrictsProvider);
    final availableCities = _district.isNotEmpty
        ? (districtsMap[_district]?.cities ?? <DistrictCity>[])
        : <DistrictCity>[];
    final availableLocalities = _city.isNotEmpty
        ? getLocalitiesForCity(_city, localitiesMap)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apartment_rounded, size: 24, color: Color(0xFF300868)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Mess Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your basic mess details, location & contact info',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Mess Name
        _buildFieldLabel('MESS NAME'),
        TextFormField(
          initialValue: _messName,
          onChanged: (val) => setState(() => _messName = val),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          decoration: _buildInputDecoration(
            hint: 'e.g. Sunrise Executive Boys Mess & PG',
            prefixIcon: Icons.apartment_rounded,
          ),
        ),
        const SizedBox(height: 16),

        // 2. Mess Type (Boys, Girls, Co-ed)
        _buildFieldLabel('MESS TYPE'),
        Row(
          children: [
            _buildExactTypeCard(
              type: 'Boys',
              label: 'Boys',
              selectedBorder: const Color(0xFF3B82F6),
              selectedBg: const Color(0xFFEFF6FF),
              selectedText: const Color(0xFF1E3A8A),
              iconWidget: (selected) => BoysIconWidget(color: selected ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 8),
            _buildExactTypeCard(
              type: 'Girls',
              label: 'Girls',
              selectedBorder: const Color(0xFFF472B6),
              selectedBg: const Color(0xFFFDF2F8),
              selectedText: const Color(0xFFBE185D),
              iconWidget: (selected) => GirlsIconWidget(color: selected ? const Color(0xFFF472B6) : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 8),
            _buildExactTypeCard(
              type: 'Co-ed',
              label: 'Co-ed',
              selectedBorder: const Color(0xFF300868),
              selectedBg: const Color(0xFFFAF5FF),
              selectedText: const Color(0xFF300868),
              iconWidget: (selected) => CoedIconWidget(color: selected ? const Color(0xFF300868) : const Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Location
        _buildFieldLabel('LOCATION'),
        // Row 1: District & City
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('District', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _district.isEmpty ? null : _district,
                    hint: const Text('Select District', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    items: ref.watch(activeDistrictsProvider).map((dist) {
                      return DropdownMenuItem(value: dist.id, child: Text(dist.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _district = val ?? '';
                        _city = '';
                        _locality = '';
                        _localityType = '';
                        _customLocality = '';
                      });
                    },
                    decoration: _buildDropdownDecoration(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('City / Town', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _city.isEmpty ? null : _city,
                    hint: const Text('Select City', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    items: availableCities.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: _district.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              _city = val ?? '';
                              _locality = '';
                              _localityType = '';
                              _customLocality = '';
                            });
                          },
                    decoration: _buildDropdownDecoration(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Locality & GPS Coordinates
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Locality / Area', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _localityType.isNotEmpty
                        ? _localityType
                        : (availableLocalities.contains(_locality)
                            ? _locality
                            : (_locality.isNotEmpty ? 'Other' : null)),
                    hint: const Text('Select Locality', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    items: [
                      ...availableLocalities.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))),
                      if (availableLocalities.isNotEmpty)
                        const DropdownMenuItem(value: 'Other', child: Text('Other (Custom Locality)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF300868)))),
                    ],
                    onChanged: _city.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              if (val == 'Other') {
                                _localityType = 'Other';
                                _locality = _customLocality;
                              } else {
                                _localityType = val ?? '';
                                _locality = val ?? '';
                              }
                            });
                          },
                    decoration: _buildDropdownDecoration(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GPS Coordinates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _gpsLoading ? null : _handleGetGPS,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _gpsLatitude != null ? const Color(0xFFFAF5FF) : const Color(0xFF300868),
                        border: Border.all(
                          color: _gpsLatitude != null ? const Color(0xFFDDD6FE) : const Color(0xFF300868),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: _gpsLatitude != null ? const Color(0xFF300868) : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _gpsLoading
                                  ? 'Locating...'
                                  : (_gpsLatitude != null
                                      ? '${_gpsLatitude!.toStringAsFixed(3)}, ${_gpsLongitude!.toStringAsFixed(3)}'
                                      : 'Auto Fill GPS'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _gpsLatitude != null ? const Color(0xFF300868) : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Custom Locality Input if Other is selected
        if (_localityType == 'Other' && _city.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _customLocality,
            onChanged: (val) {
              setState(() {
                _customLocality = val;
                _locality = val;
              });
            },
            decoration: _buildInputDecoration(
              hint: 'Enter custom locality',
              prefixIcon: Icons.edit_location_alt_rounded,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 4. Address (optional)
        _buildFieldLabelWithOptional('ADDRESS'),
        TextFormField(
          initialValue: _address,
          onChanged: (val) => setState(() => _address = val),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
          decoration: _buildInputDecoration(
            hint: 'e.g. Plot No. 124, Station Road, Balasore',
            prefixIcon: Icons.home_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // 5. Contact Details (Phone Number)
        _buildFieldLabel('CONTACT DETAILS (PHONE NUMBER)'),
        TextFormField(
          initialValue: _phoneNumber,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (val) => setState(() => _phoneNumber = val),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF111827)),
          decoration: _buildInputDecoration(
            hint: 'e.g. 9876543210',
            prefixIcon: Icons.phone_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildExactTypeCard({
    required String type,
    required String label,
    required Color selectedBorder,
    required Color selectedBg,
    required Color selectedText,
    required Widget Function(bool isSelected) iconWidget,
  }) {
    final isSelected = _messType.contains(type);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _messType = [type]),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBorder : const Color(0xFFF3F4F6),
              width: 2,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: selectedBorder.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: Center(child: iconWidget(isSelected)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? selectedText : const Color(0xFF374151),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check_rounded, size: 12, color: selectedText),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: ROOM PRICING & FEATURES (WITH DEVICE MEMORY UPLOADS)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bed_rounded, size: 24, color: Color(0xFF300868)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Room Pricing & Features',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure total beds, sharing types, prices & features',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Total Beds & Building Photo Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabelWithOptional('TOTAL BEDS'),
                  TextFormField(
                    initialValue: _totalBeds,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() => _totalBeds = val),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    decoration: _buildInputDecoration(hint: 'e.g. 20'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabelWithOptional('MESS BUILDING PHOTO'),
                  InkWell(
                    onTap: () => _showMediaPickerSheet(
                      allowVideo: false,
                      onMediaPicked: (items) => setState(() => _buildingPhotos.addAll(items)),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF300868)),
                          SizedBox(width: 6),
                          Text(
                            'Upload Photo',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF300868)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Building Photos Previews from Device Memory
        if (_buildingPhotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildingPhotos.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.previewBytes != null
                          ? Image.memory(item.previewBytes!, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 24, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: () => setState(() => _buildingPhotos.removeAt(idx)),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xCC000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 18),

        // 2. Types of Room Available
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('TYPES OF ROOM AVAILABLE'),
            const Text('(Select all available)', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        _buildGridButtonChoices(
          items: ['1 Seater', '2 Seater', '3 Seater', '4 Seater', '5 Seater', '6 Seater', '7 Seater'],
          columns: 2,
          isSelected: (type) => _roomTypes.contains(type),
          onTap: (type) => _handleRoomTypeToggle(type),
          showCheck: true,
        ),
        const SizedBox(height: 20),

        // 3. Room Configurations (Price, Specificity, Photos, Vacancy)
        if (_roomTypes.isNotEmpty) ...[
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          const Text(
            'ROOM PRICING & FEATURES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          ..._roomTypes.map((room) {
            final variants = _roomVariants[room] ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x66FAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E8FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bed_rounded, size: 16, color: Color(0xFF300868)),
                          const SizedBox(width: 6),
                          Text(
                            room,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF111827)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _addVariant(room),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 12, color: Color(0xFF300868)),
                              SizedBox(width: 2),
                              Text('Add Variant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF300868))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...variants.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final variant = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF3E8FF)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (variants.length > 1) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Variant ${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF300868))),
                                InkWell(
                                  onTap: () => _removeVariant(room, idx),
                                  child: const Text('REMOVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                                ),
                              ],
                            ),
                            const Divider(height: 12, color: Color(0xFFF3F4F6)),
                          ],

                          // Facilities Dropdown
                          const Text('FACILITIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: variant.specificityType.isNotEmpty
                                ? variant.specificityType
                                : (roomSpecificityOptions.contains(variant.label) ? variant.label : (variant.label.isNotEmpty ? 'Other' : null)),
                            hint: const Text('Select Facilities', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            items: roomSpecificityOptions.map((opt) {
                              return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                if (val == 'Other') {
                                  variant.specificityType = 'Other';
                                  variant.label = variant.customLabel;
                                } else {
                                  variant.specificityType = val ?? '';
                                  variant.label = val ?? '';
                                }
                              });
                            },
                            decoration: _buildDropdownDecoration(),
                          ),
                          if (variant.specificityType == 'Other') ...[
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: variant.customLabel,
                              onChanged: (val) {
                                variant.customLabel = val;
                                variant.label = val;
                              },
                              style: const TextStyle(fontSize: 12),
                              decoration: _buildInputDecoration(hint: 'Write custom facilities (e.g. Attached Washroom)'),
                            ),
                          ],
                          const SizedBox(height: 10),

                          // Price & Status Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('RENT (₹/MONTH)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      initialValue: variant.price,
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => variant.price = val,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                                      decoration: _buildInputDecoration(hint: 'Rent ₹/month'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => setState(() => variant.isVacant = !variant.isVacant),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: variant.isVacant ? const Color(0xFFECFDF5) : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: variant.isVacant ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          variant.isVacant ? '✓ Vacant' : 'Occupied',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: variant.isVacant ? const Color(0xFF047857) : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Upload Media Button from Device Memory
                          InkWell(
                            onTap: () => _showMediaPickerSheet(
                              allowVideo: true,
                              onMediaPicked: (items) => setState(() => variant.localMedia.addAll(items)),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, size: 14, color: Color(0xFF300868)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Upload Photos & Videos',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF300868)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Room Local Media Previews
                          if (variant.localMedia.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: variant.localMedia.asMap().entries.map((mEntry) {
                                final mIdx = mEntry.key;
                                final mItem = mEntry.value;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFDDD6FE)),
                                        color: const Color(0xFF111827),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: mItem.isVideo
                                            ? const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.videocam_rounded, size: 20, color: Color(0xFFD8B4FE)),
                                                    SizedBox(height: 2),
                                                    Text('VIDEO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFE9D5FF))),
                                                  ],
                                                ),
                                              )
                                            : (mItem.previewBytes != null
                                                ? Image.memory(mItem.previewBytes!, fit: BoxFit.cover)
                                                : const Icon(Icons.image, size: 24, color: Color(0xFF9CA3AF))),
                                      ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: InkWell(
                                        onTap: () => setState(() => variant.localMedia.removeAt(mIdx)),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Color(0xCC000000),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: FOOD & FACILITIES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_rounded, size: 24, color: Color(0xFF300868)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Food & Facilities',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure mess food, water, cleaning, utilities & spaces',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Food Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x66FAF5FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3E8FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FOOD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1F2937), letterSpacing: 0.8)),
              const SizedBox(height: 10),

              // Food Option
              const Text('Food Option', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Food Available', 'Self Cook', 'Both'], _foodAvailability, (val) => setState(() => _foodAvailability = val)),
              const SizedBox(height: 12),

              // Managed By (2x2 grid with subtitle)
              const Text('Food Facility Managed By', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildManagedByGrid(),
              const SizedBox(height: 12),

              // Meals per day
              if (_foodAvailability != 'Self Cook') ...[
                const Text('No. of Meals Served in a Day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                _buildOptionGrid(['1 Meal', '2 Meals', '3 Meals', '4 Meals'], _mealsPerDay, (val) => setState(() => _mealsPerDay = val)),
                const SizedBox(height: 12),
              ],

              // Food Type
              const Text('Food Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Pure Veg', 'Veg + Non-Veg'], _foodType, (val) => setState(() => _foodType = val)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Water Section
        _buildFieldLabel('WATER'),
        _buildOptionGrid(['Water Filter', 'Tubewell', 'Both', 'None'], _waterFacility, (val) => setState(() => _waterFacility = val)),
        const SizedBox(height: 16),

        // 3. Cleaning Section (Laundry)
        _buildFieldLabel('CLEANING SECTION (LAUNDRY)'),
        _buildOptionGrid(['Laundry', 'Washing Machine', 'Both', 'None'], _laundryFacility, (val) => setState(() => _laundryFacility = val)),
        const SizedBox(height: 16),

        // 4. Cleaning Service (Housekeeping)
        _buildFieldLabel('CLEANING SERVICE'),
        _buildOptionGrid(['Room Cleaning', 'Washroom Cleaning', 'Both', 'None'], _cleaningService, (val) => setState(() => _cleaningService = val)),
        const SizedBox(height: 16),

        // 5. Utilities & Security (2x2 grid)
        _buildFieldLabel('UTILITIES & SECURITY'),
        Row(
          children: [
            Expanded(child: _buildYesNoToggle('Wifi', 'Internet', _wifi, (v) => setState(() => _wifi = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildYesNoToggle('Power Backup', 'Inverter', _powerBackup, (v) => setState(() => _powerBackup = v))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildYesNoToggle('CCTV', 'Security', _cctv, (v) => setState(() => _cctv = v))),
            const SizedBox(width: 8),
            Expanded(child: _buildYesNoToggle('Warden / Watchman', 'Staff', _wardenWatchman, (v) => setState(() => _wardenWatchman = v))),
          ],
        ),
        const SizedBox(height: 16),

        // 6. Extra Space
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('EXTRA SPACE'),
            const Text('(Select all available)', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        _buildExtraSpaceGrid(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4: CHARGES & EXTRA DETAILS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, size: 24, color: Color(0xFF300868)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Charges & Extra Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure rent, charges, notice period & operating history',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Charges Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x66FAF5FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3E8FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHARGES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1F2937), letterSpacing: 0.8)),
              const SizedBox(height: 10),

              // Rent Billing Cycle
              const Text('Rent Billing Cycle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(
                ['Monthly Basis', 'Yearly Basis'],
                _rentCycle == 'monthly' ? 'Monthly Basis' : 'Yearly Basis',
                (v) => setState(() => _rentCycle = v.startsWith('Monthly') ? 'monthly' : 'yearly'),
              ),
              const SizedBox(height: 12),

              // Security Deposit
              const Text('Security Deposit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(
                ['No Deposit', 'Monthly', 'Custom'],
                _securityDepositType,
                _handleSecurityDepositTypeChange,
                columns: 3,
              ),
              const SizedBox(height: 6),
              _buildMonthsDropdown(
                isEnabled: _securityDepositType == 'Monthly',
                value: _securityDepositMonths,
                onChanged: (val) {
                  if (val != null) _handleSecurityMonthsChange(val);
                },
              ),
              if (_securityDepositType == 'Custom') ...[
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: _securityDepositCustom,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _securityDepositCustom = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: _buildInputDecoration(hint: 'Enter security deposit amount (₹)'),
                ),
              ],
              const SizedBox(height: 12),

              // Advance Payment
              const Text('Advance Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(
                ['No Deposit', 'Monthly', 'Custom'],
                _advancePaymentType,
                _handleAdvancePaymentTypeChange,
                columns: 3,
              ),
              const SizedBox(height: 6),
              _buildMonthsDropdown(
                isEnabled: _advancePaymentType == 'Monthly',
                value: _advancePaymentMonths,
                onChanged: (val) {
                  if (val != null) _handleAdvanceMonthsChange(val);
                },
              ),
              if (_advancePaymentType == 'Custom') ...[
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: _advancePaymentCustom,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _advancePaymentCustom = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: _buildInputDecoration(hint: 'Enter advance payment amount (₹)'),
                ),
              ],
              const SizedBox(height: 12),

              // Electricity Bill
              const Text('Electricity Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Included in Rent', 'As per Meter', 'Extra Fixed'], _electricityBill, (v) => setState(() => _electricityBill = v)),
              if (_electricityBill == 'Extra Fixed') ...[
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: _electricityBillAmount,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _electricityBillAmount = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: _buildInputDecoration(hint: 'Enter monthly electricity bill (₹)'),
                ),
              ],
              const SizedBox(height: 12),

              // Maintenance Fee
              const Text('Maintenance Fee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Included', 'Extra Charge'], _maintenanceFee, (v) => setState(() => _maintenanceFee = v)),
              if (_maintenanceFee == 'Extra Charge') ...[
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: _maintenanceFeeAmount,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _maintenanceFeeAmount = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: _buildInputDecoration(hint: 'Enter monthly maintenance fee (₹)'),
                ),
              ],
              const SizedBox(height: 12),

              // Cleaning Charges
              const Text('Cleaning Charges', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Included in Rent', 'Extra Charge', 'None'], _cleaningCharges, (v) => setState(() => _cleaningCharges = v)),
              if (_cleaningCharges == 'Extra Charge') ...[
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: _cleaningChargesAmount,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _cleaningChargesAmount = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: _buildInputDecoration(hint: 'Enter monthly cleaning fee (₹)'),
                ),
              ],
              const SizedBox(height: 12),

              // Food Bill
              const Text('Food Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Included in Rent', 'Separate', 'Self Cook'], _foodBill, (v) => setState(() => _foodBill = v)),
              const SizedBox(height: 12),

              // Utensils Charges
              const Text('Utensils Charges', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              _buildOptionGrid(['Provided', 'Chargeable', 'Bring Own'], _utensilsCharges, (v) => setState(() => _utensilsCharges = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Notice Period (6 options in grid)
        _buildFieldLabel('NOTICE PERIOD'),
        _buildOptionGrid(
          ['No Notice', '15 Days', '1 Month', '2 Months', '3 Months', 'Other'],
          _noticePeriod,
          (v) => setState(() => _noticePeriod = v),
          columns: 3,
        ),
        if (_noticePeriod == 'Other') ...[
          const SizedBox(height: 6),
          TextFormField(
            initialValue: _noticePeriodCustom,
            onChanged: (v) => _noticePeriodCustom = v,
            style: const TextStyle(fontSize: 13),
            decoration: _buildInputDecoration(hint: 'Enter notice period (e.g. 45 Days)'),
          ),
        ],
        const SizedBox(height: 16),

        // 3. Operating Since (Year)
        _buildFieldLabelWithOptional('OPERATING SINCE (YEAR)'),
        DropdownButtonFormField<String>(
          initialValue: _operatingSince.isEmpty ? null : _operatingSince,
          hint: const Text('Select starting year', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          items: [
            ...List.generate(27, (i) => 2026 - i).map((year) {
              final yr = year.toString();
              return DropdownMenuItem(value: yr, child: Text(yr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
            }),
            const DropdownMenuItem(value: 'Before 2000', child: Text('Before 2000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
          onChanged: (val) => setState(() => _operatingSince = val ?? ''),
          decoration: _buildDropdownDecoration(),
        ),
        const SizedBox(height: 16),

        // 4. Description / About Mess (Optional)
        _buildFieldLabelWithOptional('DESCRIPTION / ABOUT MESS'),
        TextFormField(
          initialValue: _description,
          minLines: 3,
          maxLines: 5,
          onChanged: (val) => setState(() => _description = val),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937), height: 1.4),
          decoration: _buildInputDecoration(
            hint: 'Tell students about your mess environment, special facilities, meals, or house rules...',
          ),
        ),
        const SizedBox(height: 16),

        // Terms & Consent Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x80FAF5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3E8FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _consent,
                  activeColor: const Color(0xFF300868),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _consent = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 3.0),
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
                      children: [
                        TextSpan(text: 'Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF300868))),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF300868))),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 5: SUCCESS CONFIRMATION (Matching MessRegistration.jsx)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Success() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 42, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Submission Received!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for registering your mess. Our team will verify the details and contact you at $_phoneNumber shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REUSABLE MICRO-COMPONENTS MATCHING WEBSITE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF374151),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFieldLabelWithOptional(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '(optional)',
            style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // Generic option buttons grid
  Widget _buildOptionGrid(List<String> options, String current, Function(String) onSelect, {int? columns}) {
    final cols = columns ?? (options.length <= 3 ? options.length : 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((cols - 1) * 8)) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = current == opt;
            return InkWell(
              onTap: () => onSelect(opt),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemWidth,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF300868) : const Color(0xFFF3F4F6),
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF300868).withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: -0.2,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? const Color(0xFF300868) : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Multi-choice grid (e.g. 1 Seater, 2 Seater)
  Widget _buildGridButtonChoices({
    required List<String> items,
    required int columns,
    required bool Function(String item) isSelected,
    required Function(String item) onTap,
    bool showCheck = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final selected = isSelected(item);
            return InkWell(
              onTap: () => onTap(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemWidth,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFAF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF300868) : const Color(0xFFF3F4F6),
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: const Color(0xFF300868).withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected && showCheck) ...[
                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFF300868)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? const Color(0xFF300868) : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 2x2 Grid for "Managed By" with subtitle (Owner -> Manager, etc.)
  Widget _buildManagedByGrid() {
    final list = [
      {'title': 'Owner', 'sub': 'Manager'},
      {'title': 'Students', 'sub': 'Self-managed'},
      {'title': 'Warden', 'sub': 'Supervised'},
      {'title': 'Nearby Canteen', 'sub': 'External'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((item) {
            final title = item['title']!;
            final sub = item['sub']!;
            final isSelected = _managedBy == title;
            return InkWell(
              onTap: () => setState(() => _managedBy = title),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemWidth,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF300868) : const Color(0xFFF3F4F6),
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF300868).withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF300868) : const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Yes / No segmented switch toggle (Wifi, CCTV, Inverter, Warden)
  Widget _buildYesNoToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF2F9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onChanged(true),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: value ? const Color(0xFF300868) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: value ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onChanged(false),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: !value ? const Color(0xFFE5E7EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: !value ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                      ),
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

  // Extra Space 2-column grid with custom square checkboxes
  Widget _buildExtraSpaceGrid() {
    final spaces = ['Parking', 'Access to Terrace', 'Dining Hall', 'Library'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: spaces.map((name) {
            final isChecked = _extraSpace.contains(name);
            return InkWell(
              onTap: () => _handleCheckboxToggle(_extraSpace, name),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemWidth,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFFFAF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF300868) : const Color(0xFFF3F4F6),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isChecked ? const Color(0xFF300868) : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isChecked ? const Color(0xFF300868) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isChecked ? const Color(0xFF300868) : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Consistent Input Decoration
  InputDecoration _buildInputDecoration({required String hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF300868)) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF300868), width: 2),
      ),
      counterText: '',
    );
  }

  InputDecoration _buildDropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF300868), width: 2),
      ),
    );
  }

  Widget _buildMonthsDropdown({
    required bool isEnabled,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final monthsList = List.generate(12, (i) => '${i + 1} Month${i > 0 ? 's' : ''}');
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: DropdownButtonFormField<String>(
        key: ValueKey('${isEnabled}_$value'),
        initialValue: monthsList.contains(value) ? value : '1 Month',
        items: monthsList.map((m) {
          return DropdownMenuItem<String>(
            value: m,
            child: Text(
              m,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEnabled ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              ),
            ),
          );
        }).toList(),
        onChanged: isEnabled ? onChanged : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: isEnabled ? Colors.white : const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isEnabled ? const Color(0xFFDDD6FE) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isEnabled ? const Color(0xFFDDD6FE) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF300868), width: 2),
          ),
        ),
      ),
    );
  }
}
