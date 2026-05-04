import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class FilterSection extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String selectedBranchId;
  final int selectedYear;
  final int currentTabIndex;
  final Function({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    int? year,
  }) onFilterChanged;

  const FilterSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedBranchId,
    required this.selectedYear,
    required this.currentTabIndex,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: AppColors.getCardDecoration(context),
      child: Column(
        children: [
          // الصف الأول: التواريخ
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context: context,
                  label: 'من',
                  date: startDate,
                  onTap: () => _pickDate(context, isStart: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  context: context,
                  label: 'إلى',
                  date: endDate,
                  onTap: () => _pickDate(context, isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // الصف الثاني: اختصارات سريعة
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickFilter(context, 'هذا الشهر', () {
                  final now = DateTime.now();
                  onFilterChanged(
                    startDate: DateTime(now.year, now.month, 1),
                    endDate: now,
                  );
                }),
                _buildQuickFilter(context, 'الشهر السابق', () {
                  final now = DateTime.now();
                  final prevMonth = DateTime(now.year, now.month - 1, 1);
                  final lastDay = DateTime(now.year, now.month, 0);
                  onFilterChanged(startDate: prevMonth, endDate: lastDay);
                }),
                _buildQuickFilter(context, 'ربع سنوي', () {
                  final now = DateTime.now();
                  final quarterStart = DateTime(
                    now.year,
                    ((now.month - 1) ~/ 3) * 3 + 1,
                    1,
                  );
                  onFilterChanged(startDate: quarterStart, endDate: now);
                }),
                _buildQuickFilter(context, 'نصف سنوي', () {
                  final now = DateTime.now();
                  final halfStart = now.month <= 6
                      ? DateTime(now.year, 1, 1)
                      : DateTime(now.year, 7, 1);
                  onFilterChanged(startDate: halfStart, endDate: now);
                }),
                _buildQuickFilter(context, 'هذا العام', () {
                  final now = DateTime.now();
                  onFilterChanged(
                    startDate: DateTime(now.year, 1, 1),
                    endDate: now,
                  );
                }),
                _buildQuickFilter(context, 'العام السابق', () {
                  final now = DateTime.now();
                  onFilterChanged(
                    startDate: DateTime(now.year - 1, 1, 1),
                    endDate: DateTime(now.year - 1, 12, 31),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.getBg(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final DateTime initialDate = isStart ? startDate : endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.getCard(context),
              onSurface: AppColors.getText(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        onFilterChanged(startDate: picked);
      } else {
        onFilterChanged(endDate: picked);
      }
    }
  }
}