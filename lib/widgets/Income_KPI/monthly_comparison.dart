import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class MonthlyComparison extends StatefulWidget {
  final List<MonthData> monthsData;
  final int currentYear;

  const MonthlyComparison({
    super.key,
    required this.monthsData,
    required this.currentYear,
  });

  @override
  State<MonthlyComparison> createState() => _MonthlyComparisonState();
}

class _MonthlyComparisonState extends State<MonthlyComparison> {
  int _touchedIndex = -1;
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');

  // أسماء الشهور بالعربي
  final List<String> _arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    if (widget.monthsData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────
          // العنوان
          // ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_view_month,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مقارنة الشهور',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.getText(isDark),
                      ),
                    ),
                    Text(
                      'سنة ${widget.currentYear}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              // أفضل شهر
              if (_getBestMonth() != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        _arabicMonths[_getBestMonth()! - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ─────────────────────────────────────────────────
          // الرسم البياني
          // ─────────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxAmount() * 1.2,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null) {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedIndex = -1;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        isDark ? AppColors.darkCard : Colors.white,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = widget.monthsData[groupIndex];
                      return BarTooltipItem(
                        '${_arabicMonths[month.month - 1]}\n',
                        TextStyle(
                          color: AppColors.getText(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${_currencyFormat.format(month.amount.round())} ج.م',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.monthsData.length) {
                          return const SizedBox.shrink();
                        }
                        final month = widget.monthsData[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getShortMonthName(month),
                            style: TextStyle(
                              color: _touchedIndex == index
                                  ? AppColors.primary
                                  : AppColors.getTextSecondary(isDark),
                              fontSize: 10,
                              fontWeight: _touchedIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: _getInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatYAxis(value),
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.getBorder(isDark),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(isDark),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // الإحصائيات السريعة
          // ─────────────────────────────────────────────────
          _buildQuickStats(isDark),

          // ─────────────────────────────────────────────────
          // التفاصيل عند اللمس
          // ─────────────────────────────────────────────────
          if (_touchedIndex >= 0 && _touchedIndex < widget.monthsData.length) ...[
            const SizedBox(height: 16),
            _buildMonthDetails(isDark, widget.monthsData[_touchedIndex]),
          ],
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(bool isDark) {
    final maxAmount = _getMaxAmount();
    final currentMonth = DateTime.now().month;

    return widget.monthsData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final isCurrentMonth = data.month == currentMonth;
      final isBestMonth = data.month == _getBestMonth();

      Color barColor;
      if (isBestMonth) {
        barColor = AppColors.success;
      } else if (isCurrentMonth) {
        barColor = AppColors.primary;
      } else {
        barColor = AppColors.primary.withOpacity(0.6);
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.amount,
            color: isTouched ? barColor : barColor.withOpacity(0.8),
            width: isTouched ? 20 : 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxAmount * 1.2,
              color: AppColors.getBorder(isDark).withOpacity(0.3),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildQuickStats(bool isDark) {
    final total = widget.monthsData.fold<double>(0, (sum, m) => sum + m.amount);
    final average = widget.monthsData.isNotEmpty ? total / widget.monthsData.length : 0.0;
    final best = _getBestMonthData();
    final worst = _getWorstMonthData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              isDark: isDark,
              icon: Icons.functions,
              label: 'الإجمالي',
              value: '${_currencyFormat.format(total.round())} ج.م',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.getBorder(isDark),
          ),
          Expanded(
            child: _buildStatItem(
              isDark: isDark,
              icon: Icons.show_chart,
              label: 'المتوسط',
              value: '${_currencyFormat.format(average.round())} ج.م',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.getText(isDark),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMonthDetails(bool isDark, MonthData month) {
    final previousMonth = _getPreviousMonthData(month.month);
    double changePercent = 0;

    if (previousMonth != null && previousMonth.amount > 0) {
      changePercent = ((month.amount - previousMonth.amount) / previousMonth.amount) * 100;
    }

    final isPositive = changePercent >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _arabicMonths[month.month - 1],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  isDark: isDark,
                  label: 'الإيرادات',
                  value: '${_currencyFormat.format(month.amount.round())} ج.م',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  isDark: isDark,
                  label: 'العمليات',
                  value: '${month.transactions}',
                ),
              ),
              if (previousMonth != null)
                Expanded(
                  child: _buildDetailItem(
                    isDark: isDark,
                    label: 'الشهر السابق',
                    value: '${_currencyFormat.format(previousMonth.amount.round())} ج.م',
                    isSecondary: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required bool isDark,
    required String label,
    required String value,
    bool isSecondary = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSecondary
                ? AppColors.getTextSecondary(isDark)
                : AppColors.getText(isDark),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔧 Helper Methods
  // ═══════════════════════════════════════════════════════════

  String _getShortMonthName(int month) {
    final names = ['ين', 'فب', 'مار', 'أب', 'ماي', 'يون', 'يول', 'أغ', 'سب', 'أك', 'نو', 'دي'];
    return names[month - 1];
  }

  double _getMaxAmount() {
    if (widget.monthsData.isEmpty) return 1000;
    return widget.monthsData.map((m) => m.amount).reduce((a, b) => a > b ? a : b);
  }

  double _getInterval() {
    final max = _getMaxAmount();
    if (max <= 0) return 1000;
    return (max / 4).ceilToDouble();
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  int? _getBestMonth() {
    if (widget.monthsData.isEmpty) return null;
    final best = widget.monthsData.reduce((a, b) => a.amount > b.amount ? a : b);
    return best.amount > 0 ? best.month : null;
  }

  MonthData? _getBestMonthData() {
    if (widget.monthsData.isEmpty) return null;
    return widget.monthsData.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  MonthData? _getWorstMonthData() {
    if (widget.monthsData.isEmpty) return null;
    final nonZero = widget.monthsData.where((m) => m.amount > 0).toList();
    if (nonZero.isEmpty) return null;
    return nonZero.reduce((a, b) => a.amount < b.amount ? a : b);
  }

  MonthData? _getPreviousMonthData(int currentMonth) {
    final previousMonth = currentMonth - 1;
    if (previousMonth < 1) return null;
    try {
      return widget.monthsData.firstWhere((m) => m.month == previousMonth);
    } catch (e) {
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// 📊 نموذج بيانات الشهر
// ══════════════════════════════════════════════════════════════
class MonthData {
  final int month;
  final double amount;
  final int transactions;

  MonthData({
    required this.month,
    required this.amount,
    required this.transactions,
  });
}