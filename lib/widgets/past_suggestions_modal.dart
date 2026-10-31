import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/inquiry_storage_helper.dart';

class PastSuggestionsModal extends StatefulWidget {
  final List<Map<String, dynamic>> pastInquiries;
  final VoidCallback onUpdated;

  const PastSuggestionsModal({
    super.key,
    required this.pastInquiries,
    required this.onUpdated,
  });

  static void show(BuildContext context, List<Map<String, dynamic>> pastInquiries, VoidCallback onUpdated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PastSuggestionsModal(
        pastInquiries: pastInquiries,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<PastSuggestionsModal> createState() => _PastSuggestionsModalState();
}

class _PastSuggestionsModalState extends State<PastSuggestionsModal> {
  late List<Map<String, dynamic>> _inquiries;

  @override
  void initState() {
    super.initState();
    _inquiries = List.from(widget.pastInquiries);
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final d = DateTime.parse(isoString).toLocal();
      return DateFormat('d MMM y, h:mm a').format(d);
    } catch (_) {
      return '';
    }
  }

  String _formatCity(String? cityId) {
    if (cityId == null || cityId.isEmpty) return '';
    if (cityId.toLowerCase() == 'baleshwar') return 'Balasore';
    return cityId[0].toUpperCase() + cityId.substring(1);
  }

  Future<void> _deleteItem(int index) async {
    await InquiryStorageHelper.deleteInquiryItem(index);
    setState(() {
      _inquiries.removeAt(index);
    });
    widget.onUpdated();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History?', style: TextStyle(fontFamily: 'Outfit')),
        content: const Text('Are you sure you want to clear all your past room search history?', style: TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await InquiryStorageHelper.clearAllInquiries();
      setState(() {
        _inquiries.clear();
      });
      widget.onUpdated();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Modal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Past Room Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Your previous room match requests (${_inquiries.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_inquiries.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Clear All', style: TextStyle(fontSize: 12, fontFamily: 'Outfit')),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Items List
          Expanded(
            child: _inquiries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded, size: 32, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Past Requests Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Once you submit a room inquiry, it will appear here.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontFamily: 'Outfit'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inquiries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _inquiries[index];
                      final inquiry = Map<String, dynamic>.from(item['inquiry'] as Map? ?? {});
                      final submittedAt = item['submittedAt'] as String?;

                      final city = _formatCity(inquiry['city'] as String?);
                      final location = inquiry['location'] as String? ?? '';
                      final gender = (inquiry['gender'] as String? ?? '').toUpperCase();
                      final occupancy = (inquiry['occupancy'] as String? ?? '').replaceAll('-seater', ' Seater');
                      final budget = inquiry['budget'] as String? ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/find-your-room/results', extra: inquiry);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date
                                    Text(
                                      _formatDate(submittedAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Location & Gender badges
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          city + (location.isNotEmpty ? ', $location' : ''),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Outfit',
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (gender.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F0FF),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              gender,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                          ),
                                        if (occupancy.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              occupancy,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4B5563),
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Budget label
                                    if (budget.isNotEmpty)
                                      Text(
                                        'Budget: ₹$budget/mo',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                          fontFamily: 'Outfit',
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Delete button & right arrow
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
                                onPressed: () => _deleteItem(index),
                                tooltip: 'Delete search',
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
