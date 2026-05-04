import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/finance_theme.dart';
import '../../models/finance_session_details_model.dart';

class FinanceSummarySection extends StatelessWidget {
  final FinanceRecordsSummary summary;
  const FinanceSummarySection({super.key, required this.summary});

  String _formatNumber(double value) => NumberFormat('#,##0.##', 'ar').format(value);
  String _formatDate(DateTime? date) => date == null ? '—' : DateFormat('yyyy/MM/dd', 'ar').format(date);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الصف الأول: بطاقتان كبيرتان
        Row(
          children: [
            _buildLargeStat(context, label: 'إجمالي الاشتراكات', value: _formatNumber(summary.totalAmount), icon: Icons.account_balance_wallet_rounded, color: FinanceTheme.primary),
            const SizedBox(width: 12),
            _buildLargeStat(context, label: 'متوسط الاشتراك', value: _formatNumber(summary.averageAmount), icon: Icons.trending_up_rounded, color: FinanceTheme.accent),
          ],
        ),
        const SizedBox(height: 12),
        // الصف الثاني: 3 بطاقات صغيرة
        Row(
          children: [
            _buildSmallStat(context, label: 'أطفال', value: '${summary.uniqueChildrenCount}', icon: Icons.child_care_rounded, color: FinanceTheme.success),
            const SizedBox(width: 10),
            _buildSmallStat(context, label: 'سجلات', value: '${summary.recordsCount}', icon: Icons.receipt_long_rounded, color: FinanceTheme.info),
            const SizedBox(width: 10),
            _buildSmallStat(context, label: 'آخر التزام', value: _formatDate(summary.lastSubDate), icon: Icons.update_rounded, color: FinanceTheme.primary, isDate: true),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeStat(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Expanded(child: Text(label, style: TextStyle(fontSize: 11.5, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)))]),
            const SizedBox(height: 12),
            FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FinanceTheme.text(context), letterSpacing: -0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(BuildContext context, {required String label, required String value, required IconData icon, required Color color, bool isDate = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: TextStyle(fontSize: isDate ? 12 : 17, fontWeight: isDate ? FontWeight.w700 : FontWeight.w900, color: FinanceTheme.text(context), letterSpacing: isDate ? 0 : -0.3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}