import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class KpiComparisonTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const KpiComparisonTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final current = data['current'] ?? {};
    final previous = data['previous'] ?? {};
    final changes = data['changes'] ?? {};
    final currency = NumberFormat('#,###', 'ar_EG');

    final rows = [
      _ComparisonRow(
        title: 'إجمالي الإيرادات',
        icon: Icons.attach_money,
        currentValue: currency.format(current['totalAmount'] ?? 0),
        previousValue: currency.format(previous['totalAmount'] ?? 0),
        change: changes['totalAmount']?.toDouble(),
        suffix: 'ج.م',
      ),
      _ComparisonRow(
        title: 'عدد العمليات',
        icon: Icons.receipt_long,
        currentValue: '${current['transactions'] ?? 0}',
        previousValue: '${previous['transactions'] ?? 0}',
        change: changes['transactions']?.toDouble(),
        suffix: 'عملية',
      ),
      _ComparisonRow(
        title: 'متوسط العملية',
        icon: Icons.analytics,
        currentValue: currency.format(current['avgAmount'] ?? 0),
        previousValue: currency.format(previous['avgAmount'] ?? 0),
        change: changes['avgAmount']?.toDouble(),
        suffix: 'ج.م',
      ),
      _ComparisonRow(
        title: 'أعلى عملية',
        icon: Icons.arrow_circle_up,
        currentValue: currency.format(current['maxAmount'] ?? 0),
        previousValue: currency.format(previous['maxAmount'] ?? 0),
        change: changes['maxAmount']?.toDouble(),
        suffix: 'ج.م',
      ),
    ];

    return Container(
      decoration: AppColors.getCardDecoration(isDark),
      child: Column(
        children: [
          // ─────────────────────────────────────────────────
          // العنوان
          // ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'مقارنة الفترات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.getText(isDark),
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────
          // Header Row
          // ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'المؤشر',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الحالي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'السابق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    'التغيير',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────
          // Data Rows
          // ─────────────────────────────────────────────────
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isLast = index == rows.length - 1;

            return _buildRow(row, isDark, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(_ComparisonRow row, bool isDark, bool isLast) {
    final isPositive = (row.change ?? 0) >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.getBorder(isDark),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // ─────────────────────────────────────────────────
          // المؤشر
          // ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    row.icon,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.title,
                    style: TextStyle(
                      color: AppColors.getText(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────
          // القيمة الحالية
          // ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              row.currentValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getText(isDark),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ─────────────────────────────────────────────────
          // القيمة السابقة
          // ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              row.previousValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ─────────────────────────────────────────────────
          // نسبة التغيير
          // ─────────────────────────────────────────────────
          SizedBox(
            width: 65,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 10,
                    color: changeColor,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${row.change?.abs().toStringAsFixed(1) ?? '0'}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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

// ══════════════════════════════════════════════════════════════
// 📊 نموذج صف المقارنة
// ══════════════════════════════════════════════════════════════
class _ComparisonRow {
  final String title;
  final IconData icon;
  final String currentValue;
  final String previousValue;
  final double? change;
  final String suffix;

  _ComparisonRow({
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.previousValue,
    this.change,
    this.suffix = '',
  });
}