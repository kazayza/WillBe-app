import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/profit_loss_model.dart';
import '../../theme/app_colors.dart';

class BranchesTab extends StatelessWidget {
  final BranchReportResponse? data;
  final bool isLoading;
  final VoidCallback onRetry;

  const BranchesTab({
    super.key,
    required this.data,
    required this.isLoading,
    required this.onRetry,
  });

  String _formatNumber(double number) {
    return NumberFormat('#,##0.00', 'ar').format(number);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('تحميل البيانات'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (data!.branches.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للفروع'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ════════════════════════════════════════
          // 🥧 Pie Chart - توزيع الإيرادات
          // ════════════════════════════════════════
          _buildPieChart(context),

          const SizedBox(height: 16),

          // ════════════════════════════════════════
          // 🏢 كروت الفروع
          // ════════════════════════════════════════
          ...data!.branches.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBranchCard(context, entry.value, entry.key),
            );
          }),

          const SizedBox(height: 12),

          // ════════════════════════════════════════
          // 📊 الإجمالي
          // ════════════════════════════════════════
          _buildTotalCard(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final branchesWithIncome =
        data!.branches.where((b) => b.totalIncome > 0).toList();

    if (branchesWithIncome.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.getCardDecoration(context),
      child: Column(
        children: [
          Text(
            'توزيع الإيرادات حسب الفروع',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: branchesWithIncome.asMap().entries.map((entry) {
                  final branch = entry.value;
                  final color = AppColors.getChartColor(entry.key);
                  final percentage =
                      (branch.totalIncome / data!.totals.totalIncome) * 100;

                  return PieChartSectionData(
                    color: color,
                    value: branch.totalIncome,
                    title: '${percentage.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: branchesWithIncome.asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.getChartColor(entry.key),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.value.branchName,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getText(context),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(
    BuildContext context,
    BranchData branch,
    int index,
  ) {
    final isProfit = branch.netProfit >= 0;
    final color = AppColors.getChartColor(index);

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
                Icon(Icons.business, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.branchName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isProfit ? 'ربح' : 'خسارة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // التفاصيل
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _branchDetailItem(
                    'الإيرادات',
                    branch.totalIncome,
                    AppColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.getBorder(context),
                ),
                Expanded(
                  child: _branchDetailItem(
                    'المصروفات',
                    branch.totalExpense,
                    AppColors.error,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.getBorder(context),
                ),
                Expanded(
                  child: _branchDetailItem(
                    'الصافي',
                    branch.netProfit,
                    isProfit ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'نسبة المصروفات من الإيرادات',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    Text(
                      branch.totalIncome > 0
                          ? '${((branch.totalExpense / branch.totalIncome) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: branch.totalIncome > 0
                        ? (branch.totalExpense / branch.totalIncome).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: AppColors.getBorder(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      branch.totalExpense / (branch.totalIncome > 0 ? branch.totalIncome : 1) > 0.8
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchDetailItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            _formatNumber(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    final isProfit = data!.totals.netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.error, const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'إجمالي جميع الفروع',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _totalItem('الإيرادات', data!.totals.totalIncome),
              ),
              Expanded(
                child: _totalItem('المصروفات', data!.totals.totalExpense),
              ),
              Expanded(
                child: _totalItem('الصافي', data!.totals.netProfit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalItem(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            _formatNumber(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}