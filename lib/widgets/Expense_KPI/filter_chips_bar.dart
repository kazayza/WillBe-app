import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';

class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasActiveFilters) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // فلتر الفرع
                if (provider.selectedBranchName != null)
                  _buildChip(
                    label: '🏢 ${provider.selectedBranchName}',
                    color: const Color(0xFF2C3E50),
                    onRemove: () => provider.clearBranch(),
                  ),

                // فلتر المجموعة
                if (provider.selectedGroupName != null)
                  _buildChip(
                    label: '📂 ${provider.selectedGroupName}',
                    color: const Color(0xFF3498DB),
                    onRemove: () => provider.clearGroup(),
                  ),

                // فلتر النوع
                if (provider.selectedKindName != null)
                  _buildChip(
                    label: '📋 ${provider.selectedKindName}',
                    color: const Color(0xFF27AE60),
                    onRemove: () => provider.clearKind(),
                  ),

                // زر مسح الكل
                if (provider.activeFiltersCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ActionChip(
                      label: const Text(
                        'مسح الكل',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      onPressed: () => provider.clearAllFilters(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: color,
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: Colors.white,
        ),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}