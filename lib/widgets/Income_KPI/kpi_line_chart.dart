import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class KpiLineChart extends StatefulWidget {
  final Map<String, dynamic> data;
  final String period;
  final String compareWith;

  const KpiLineChart({
    super.key,
    required this.data,
    required this.period,
    required this.compareWith,
  });

  @override
  State<KpiLineChart> createState() => _KpiLineChartState();
}

class _KpiLineChartState extends State<KpiLineChart> {
  int? _touchedIndex;
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final current = (widget.data['current'] as List?) ?? [];
    final previous = (widget.data['previous'] as List?) ?? [];

    if (current.isEmpty) {
      return const SizedBox.shrink();
    }

    // حساب إحصائيات الفترة الحالية
    double totalCurrent = 0;
    double totalPrevious = 0;

    for (var item in current) {
      final amount = (item['amount'] ?? 0).toDouble();
      if (amount.isFinite) totalCurrent += amount;
    }

    for (var item in previous) {
      final amount = (item['amount'] ?? 0).toDouble();
      if (amount.isFinite) totalPrevious += amount;
    }

    double changePercent = 0;
    if (totalPrevious > 0) {
      changePercent = ((totalCurrent - totalPrevious) / totalPrevious) * 100;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.show_chart,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحليل الإيرادات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.getText(isDark),
                        ),
                      ),
                      Text(
                        _getPeriodLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // نسبة التغيير الإجمالية
              if (previous.isNotEmpty && changePercent.isFinite)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (changePercent >= 0 ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changePercent >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color: changePercent >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: changePercent >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ─────────────────────────────────────────────────
          // ملخص سريع
          // ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    isDark: isDark,
                    label: 'الفترة الحالية',
                    value: '${_currencyFormat.format(totalCurrent.round())} ج.م',
                    color: AppColors.primary,
                  ),
                ),
                if (previous.isNotEmpty) ...[
                  Container(
                    width: 1,
                    height: 35,
                    color: AppColors.getBorder(isDark),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      isDark: isDark,
                      label: 'الفترة السابقة',
                      value: '${_currencyFormat.format(totalPrevious.round())} ج.م',
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // الرسم البياني
          // ─────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 1.6,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(current),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.getBorder(isDark),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= current.length) {
                          return const SizedBox.shrink();
                        }

                        // عرض بعض النقاط فقط
                        final interval = _getLabelInterval(current.length);
                        if (index % interval != 0 && index != current.length - 1) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getLabel(current[index], index),
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
    reservedSize: 55,
    interval: _calculateInterval(current),
    getTitlesWidget: (value, meta) {
      // نتجنب أول وآخر قيمة لو بتتداخل
      if (value == meta.min || value == meta.max) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          _formatYAxisLabel(value),
          style: TextStyle(
            color: AppColors.getTextSecondary(isDark),
            fontSize: 9,
          ),
          textAlign: TextAlign.right,
        ),
      );
    },
  ),
),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.lineBarSpots != null &&
                          response!.lineBarSpots!.isNotEmpty) {
                        _touchedIndex = response.lineBarSpots!.first.spotIndex;
                      } else {
                        _touchedIndex = null;
                      }
                    });
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) =>
                        isDark ? AppColors.darkCard : Colors.white,
                    tooltipPadding: const EdgeInsets.all(12),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final isCurrentLine = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${_currencyFormat.format(spot.y.round())} ج.م\n',
                          TextStyle(
                            color: isCurrentLine
                                ? AppColors.primary
                                : AppColors.getTextSecondary(isDark),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: isCurrentLine ? 'الفترة الحالية' : 'الفترة السابقة',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  // ─────────────────────────────────────────────────
                  // الفترة الحالية
                  // ─────────────────────────────────────────────────
                  LineChartBarData(
                    spots: _getSpots(current),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = index == _touchedIndex;
                        return FlDotCirclePainter(
                          radius: isSelected ? 6 : 3,
                          color: Colors.white,
                          strokeWidth: isSelected ? 3 : 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  // ─────────────────────────────────────────────────
                  // الفترة السابقة
                  // ─────────────────────────────────────────────────
                  if (previous.isNotEmpty)
                    LineChartBarData(
                      spots: _getSpots(previous),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.getTextSecondary(isDark).withOpacity(0.5),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dashArray: [8, 4],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─────────────────────────────────────────────────
          // Legend
          // ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                'الفترة الحالية',
                AppColors.primary,
                false,
                isDark,
              ),
              if (previous.isNotEmpty) ...[
                const SizedBox(width: 24),
                _buildLegend(
                  'الفترة السابقة',
                  AppColors.getTextSecondary(isDark),
                  true,
                  isDark,
                ),
              ],
            ],
          ),

          // ─────────────────────────────────────────────────
          // تفاصيل النقطة المحددة
          // ─────────────────────────────────────────────────
          if (_touchedIndex != null && _touchedIndex! < current.length) ...[
            const SizedBox(height: 16),
            _buildSelectedPointDetails(isDark, current, previous),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
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
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSelectedPointDetails(
      bool isDark, List<dynamic> current, List<dynamic> previous) {
    final currentPoint = current[_touchedIndex!];
    final currentAmount = (currentPoint['amount'] ?? 0).toDouble();

    double? previousAmount;
    double changePercent = 0;

    if (previous.isNotEmpty && _touchedIndex! < previous.length) {
      previousAmount = (previous[_touchedIndex!]['amount'] ?? 0).toDouble();
      if (previousAmount != null && previousAmount > 0) {
        changePercent = ((currentAmount - previousAmount) / previousAmount) * 100;
      }
    }

    final isPositive = changePercent >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                _getLabel(currentPoint, _touchedIndex!),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_currencyFormat.format(currentAmount.round())} ج.م',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getText(isDark),
                ),
              ),
            ],
          ),
          if (previousAmount != null && previousAmount > 0) ...[
            Container(
              width: 1,
              height: 40,
              color: AppColors.getBorder(isDark),
            ),
            Column(
              children: [
                Text(
                  'السابق',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currencyFormat.format(previousAmount.round())} ج.م',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.getBorder(isDark),
            ),
            Column(
              children: [
                Text(
                  'التغيير',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
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
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (widget.period) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذه السنة';
      default:
        return 'فترة مخصصة';
    }
  }

  List<FlSpot> _getSpots(List<dynamic> list) {
    return list.asMap().entries.map((e) {
      final amount = (e.value['amount'] ?? 0).toDouble();
      return FlSpot(
        e.key.toDouble(),
        amount.isFinite ? amount : 0.0,
      );
    }).toList();
  }

  double _calculateInterval(List<dynamic> data) {
  if (data.isEmpty) return 1000;
  
  final values = data
      .map((e) => (e['amount'] ?? 0).toDouble())
      .where((v) => v.isFinite && v > 0)
      .toList();
  
  if (values.isEmpty) return 1000;
  
  final max = values.reduce((a, b) => a > b ? a : b);
  final min = values.reduce((a, b) => a < b ? a : b);
  final range = max - min;
  
  if (range <= 0) return max / 4;
  
  // نقسم على 3 بدل 4 عشان المسافات تبقى أكبر
  final interval = (range / 3).ceilToDouble();
  
  // نتأكد إن الـ interval مش صغير جداً
  if (interval < 100) return 100;
  
  return interval;
}

  int _getLabelInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 15) return 2;
    if (dataLength <= 31) return 5;
    return (dataLength / 6).ceil();
  }

  String _getLabel(Map<String, dynamic> item, int index) {
  final period = item['period'];

  if (period == null) return '${index + 1}';

  // لو رقم (يوم في الشهر)
  if (period is int) {
    return '$period';
  }

  // لو نص
  if (period is String) {
    // لو تاريخ ISO format (مثل: 2024-02-01T00:00:00)
    if (period.contains('T') || period.contains('-')) {
      try {
        final date = DateTime.parse(period);
        // نرجع اليوم فقط
        return '${date.day}';
      } catch (e) {
        // لو فشل التحويل، نحاول نستخرج اليوم يدوياً
        final parts = period.split('-');
        if (parts.length >= 3) {
          // ناخد اليوم من التاريخ
          final dayPart = parts[2].split('T')[0];
          final day = int.tryParse(dayPart);
          if (day != null) {
            return '$day';
          }
        }
      }
    }

    // لو رقم كـ String
    final parsed = int.tryParse(period);
    if (parsed != null) {
      return '$parsed';
    }

    // لو نص قصير، نرجعه زي ما هو
    if (period.length <= 5) {
      return period;
    }

    // لو نص طويل، ناخد آخر جزء
    return period.substring(period.length - 2);
  }

  return '${index + 1}';
}

  String _formatYAxisLabel(double value) {
    if (!value.isFinite) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildLegend(String text, Color color, bool isDashed, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🎨 رسم خط متقطع للـ Legend
// ══════════════════════════════════════════════════════════════
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}