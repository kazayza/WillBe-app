import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class GroupDistributionChart extends StatefulWidget {
  const GroupDistributionChart({super.key});

  @override
  State<GroupDistributionChart> createState() => _GroupDistributionChartState();
}

class _GroupDistributionChartState extends State<GroupDistributionChart> {
  int touchedIndex = -1;

  static const List<Color> _colors = [
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFE74C3C),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF34495E),
    Color(0xFFD35400),
    Color(0xFF27AE60),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData ||
            provider.kpiData!.groupDistribution.isEmpty) {
          return const SizedBox.shrink();
        }

        final distribution = provider.kpiData!.groupDistribution;

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
                  Icon(Icons.donut_large, color: Color(0xFF9B59B6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'توزيع المصروفات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // الرسم + المفتاح
              Row(
                children: [
                  // الرسم البياني
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildSections(distribution),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // مفتاح الألوان
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(distribution.length, (index) {
                        final item = distribution[index];
                        final isTouched = index == touchedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _colors[index % _colors.length],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.group,
                                  style: TextStyle(
                                    fontSize: isTouched ? 12 : 10,
                                    fontWeight: isTouched
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.percent}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _colors[index % _colors.length],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  List<PieChartSectionData> _buildSections(List<GroupDistribution> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 55.0 : 45.0;
      final fontSize = isTouched ? 14.0 : 11.0;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: item.amount,
        title: isTouched ? '${item.percent}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}