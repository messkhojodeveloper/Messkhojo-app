import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategorySwitcher extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CategorySwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> categories = ['All', 'Boys', 'Girls'];
    final Color brandPurple = AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: categories.map((type) {
          final isActive = (selected.isEmpty && type == 'All') ||
              selected == type ||
              (type == 'All' && selected.isEmpty);
          return GestureDetector(
            onTap: () => onChanged(type == 'All' ? '' : type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? brandPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}