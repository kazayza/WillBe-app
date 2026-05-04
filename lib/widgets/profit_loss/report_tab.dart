import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/profit_loss_model.dart';
import '../../theme/app_colors.dart';

class ReportTab extends StatelessWidget {
  final ProfitLossReport? report;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const ReportTab({
    super.key,
    required this.report,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'ar').format(number);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل التقرير...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (report == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ════════════════════════════════════════
          // 📈 الإيرادات التشغيلية
          // ════════════════════════════════════════
          _buildSectionCard(
            context: context,
            title: 'الإيرادات التشغيلية',
            icon: Icons.trending_up,
            color: AppColors.success,
            items: report!.income.operational.items,
            total: report!.income.operational.total,
          ),

          const SizedBox(height: 12),

          // ════════════════════════════════════════
          // 📈 إيرادات أخرى
          // ════════════════════════════════════════
          _buildSectionCard(
            context: context,
            title: 'إيرادات أخرى',
            icon: Icons.add_circle_outline,
            color: const Color(0xFF6366F1),
            items: report!.income.other.items,
            total: report!.income.other.total,
          ),

          const SizedBox(height: 8),

          // ════════════════════════════════════════
          // 💵 إجمالي الإيرادات
          // ════════════════════════════════════════
          _buildTotalRow(
            context: context,
            title: 'إجمالي الإيرادات',
            amount: report!.income.grandTotal,
            color: AppColors.success,
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.getBorder(context), thickness: 2),
          const SizedBox(height: 16),

          // ════════════════════════════════════════
          // 👥 الرواتب والأجور
          // ════════════════════════════════════════
          _buildSectionCard(
            context: context,
            title: 'الرواتب والأجور',
            icon: Icons.people,
            color: AppColors.error,
            items: report!.expenses.salaries.items,
            total: report!.expenses.salaries.total,
          ),

          const SizedBox(height: 12),

          // ════════════════════════════════════════
          // 🏢 مصروفات تشغيلية
          // ════════════════════════════════════════
          _buildSectionCard(
            context: context,
            title: 'مصروفات تشغيلية',
            icon: Icons.settings,
            color: AppColors.warning,
            items: report!.expenses.operational.items,
            total: report!.expenses.operational.total,
          ),

          const SizedBox(height: 12),

          // ════════════════════════════════════════
          // ⚠️ مصروفات غير تشغيلية
          // ════════════════════════════════════════
          if (report!.expenses.nonOperational.items.isNotEmpty)
            _buildSectionCard(
              context: context,
              title: 'مصروفات غير تشغيلية',
              icon: Icons.warning_amber,
              color: const Color(0xFF9C27B0),
              items: report!.expenses.nonOperational.items,
              total: report!.expenses.nonOperational.total,
            ),

          const SizedBox(height: 8),

          // ════════════════════════════════════════
          // 💸 إجمالي المصروفات
          // ════════════════════════════════════════
          _buildTotalRow(
            context: context,
            title: 'إجمالي المصروفات',
            amount: report!.expenses.grandTotal,
            color: AppColors.error,
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.getBorder(context), thickness: 2),
          const SizedBox(height: 16),

          // ════════════════════════════════════════
          // 💰 صافي الربح / الخسارة
          // ════════════════════════════════════════
          _buildNetProfitCard(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // 🔧 Widgets المساعدة
  // ════════════════════════════════════════

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<GroupItem> items,
    required double total,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: AppColors.getCardDecoration(context),
      child: Column(
        children: [
          // العنوان
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  _formatNumber(total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // العناصر
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.getBorder(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getText(context),
                      ),
                    ),
                  ),
                  Text(
                    _formatNumber(item.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(context),
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

  Widget _buildTotalRow({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            _formatNumber(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard(BuildContext context) {
    final isProfit = report!.summary.netProfit >= 0;
    final color = isProfit ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isProfit ? Icons.emoji_events : Icons.warning,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            isProfit ? 'صافي الربح' : 'صافي الخسارة',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatNumber(report!.summary.netProfit.abs()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'هامش الربح: ${report!.summary.profitMargin.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}