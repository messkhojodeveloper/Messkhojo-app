import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/districts_config.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/inquiry_storage_helper.dart';
import '../../data/models/mess_model.dart';
import '../../providers/home_providers.dart';
import '../../widgets/past_suggestions_modal.dart';

class FindYourRoomScreen extends ConsumerStatefulWidget {
  const FindYourRoomScreen({super.key});

  @override
  ConsumerState<FindYourRoomScreen> createState() => _FindYourRoomScreenState();
}

class _FindYourRoomScreenState extends ConsumerState<FindYourRoomScreen> {
  int _step = 1;
  bool _isSubmitting = false;
  String _error = '';
  String _phoneError = '';

  // Form Fields
  String _gender = 'boys';
  String _city = '';
  String _location = '';
  String _budget = '';
  String _occupancy = '1-seater';
  String _expectedMoveIn = 'immediately';
  String _requirements = '';
  String _name = '';
  String _phone = '';
  String _whatsapp = '';
  bool _sameAsPhone = false;
  bool _consent = false;
  bool _alreadySubmittedToday = false;
  List<Map<String, dynamic>> _pastInquiries = [];

  final _formKeyStep3 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkRateLimitAndHistory();
  }

  Future<void> _checkRateLimitAndHistory() async {
    final submittedToday = await InquiryStorageHelper.hasSubmittedToday();
    final past = await InquiryStorageHelper.getPastInquiries();
    if (mounted) {
      setState(() {
        _alreadySubmittedToday = submittedToday;
        _pastInquiries = past;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> _getAvailableLandmarks(List<MessModel> messes) {
    if (_city.isEmpty) return [];
    final cityId = _city.toLowerCase();
    final landmarkSet = <String>{};

    for (final dist in DistrictsConfig.all.values) {
      for (final c in dist.cities) {
        if (c.id == cityId) {
          landmarkSet.addAll(dist.landmarks);
        }
      }
    }

    for (final mess in messes) {
      if (mess.city.toLowerCase() == cityId && mess.address.isNotEmpty) {
        landmarkSet.add(mess.address.trim());
      }
    }

    final sorted = landmarkSet.toList()..sort();
    return sorted;
  }

  void _nextStep() {
    setState(() => _error = '');

    if (_step == 1) {
      if (_city.isEmpty || _location.trim().isEmpty || _budget.isEmpty) {
        setState(() {
          _error = 'Please select your preferred city, area and budget to continue.';
        });
        return;
      }
    }

    if (_step < 3) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() {
        _step--;
        _error = '';
      });
    }
  }

  Future<void> _submitRequest() async {
    setState(() {
      _phoneError = '';
      _error = '';
    });

    // Anti-double-submit guard
    if (_isSubmitting) return;

    // Validate form fields (name + phone via Form validators)
    if (!(_formKeyStep3.currentState?.validate() ?? false)) return;

    // Strict Indian phone validation for the phone field
    final phoneValidationError = validateIndianPhone(_phone);
    if (phoneValidationError != null) {
      setState(() => _phoneError = phoneValidationError);
      return;
    }

    final calculatedWhatsapp = _sameAsPhone ? _phone.trim() : sanitizePhone(_whatsapp);
    final whatsappValidationError = validateIndianPhone(calculatedWhatsapp, fieldName: 'WhatsApp number');
    if (whatsappValidationError != null) {
      setState(() => _error = whatsappValidationError);
      return;
    }

    if (!_consent) {
      setState(() => _error = 'Please accept the Terms & Conditions and Privacy Policy.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestorePayload = {
        'name': _name.trim(),
        'phone': sanitizePhone(_phone),
        'whatsapp': calculatedWhatsapp,
        'city': _city,
        'location': _location.trim(),
        'budget': _budget,
        'gender': _gender,
        'occupancy': _occupancy,
        'expectedMoveIn': _expectedMoveIn,
        'requirements': _requirements.trim(),
        'consent': _consent,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      };

      await FirebaseFirestore.instance.collection('room_inquiries').add(firestorePayload);

      final localInquiryData = {
        'name': _name.trim(),
        'phone': sanitizePhone(_phone),
        'whatsapp': calculatedWhatsapp,
        'city': _city,
        'location': _location.trim(),
        'budget': _budget,
        'gender': _gender,
        'occupancy': _occupancy,
        'expectedMoveIn': _expectedMoveIn,
        'requirements': _requirements.trim(),
        'consent': _consent,
        'status': 'new',
      };

      // Save to local storage for rate limiting & past suggestions
      await InquiryStorageHelper.saveInquiry(localInquiryData);
      await _checkRateLimitAndHistory();

      HapticFeedback.mediumImpact();

      if (mounted) {
        context.push('/find-your-room/results', extra: localInquiryData);
      }
    } catch (e) {
      debugPrint('Error submitting inquiry: $e');
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messesAsync = ref.watch(messesStreamProvider);
    final messes = messesAsync.value ?? [];
    final landmarks = _getAvailableLandmarks(messes);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Find Your Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 18,
          ),
        ),
        // actions: removed history icon
      ),
      body: _alreadySubmittedToday
          ? _buildAlreadySubmittedTodayScreen()
          : _buildFormScreen(landmarks),
    );
  }

  // ─── ALREADY SUBMITTED TODAY SCREEN (RATE-LIMIT GATE) ─────────────────────

  Widget _buildAlreadySubmittedTodayScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFF59E0B), size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Already Submitted Today',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Outfit',
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "You've already submitted a Find Your Room request today. You can submit again tomorrow.",
              style: TextStyle(fontSize: 14, fontFamily: 'Outfit', color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Resets at midnight · One request per device per day',
              style: TextStyle(fontSize: 12, fontFamily: 'Outfit', color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                if (_pastInquiries.isNotEmpty)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        PastSuggestionsModal.show(context, _pastInquiries, _checkRateLimitAndHistory);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Past Suggestions (${_pastInquiries.length})'),
                    ),
                  ),
                if (_pastInquiries.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Home', style: TextStyle(color: Color(0xFF334155), fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_pastInquiries.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose from your past searches:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pastInquiries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _pastInquiries[index];
                        final inquiry = Map<String, dynamic>.from(item['inquiry'] as Map? ?? {});
                        final rawCity = inquiry['city'] as String? ?? '';
                        final city = rawCity.toLowerCase() == 'baleshwar' ? 'Balasore' : (rawCity.isNotEmpty ? rawCity[0].toUpperCase() + rawCity.substring(1) : '');
                        final location = inquiry['location'] as String? ?? '';
                        final gender = (inquiry['gender'] as String? ?? '').toUpperCase();
                        final occupancy = (inquiry['occupancy'] as String? ?? '').replaceAll('-seater', ' Seater');

                        return InkWell(
                          onTap: () {
                            context.push('/find-your-room/results', extra: inquiry);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$city${location.isNotEmpty ? ", $location" : ""}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Outfit',
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (gender.isNotEmpty)
                                            Text(
                                              '$gender • ',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                                            ),
                                          if (occupancy.isNotEmpty)
                                            Text(
                                              '$occupancy • ',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Outfit'),
                                            ),
                                          Text(
                                            '₹${inquiry["budget"] ?? ""}/mo',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      );
  }

  // ─── MAIN FORM SCREEN ────────────────────────────────────────────────────────

  Widget _buildFormScreen(List<String> landmarks) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),

          // Error banner
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Form card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 1
                      ? _buildStep1(landmarks)
                      : _step == 2
                          ? _buildStep2()
                          : _buildStep3(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── STEP INDICATOR ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          _buildStepBubble(1, 'Location'),
          _buildStepLine(1),
          _buildStepBubble(2, 'Details'),
          _buildStepLine(2),
          _buildStepBubble(3, 'Contact'),
        ],
      ),
    );
  }

  Widget _buildStepBubble(int step, String label) {
    final isDone = _step > step;
    final isActive = _step == step;
    return Expanded(
      flex: 0,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF10B981)
                  : isActive
                      ? AppTheme.primary
                      : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Outfit',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Outfit',
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.primary : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isCompleted = _step > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─── RADIO CARD ──────────────────────────────────────────────────────────────

  Widget _buildRadioCard(String field, String value, String label, IconData icon, String currentValue) {
    final isSelected = currentValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (field == 'gender') _gender = value;
            if (field == 'occupancy') _occupancy = value;
            if (field == 'expectedMoveIn') _expectedMoveIn = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF300868), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF9FAFB),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STEP 1 ──────────────────────────────────────────────────────────────────

  Widget _buildStep1(List<String> landmarks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'What are you looking for?', icon: Icons.search_rounded),
        const SizedBox(height: 20),

        _buildFieldLabel('Accommodation Type'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadioCard('gender', 'boys', 'Boys Mess', Icons.person_rounded, _gender),
            const SizedBox(width: 12),
            _buildRadioCard('gender', 'girls', 'Girls Mess', Icons.person_3_rounded, _gender),
          ],
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Preferred City'),
        const SizedBox(height: 8),
        _buildDropdown<String>(
          value: _city.isEmpty ? null : _city,
          hint: 'Select your city',
          items: DistrictsConfig.all.values
              .expand((dist) => dist.cities)
              .map((city) => DropdownMenuItem(value: city.id, child: Text(city.name, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (val) => setState(() {
            _city = val ?? '';
            _location = '';
          }),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Preferred Area / Landmark'),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (_city.isEmpty) return const Iterable<String>.empty();
            return landmarks.where((option) =>
                option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) => setState(() => _location = selection),
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != _location && _location.isEmpty) {
              textEditingController.text = _location;
            }
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: _city.isNotEmpty,
              onChanged: (val) => setState(() => _location = val),
              decoration: InputDecoration(
                hintText: _city.isNotEmpty ? 'e.g. Mansingh Bazar...' : 'Select a city first',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF9CA3AF)),
                fillColor: _city.isNotEmpty ? Colors.grey.shade50 : Colors.grey.shade100,
              ),
              style: const TextStyle(fontSize: 14),
            );
          },
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Rental Budget (monthly)'),
        const SizedBox(height: 8),
        _buildDropdown<String>(
          value: _budget.isEmpty ? null : _budget,
          hint: 'Select your maximum budget',
          items: const [
            DropdownMenuItem(value: '<2000', child: Text('Below ₹2,000/mo', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: '2000-3000', child: Text('₹2,000 – ₹3,000/mo', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: '3000-5000', child: Text('₹3,000 – ₹5,000/mo', style: TextStyle(fontSize: 14))),
            DropdownMenuItem(value: '5000+', child: Text('Above ₹5,000/mo', style: TextStyle(fontSize: 14))),
          ],
          onChanged: (val) => setState(() => _budget = val ?? ''),
        ),
        const SizedBox(height: 28),

        _buildNavRow(showBack: false),
      ],
    );
  }

  // ─── STEP 2 ──────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Room Details', icon: Icons.bed_rounded),
        const SizedBox(height: 20),

        _buildFieldLabel('Occupancy Preference'),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                _buildRadioCard('occupancy', '1-seater', '1 Seater', Icons.person_outline_rounded, _occupancy),
                const SizedBox(width: 10),
                _buildRadioCard('occupancy', '2-seater', '2 Seater', Icons.people_outline_rounded, _occupancy),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildRadioCard('occupancy', '3-seater', '3 Seater', Icons.group_outlined, _occupancy),
                const SizedBox(width: 10),
                _buildRadioCard('occupancy', 'any', 'Any', Icons.bed_outlined, _occupancy),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Expected Move-In'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadioCard('expectedMoveIn', 'immediately', 'Now', Icons.bolt_rounded, _expectedMoveIn),
            const SizedBox(width: 8),
            _buildRadioCard('expectedMoveIn', 'within-15-days', '15 Days', Icons.calendar_today_rounded, _expectedMoveIn),
            const SizedBox(width: 8),
            _buildRadioCard('expectedMoveIn', 'next-month', 'Next Month', Icons.next_plan_rounded, _expectedMoveIn),
          ],
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Any specific needs? (Optional)'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _requirements,
          maxLines: 3,
          onChanged: (val) => setState(() => _requirements = val),
          decoration: const InputDecoration(
            hintText: 'e.g. Need attached washroom, ground floor, cooking allowed...',
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 28),

        _buildNavRow(showBack: true),
      ],
    );
  }

  // ─── STEP 3 ──────────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'How can we reach you?', icon: Icons.phone_rounded),
          const SizedBox(height: 20),

          _buildFieldLabel('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _name,
            onChanged: (val) => setState(() => _name = val),
            decoration: const InputDecoration(
              hintText: 'e.g. Rahul Sharma',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
            ),
            style: const TextStyle(fontSize: 14),
            validator: (v) => validateName(v, fieldName: 'Full name'),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (val) {
              setState(() {
                _phone = val.replaceAll(RegExp(r'\D'), '');
                _phoneError = '';
                if (_sameAsPhone) {
                  _whatsapp = _phone;
                }
              });
            },
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixText: '+91 ',
              counterText: '',
              hintText: '10-digit mobile number',
              prefixIcon: const Icon(Icons.call_outlined, size: 20, color: Color(0xFF9CA3AF)),
              errorText: _phoneError.isNotEmpty ? _phoneError : null,
            ),
            style: const TextStyle(fontSize: 14),
            validator: (v) => validateIndianPhone(v),
          ),
          const SizedBox(height: 12),

          // Same as phone checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _sameAsPhone = !_sameAsPhone;
                if (_sameAsPhone) {
                  _whatsapp = _phone;
                }
              });
            },
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _sameAsPhone,
                    onChanged: (val) {
                      setState(() {
                        _sameAsPhone = val ?? true;
                        if (_sameAsPhone) {
                          _whatsapp = _phone;
                        }
                      });
                    },
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'WhatsApp number is same as Phone Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Outfit',
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dedicated WhatsApp field if not same
          if (!_sameAsPhone) ...[
            _buildFieldLabel('WhatsApp Number'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _whatsapp,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (val) {
                setState(() {
                  _whatsapp = val.replaceAll(RegExp(r'\D'), '');
                });
              },
              decoration: const InputDecoration(
                prefixText: '+91 ',
                counterText: '',
                hintText: '10-digit WhatsApp number',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF10B981)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14),
              validator: (v) => validateIndianPhone(v, fieldName: 'WhatsApp number'),
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 12),

          // Consent
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _consent ? const Color(0xFFF3F0FF) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _consent ? const Color(0xFFDDD6FE) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consent,
                  onChanged: (val) => setState(() => _consent = val ?? false),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _consent = !_consent),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5, fontFamily: 'Outfit'),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/terms'),
                                child: const Text('Terms & Conditions',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Outfit',
                                    )),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push('/privacy'),
                                child: const Text('Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Outfit',
                                    )),
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
          ),
          const SizedBox(height: 24),

          _buildNavRow(showBack: true, isLastStep: true),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNavRow({required bool showBack, bool isLastStep = false}) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                foregroundColor: const Color(0xFF4B5563),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: showBack ? 2 : 1,
          child: ElevatedButton(
            onPressed: isLastStep
                ? (_isSubmitting || !_consent ? null : () {
                    if (_formKeyStep3.currentState!.validate()) {
                      _submitRequest();
                    }
                  })
                : _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isLastStep ? Icons.send_rounded : Icons.arrow_forward_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(isLastStep ? 'Submit Request' : 'Next Step'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── HELPER WIDGET ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
