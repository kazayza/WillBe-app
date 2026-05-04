import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/profit_loss_model.dart';
import '../../theme/app_colors.dart';

class MonthlyTab extends StatelessWidget {
  final MonthlyTrendResponse? data;
  final bool isLoading;
  final VoidCallback onRetry;

  const MonthlyTab({
    super.key,
    required this.data,
    required this.isLoading,
    required this.onRetry,
  });

  String _formatNumber(double number) {
    return NumberFormat('#,##0', 'ar').format(number);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ════════════════════════════════════════
          // 📊 الرسم البياني
          // ════════════════════════════════════════
          _buildChart(context),

          const SizedBox(height: 8),

          // Legend
          _buildLegend(context),

          const SizedBox(height: 16),

          // ════════════════════════════════════════
          // 📋 الجدول
          // ════════════════════════════════════════
          _buildDataTable(context),

          const SizedBox(height: 12),

          // ════════════════════════════════════════
          // 📊 الإجماليات
          // ════════════════════════════════════════
          _buildTotalsCard(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final maxVal = data!.months.fold<double>(0, (max, m) {
      final highest = [m.income, m.expense, m.netProfit.abs()].reduce(
        (a, b) => a > b ? a : b,
      );
      return highest > max ? highest : max;
    });

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.getCardDecoration(context),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = data!.months[group.x.toInt()];
                String label;
                switch (rodIndex) {
                  case 0:
                    label = 'إيرادات: ${_formatNumber(month.income)}';
                    break;
                  case 1:
                    label = 'مصروفات: ${_formatNumber(month.expense)}';
                    break;
                  default:
                    label = 'ربح: ${_formatNumber(month.netProfit)}';
                }
                return BarTooltipItem(
                  label,
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final months = [
                    'ين', 'فب', 'مر', 'أب', 'ما', 'يو',
                    'يل', 'أغ', 'سب', 'أك', 'نو', 'دي',
                  ];
                  if (value.toInt() < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        months[value.toInt()],
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCompact(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.getTextSecondary(context),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.getBorder(context),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data!.months.asMap().entries.map((entry) {
            final index = entry.key;
            final month = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: month.income,
                  color: AppColors.success,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: month.expense,
                  color: AppColors.error,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: month.netProfit.abs(),
                  color: month.netProfit >= 0
                      ? AppColors.primary
                      : AppColors.warning,
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('إيرادات', AppColors.success),
        const SizedBox(width: 16),
        _legendItem('مصروفات', AppColors.error),
        const SizedBox(width: 16),
        _legendItem('صافي', AppColors.primary),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return Container(
      decoration: AppColors.getCardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('الشهر', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإيرادات', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المصروفات', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الصافي', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: data!.months.map((month) {
            return DataRow(
              cells: [
                DataCell(Text(month.monthName, style: const TextStyle(fontSize: 12))),
                DataCell(Text(
                  _formatNumber(month.income),
                  style: const TextStyle(fontSize: 12, color: AppColors.success),
                )),
                DataCell(Text(
                  _formatNumber(month.expense),
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                )),
                DataCell(Text(
                  _formatNumber(month.netProfit),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: month.netProfit >= 0 ? AppColors.success : AppColors.error,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'إجمالي العام ${data!.year}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _totalItem('الإيرادات', data!.totals.income, AppColors.success),
              ),
              Expanded(
                child: _totalItem('المصروفات', data!.totals.expense, AppColors.error),
              ),
              Expanded(
                child: _totalItem(
                  'الصافي',
                  data!.totals.netProfit,
                  data!.totals.netProfit >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            _formatNumber(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}