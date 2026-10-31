import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/analytics_tracker.dart';
import '../core/theme/app_theme.dart';
import '../data/models/mess_model.dart';
import '../data/models/room_model.dart';

class ContactOwnerDialog extends StatefulWidget {
  final MessModel mess;
  final List<RoomModel>? rooms;
  final String? initialOccupancy;
  final String? roomId;

  const ContactOwnerDialog({
    super.key,
    required this.mess,
    this.rooms,
    this.initialOccupancy,
    this.roomId,
  });

  static Future<void> show(
    BuildContext context, {
    required MessModel mess,
    List<RoomModel>? rooms,
    String? initialOccupancy,
    String? roomId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ContactOwnerDialog(
        mess: mess,
        rooms: rooms,
        initialOccupancy: initialOccupancy,
        roomId: roomId,
      ),
    );
  }

  @override
  State<ContactOwnerDialog> createState() => _ContactOwnerDialogState();
}

class _ContactOwnerDialogState extends State<ContactOwnerDialog> {
  String? selectedOccupancy;
  bool isConnecting = false;
  late final List<String> availableOccupancies;

  @override
  void initState() {
    super.initState();
    availableOccupancies = _computeOccupancies();

    if (widget.initialOccupancy != null && widget.initialOccupancy!.isNotEmpty) {
      final normalized = _normalizeOccupancy(widget.initialOccupancy);
      if (availableOccupancies.contains(normalized)) {
        selectedOccupancy = normalized;
      } else {
        selectedOccupancy = widget.initialOccupancy;
      }
    }
  }

  List<String> _computeOccupancies() {
    final List<String> list = [];
    if (widget.rooms != null && widget.rooms!.isNotEmpty) {
      for (final r in widget.rooms!) {
        final occ = _normalizeOccupancy(r.occupancy);
        if (occ.isNotEmpty && !list.contains(occ)) {
          list.add(occ);
        }
      }
    }

    if (list.isEmpty) {
      list.addAll(['1', '2', '3', '4']);
    }

    if (!list.contains('General Inquiry')) {
      list.add('General Inquiry');
    }
    return list;
  }

  static String _normalizeOccupancy(String? val) {
    if (val == null || val.trim().isEmpty) return '';
    final s = val.toLowerCase().trim();
    if (s == '1' || s == 'single' || s == '1 seater' || s == '1-seater' || s.contains('single')) return '1';
    if (s == '2' || s == 'double' || s == '2 seater' || s == '2-seater' || s.contains('double')) return '2';
    if (s == '3' || s == 'triple' || s == '3 seater' || s == '3-seater' || s.contains('triple')) return '3';
    if (s == '4' || s == 'four' || s == '4 seater' || s == '4-seater') return '4';
    if (s == '5' || s == 'five' || s == '5 seater' || s == '5-seater') return '5';
    if (s == '6' || s == 'six' || s == '6 seater' || s == '6-seater') return '6';
    if (s == '8' || s == 'eight' || s == '8 seater' || s == '8-seater') return '8';
    return val.trim();
  }

  Future<void> _handleCallNow() async {
    if (selectedOccupancy == null || isConnecting) return;
    setState(() {
      isConnecting = true;
    });

    try {
      // 1. Track conversion event in analytics
      AnalyticsTracker.instance.trackContactClick(
        'phone',
        widget.mess.id,
        messName: widget.mess.name,
        district: widget.mess.district,
      );

      // 2. Track booking record in Firestore
      final user = FirebaseAuth.instance.currentUser;
      final bookingData = {
        'userId': user?.uid ?? 'guest',
        'userName': user?.displayName ?? 'App User',
        'userPhone': user?.phoneNumber ?? 'N/A',
        'messId': widget.mess.id,
        'messName': widget.mess.name,
        'roomId': widget.roomId,
        'roomType': selectedOccupancy,
        'price': widget.mess.minPrice ?? 0,
        'rentCycle': 'monthly',
        'ownerPhone': widget.mess.contact,
        'status': 'contacted',
        'createdAt': FieldValue.serverTimestamp(),
      };

      FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData)
          .catchError((e) {
        debugPrint('Error recording booking: $e');
        return FirebaseFirestore.instance.collection('bookings').doc();
      });
    } catch (e) {
      debugPrint('Call tracking error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    // 3. Launch phone dialer
    final uri = Uri.parse('tel:${widget.mess.contact}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phone icon header
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), // emerald-50
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF10B981), // emerald-500
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'Contact Owner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Outfit',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text.rich(
                TextSpan(
                  text: 'You are about to call the owner of ',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Outfit',
                  ),
                  children: [
                    TextSpan(
                      text: widget.mess.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Warning / Instructions Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // amber-50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFD97706), // amber-600
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please keep in mind:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E), // amber-800
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildInstructionBullet('Introduce yourself politely'),
                          _buildInstructionBulletWithBold('Mention you found the mess on ', 'MessKhojo'),
                          _buildInstructionBullet("Be respectful of the owner's time"),
                          _buildInstructionBullet('Ask your queries clearly and patiently'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Property & Occupancy Selection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // gray-50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Name Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Property',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.mess.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                              fontFamily: 'Outfit',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),

                    // Occupancy prompt
                    const Text(
                      'WHICH OCCUPANCY ARE YOU CALLING FOR?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF374151),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Occupancy Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableOccupancies.map((occ) {
                        final isSelected = selectedOccupancy == occ;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedOccupancy = occ;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              occ,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF374151),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Red/amber helper text if unselected
                    if (selectedOccupancy == null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '* Please select an option above to proceed with the call.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF374151),
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Call Now button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (selectedOccupancy != null && !isConnecting)
                            ? _handleCallNow
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A), // green-600
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                          elevation: selectedOccupancy != null ? 3 : 0,
                          shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          shape: const StadiumBorder(),
                        ),
                        child: isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Call Now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB45309),
                fontFamily: 'Outfit',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBulletWithBold(String prefix, String boldPart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3)),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: prefix,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB45309),
                  fontFamily: 'Outfit',
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: boldPart,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
