import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class SeasonalChart extends StatelessWidget {
  const SeasonalChart({super.key});

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData ||
            provider.kpiData!.charts.seasonalTrend.isEmpty) {
          return const SizedBox.shrink();
        }

        final seasonal = provider.kpiData!.charts.seasonalTrend;
        final maxTotal = seasonal
            .map((s) => s.total)
            .reduce((a, b) => a > b ? a : b);
        final highestMonth =
            seasonal.reduce((a, b) => a.total > b.total ? a : b);
        final lowestMonth =
            seasonal.reduce((a, b) => a.total < b.total ? a : b);

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
                  Icon(Icons.timeline, color: Color(0xFF16A085), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'التحليل الموسمي (آخر 12 شهر)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
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
                      horizontalInterval: maxTotal / 4,
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
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < seasonal.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _getShortMonth(seasonal[index].month),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              );
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
                            final index = spot.spotIndex;
                            if (index < seasonal.length) {
                              final item = seasonal[index];
                              return LineTooltipItem(
                                '${item.monthName} ${item.year}\n${_formatNumber(item.total)} ج.م\n${item.transactions} معاملة',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(seasonal.length, (index) {
                          return FlSpot(
                            index.toDouble(),
                            seasonal[index].total,
                          );
                        }),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF16A085),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isHighest =
                                seasonal[index].total == highestMonth.total;
                            final isLowest =
                                seasonal[index].total == lowestMonth.total;
                            return FlDotCirclePainter(
                              radius: isHighest || isLowest ? 5 : 3,
                              color: isHighest
                                  ? const Color(0xFFE74C3C)
                                  : isLowest
                                      ? const Color(0xFF27AE60)
                                      : Colors.white,
                              strokeWidth: 2,
                              strokeColor: isHighest
                                  ? const Color(0xFFE74C3C)
                                  : isLowest
                                      ? const Color(0xFF27AE60)
                                      : const Color(0xFF16A085),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF16A085).withOpacity(0.15),
                              const Color(0xFF16A085).withOpacity(0.02),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ملخص
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      icon: Icons.arrow_upward,
                      label: 'أعلى شهر',
                      value: highestMonth.monthName,
                      amount: '${_formatNumber(highestMonth.total)} ج.م',
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryBox(
                      icon: Icons.arrow_downward,
                      label: 'أقل شهر',
                      value: lowestMonth.monthName,
                      amount: '${_formatNumber(lowestMonth.total)} ج.م',
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryBox(
                      icon: Icons.calculate,
                      label: 'المتوسط الشهري',
                      value: '',
                      amount:
                          '${_formatNumber(seasonal.fold<double>(0, (sum, s) => sum + s.total) / seasonal.length)} ج.م',
                      color: const Color(0xFF16A085),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryBox({
    required IconData icon,
    required String label,
    required String value,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF7F8C8D)),
            textAlign: TextAlign.center,
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getShortMonth(String month) {
    // month format: "2025-01"
    final parts = month.split('-');
    if (parts.length == 2) {
      final monthNum = int.tryParse(parts[1]) ?? 1;
      final shortMonths = [
        'ين', 'فب', 'مار', 'أبر', 'ماي', 'يون',
        'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
      ];
      return shortMonths[monthNum - 1];
    }
    return month;
  }

  String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}