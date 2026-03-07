import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';
import 'kpi_theme.dart';

class PeriodFilterBar extends StatelessWidget {
  const PeriodFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KPITheme.of(context);

    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: theme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                children: [
                  Icon(Icons.date_range, color: theme.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الفترة الزمنية',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // أزرار الفترات
              Row(
                children: [
                  _buildPeriodButton(
                    context: context,
                    label: 'شهري',
                    value: 'month',
                    icon: Icons.calendar_today,
                    provider: provider,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodButton(
                    context: context,
                    label: 'ربع سنوي',
                    value: 'quarter',
                    icon: Icons.date_range,
                    provider: provider,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodButton(
                    context: context,
                    label: 'سنوي',
                    value: 'year',
                    icon: Icons.calendar_month,
                    provider: provider,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodButton(
                    context: context,
                    label: 'مخصص',
                    value: 'custom',
                    icon: Icons.tune,
                    provider: provider,
                    theme: theme,
                  ),
                ],
              ),

              // عرض الفترة المخصصة
              if (provider.selectedPeriodType == 'custom')
                _buildCustomDatePicker(context, provider, theme),

              // ✅ عرض فترات المقارنة بوضوح
              if (provider.hasData) _buildComparisonInfo(provider, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodButton({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required ExpensesKPIProvider provider,
    required KPITheme theme,
  }) {
    final isSelected = provider.selectedPeriodType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (value == 'custom') {
            _selectCustomDates(context, provider);
          } else {
            provider.setPeriodType(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.info : theme.sectionBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.info : theme.divider,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : theme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ✅ عرض فترات المقارنة بوضوح
  // ════════════════════════════════════════════════════════════
  Widget _buildComparisonInfo(ExpensesKPIProvider provider, KPITheme theme) {
    final dates = provider.kpiData!.dates;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.sectionBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        children: [
          // الفترة الحالية
          _buildPeriodRow(
            icon: Icons.circle,
            iconColor: theme.info,
            label: 'الفترة الحالية',
            dateRange: _formatDateRange(dates.current.start, dates.current.end),
            days: '${dates.current.days} يوم',
            theme: theme,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: theme.divider, height: 1),
          ),

          // فترة المقارنة (السابقة)
          _buildPeriodRow(
            icon: Icons.circle,
            iconColor: theme.warning,
            label: 'مقارنة بالسابق',
            dateRange: _formatDateRange(dates.previous.start, dates.previous.end),
            days: '${dates.previous.days} يوم',
            theme: theme,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: theme.divider, height: 1),
          ),

          // فترة المقارنة (العام السابق)
          _buildPeriodRow(
            icon: Icons.circle,
            iconColor: theme.purple,
            label: 'مقارنة بالعام السابق',
            dateRange: _formatDateRange(dates.lastYear.start, dates.lastYear.end),
            days: '${dates.lastYear.days} يوم',
            theme: theme,
          ),

          const SizedBox(height: 8),

          // مؤشر عدالة المقارنة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dates.meta.fairComparison
                  ? theme.positiveLight
                  : theme.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  dates.meta.fairComparison
                      ? Icons.check_circle
                      : Icons.info,
                  size: 14,
                  color: dates.meta.fairComparison
                      ? theme.positive
                      : theme.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  dates.meta.fairComparison
                      ? 'مقارنة عادلة ✅ (نفس عدد الأيام)'
                      : 'تنبيه: فترات المقارنة مختلفة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: dates.meta.fairComparison
                        ? theme.positive
                        : theme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String dateRange,
    required String days,
    required KPITheme theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 8, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                dateRange,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            days,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📅 اختيار فترة مخصصة - مع إصلاح الخطأ
  // ════════════════════════════════════════════════════════════
  Future<void> _selectCustomDates(
    BuildContext context,
    ExpensesKPIProvider provider,
  ) async {
    try {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: provider.customStartDate != null &&
                provider.customEndDate != null
            ? DateTimeRange(
                start: provider.customStartDate!,
                end: provider.customEndDate!,
              )
            : DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2C3E50),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF2C3E50),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        provider.setCustomDates(picked.start, picked.end);
      }
    } catch (e) {
      debugPrint('Error selecting dates: $e');
    }
  }

  Widget _buildCustomDatePicker(
    BuildContext context,
    ExpensesKPIProvider provider,
    KPITheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.sectionBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateBox(
              label: 'من',
              date: provider.customStartDate,
              onTap: () => _selectCustomDates(context, provider),
              theme: theme,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: theme.textSecondary),
          ),
          Expanded(
            child: _buildDateBox(
              label: 'إلى',
              date: provider.customEndDate,
              onTap: () => _selectCustomDates(context, provider),
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required KPITheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.divider),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'اختر التاريخ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: date != null ? theme.textPrimary : theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    return '${start.day}/${start.month}/${start.year} → ${end.day}/${end.month}/${end.year}';
  }
}