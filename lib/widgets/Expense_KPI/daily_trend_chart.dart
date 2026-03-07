import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class DailyTrendChart extends StatelessWidget {
  const DailyTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData ||
            provider.kpiData!.charts.dailyTrend.current.isEmpty) {
          return const SizedBox.shrink();
        }

        final dailyTrend = provider.kpiData!.charts.dailyTrend;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              const Row(
                children: [
                  Icon(Icons.show_chart, color: Color(0xFF2980B9), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'التريند اليومي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // مفتاح الألوان
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('الفترة الحالية', const Color(0xFF3498DB)),
                  const SizedBox(width: 20),
                  _buildLegendItem('الفترة السابقة', const Color(0xFFE74C3C)),
                ],
              ),

              const SizedBox(height: 16),

              // الرسم البياني
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxValue(dailyTrend) / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: const Color(0xFFECF0F1),
                          strokeWidth: 1,
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatNumber(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF7F8C8D),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _getBottomInterval(dailyTrend.current.length),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 &&
                                index < dailyTrend.current.length) {
                              final date = dailyTrend.current[index].date;
                              if (date != null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isCurrentLine = spot.barIndex == 0;
                            return LineTooltipItem(
                              '${isCurrentLine ? 'الحالي' : 'السابق'}\n${_formatNumber(spot.y)} ج.م',
                              TextStyle(
                                color: isCurrentLine
                                    ? const Color(0xFF3498DB)
                                    : const Color(0xFFE74C3C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // خط الفترة الحالية
                      _buildLineData(
                        dailyTrend.current,
                        const Color(0xFF3498DB),
                        true,
                      ),
                      // خط الفترة السابقة
                      if (dailyTrend.previous.isNotEmpty)
                        _buildLineData(
                          dailyTrend.previous,
                          const Color(0xFFE74C3C),
                          false,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ملخص سريع
              _buildQuickSummary(dailyTrend),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📈 بناء خط واحد
  // ════════════════════════════════════════════════════════════
  LineChartBarData _buildLineData(
    List<DailyPoint> points,
    Color color,
    bool isCurrent,
  ) {
    return LineChartBarData(
      spots: List.generate(points.length, (index) {
        return FlSpot(index.toDouble(), points[index].amount);
      }),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: isCurrent ? 3 : 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: points.length <= 15,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: isCurrent,
        color: color.withOpacity(0.08),
      ),
      dashArray: isCurrent ? null : [8, 4],
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📊 ملخص سريع
  // ════════════════════════════════════════════════════════════
  Widget _buildQuickSummary(DailyTrend trend) {
    final currentTotal =
        trend.current.fold<double>(0, (sum, p) => sum + p.amount);
    final previousTotal =
        trend.previous.fold<double>(0, (sum, p) => sum + p.amount);

    final currentMax = trend.current.isNotEmpty
        ? trend.current.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;
    final currentMin = trend.current.isNotEmpty
        ? trend.current.reduce((a, b) => a.amount < b.amount ? a : b)
        : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (currentMax != null)
            Expanded(
              child: _buildSummaryItem(
                label: 'أعلى يوم',
                value: '${_formatNumber(currentMax.amount)} ج.م',
                sub: currentMax.date != null
                    ? '${currentMax.date!.day}/${currentMax.date!.month}'
                    : '',
                color: const Color(0xFFE74C3C),
              ),
            ),
          if (currentMin != null) ...[
            Container(
              width: 1,
              height: 35,
              color: const Color(0xFFECF0F1),
            ),
            Expanded(
              child: _buildSummaryItem(
                label: 'أقل يوم',
                value: '${_formatNumber(currentMin.amount)} ج.م',
                sub: currentMin.date != null
                    ? '${currentMin.date!.day}/${currentMin.date!.month}'
                    : '',
                color: const Color(0xFF27AE60),
              ),
            ),
          ],
          Container(
            width: 1,
            height: 35,
            color: const Color(0xFFECF0F1),
          ),
          Expanded(
            child: _buildSummaryItem(
              label: 'المتوسط',
              value: trend.current.isNotEmpty
                  ? '${_formatNumber(currentTotal / trend.current.length)} ج.م'
                  : '0',
              sub: '${trend.current.length} يوم',
              color: const Color(0xFF3498DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 9, color: Color(0xFFBDC3C7)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7F8C8D)),
        ),
      ],
    );
  }

  double _getMaxValue(DailyTrend trend) {
    double max = 0;
    for (var p in trend.current) {
      if (p.amount > max) max = p.amount;
    }
    for (var p in trend.previous) {
      if (p.amount > max) max = p.amount;
    }
    return max == 0 ? 1 : max;
  }

  double _getBottomInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 15) return 2;
    if (length <= 31) return 5;
    return 7;
  }

  String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}