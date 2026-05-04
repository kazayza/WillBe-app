import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expenses_kpi_provider.dart';

class WeekdayChart extends StatelessWidget {
  const WeekdayChart({super.key});

  static const List<String> _arabicDays = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData ||
            provider.kpiData!.charts.weekdayAnalysis.isEmpty) {
          return const SizedBox.shrink();
        }

        final weekdays = provider.kpiData!.charts.weekdayAnalysis;
        final maxTotal = weekdays
            .map((w) => w.total)
            .reduce((a, b) => a > b ? a : b);
        final highestDay = weekdays.reduce((a, b) => a.total > b.total ? a : b);

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
                  Icon(Icons.calendar_view_week, color: Color(0xFFE67E22), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'تحليل أيام الأسبوع',
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
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxTotal * 1.15,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = weekdays[groupIndex];
                          return BarTooltipItem(
                            '${_getArabicDay(day.dayNumber)}\n${_formatNumber(day.total)} ج.م\n${day.transactions} معاملة',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
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
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < weekdays.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _getShortArabicDay(weekdays[index].dayNumber),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: weekdays[index].dayNumber ==
                                            highestDay.dayNumber
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: weekdays[index].dayNumber ==
                                            highestDay.dayNumber
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFF7F8C8D),
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxTotal / 4,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xFFECF0F1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: List.generate(weekdays.length, (index) {
                      final day = weekdays[index];
                      final isHighest = day.dayNumber == highestDay.dayNumber;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: day.total,
                            width: 28,
                            color: isHighest
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFE67E22).withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxTotal * 1.15,
                              color: const Color(0xFFF5F6FA),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ملخص
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFE67E22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أعلى إنفاق يوم ${_getArabicDay(highestDay.dayNumber)} بمتوسط ${_formatNumber(highestDay.average)} ج.م (${highestDay.transactions} معاملة)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getArabicDay(int dayNumber) {
    if (dayNumber >= 1 && dayNumber <= 7) {
      return _arabicDays[dayNumber - 1];
    }
    return '';
  }

  String _getShortArabicDay(int dayNumber) {
    final days = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
    if (dayNumber >= 1 && dayNumber <= 7) {
      return days[dayNumber - 1];
    }
    return '';
  }

  String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}