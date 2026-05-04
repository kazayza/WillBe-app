import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/profit_loss_model.dart';
import '../../theme/app_colors.dart';

class SummaryCards extends StatelessWidget {
  final SummaryData summary;

  const SummaryCards({super.key, required this.summary});

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'ar').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // الصف الأول: إيرادات - مصروفات - صافي
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context: context,
                  title: 'الإيرادات',
                  amount: summary.totalIncome,
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  context: context,
                  title: 'المصروفات',
                  amount: summary.totalExpenses,
                  icon: Icons.trending_down,
                  color: AppColors.error,
                  bgColor: AppColors.errorLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  context: context,
                  title: 'صافي الربح',
                  amount: summary.netProfit,
                  icon: summary.netProfit >= 0
                      ? Icons.emoji_events
                      : Icons.warning,
                  color: summary.netProfit >= 0
                      ? AppColors.primary
                      : AppColors.error,
                  bgColor: summary.netProfit >= 0
                      ? AppColors.infoLight
                      : AppColors.errorLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // الصف الثاني: هامش الربح - الربح التشغيلي
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context: context,
                  title: 'هامش الربح',
                  amount: summary.profitMargin,
                  icon: Icons.pie_chart,
                  color: AppColors.warning,
                  bgColor: AppColors.warningLight,
                  isCurrency: false,
                  suffix: '%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  context: context,
                  title: 'الربح التشغيلي',
                  amount: summary.operatingProfit,
                  icon: Icons.settings,
                  color: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isCurrency = true,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              isCurrency
                  ? _formatNumber(amount)
                  : '${amount.toStringAsFixed(1)}${suffix ?? ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}