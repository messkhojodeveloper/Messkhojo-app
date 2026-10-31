import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/services/analytics_tracker.dart';
import '../../../data/models/mess_model.dart';
import '../../../data/models/room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/inquiry_provider.dart';

class InquiryBottomSheet extends ConsumerStatefulWidget {
  final MessModel? mess;
  final RoomModel? room;
  const InquiryBottomSheet({super.key, this.mess, this.room});

  @override
  ConsumerState<InquiryBottomSheet> createState() => _InquiryBottomSheetState();
}

class _InquiryBottomSheetState extends ConsumerState<InquiryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedSeating = 'Any';
  bool _consentChecked = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-select seating from room occupancy if provided
    if (widget.room != null) {
      final occVal = widget.room!.occupancy;
      if (occVal == '1' || occVal.startsWith('1')) {
        _selectedSeating = '1 Seater';
      } else if (occVal == '2' || occVal.startsWith('2')) {
        _selectedSeating = '2 Seater';
      } else if (occVal == '3' || occVal.startsWith('3')) {
        _selectedSeating = '3 Seater';
      } else {
        _selectedSeating = 'Any';
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        _nameController.text = profile.name;
        if (profile.phone != null) {
          _phoneController.text = profile.phone!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to proceed.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // Anti-double-tap guard
    if (_submitting) return;

    setState(() { _submitting = true; });

    try {
      // 1. Save to firestore collection via repository
      final targetMessId = widget.mess?.id ?? widget.room?.messId ?? '';
      await ref.read(inquiryRepositoryProvider).submitInquiry(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            seating: _selectedSeating,
            consent: _consentChecked,
            messId: targetMessId,
            messName: widget.mess?.name ?? '',
          );

      // Track inquiry submission & booking attempt across GA4 & Sentry
      AnalyticsTracker.instance.trackBookingInitiated(
        widget.room?.id ?? 'general_inquiry',
        targetMessId,
        price: widget.room?.price.toDouble() ?? widget.mess?.minPrice?.toDouble(),
        messName: widget.mess?.name,
      );
      AnalyticsTracker.instance.trackContactClick(
        'whatsapp_inquiry',
        targetMessId,
        messName: widget.mess?.name,
        district: widget.mess?.district,
      );

      // 2. Prepare WhatsApp message
      final messName = widget.mess?.name ?? 'a mess';
      final message = '* Inquiry for $messName *\n\n'
          'Hello Mess Khojo, I am ${_nameController.text.trim()}. '
          'I am looking for a ${_selectedSeating == 'Any' ? 'room' : '$_selectedSeating room'} in * $messName*.\n\n'
          'My contact: ${_phoneController.text.trim()}\n\n'
          'Please help me with seat availability and details.';

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = Uri.parse('https://wa.me/919692819621?text=$encodedMessage');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp automatically. Your inquiry was saved!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit inquiry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shift content up when keyboard is visible
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 24.0,
        bottom: 24.0 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check Availability',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connect directly with the owner',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textGray),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Your Name field
              const Text(
                'YOUR NAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textGray),
                ),
                validator: (value) => validateName(value, fieldName: 'Your name'),
                onChanged: (v) {
                  // strip leading/trailing whitespace on each change for cleaner state
                },
              ),
              const SizedBox(height: 16),

              // Phone Number field
              const Text(
                'PHONE NUMBER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: const InputDecoration(
                  hintText: '10-digit Indian mobile number',
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textGray),
                ),
                validator: (value) => validateIndianPhone(value, fieldName: 'Phone number'),
              ),
              const SizedBox(height: 16),

              // Looking for (Seater) Dropdown
              const Text(
                'LOOKING FOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeating,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.bed_outlined, color: AppTheme.textGray),
                ),
                items: const [
                  DropdownMenuItem(value: 'Any', child: Text('Any Room Type')),
                  DropdownMenuItem(value: '1 Seater', child: Text('1 Seater (Single)')),
                  DropdownMenuItem(value: '2 Seater', child: Text('2 Seater (Double)')),
                  DropdownMenuItem(value: '3 Seater', child: Text('3 Seater (Triple)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSeating = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _consentChecked,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _consentChecked = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                                context.push('/terms');
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                                context.push('/privacy');
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: (_consentChecked && !_submitting) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Submit Inquiry'),
                          SizedBox(width: 8),
                          Icon(Icons.send, size: 16),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
