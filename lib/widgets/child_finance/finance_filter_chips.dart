import 'package:flutter/material.dart';
import '../../theme/finance_theme.dart';

class FinanceFilterChips extends StatelessWidget {
  final String title;
  final List<FinanceChipItem> items;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool showTitle;

  const FinanceFilterChips({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: FinanceTheme.textSec(context), fontSize: 11.5, letterSpacing: 0.2)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 6, runSpacing: 6,
          children: items.map((item) {
            final isSelected = selectedValue == item.value;
            return GestureDetector(
              onTap: () => onChanged(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? FinanceTheme.primary : FinanceTheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? FinanceTheme.primary : FinanceTheme.border.withValues(alpha: 0.5)),
                  boxShadow: isSelected ? [BoxShadow(color: FinanceTheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))] : null,
                ),
                child: Text(
                  item.count != null ? '${item.label} (${item.count})' : item.label,
                  style: TextStyle(color: isSelected ? Colors.white : FinanceTheme.text(context), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 12.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class FinanceChipItem {
  final String value;
  final String label;
  final int? count;
  FinanceChipItem({required this.value, required this.label, this.count});
}