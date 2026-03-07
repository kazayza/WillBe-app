import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class KpiPieChart extends StatefulWidget {
  final String title;
  final List<dynamic> data;
  final String keyName;
  final IconData? icon;

  const KpiPieChart({
    super.key,
    required this.title,
    required this.data,
    required this.keyName,
    this.icon,
  });

  @override
  State<KpiPieChart> createState() => _KpiPieChartState();
}

class _KpiPieChartState extends State<KpiPieChart> {
  int _touchedIndex = -1;
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    if (widget.data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.getCardDecoration(isDark),
      child: Column(
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
                  widget.icon ?? Icons.pie_chart,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getText(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // الرسم الدائري
          // ─────────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: _getSections(isDark),
                  ),
                ),
                // ─────────────────────────────────────────────────
                // القيمة في المنتصف
                // ─────────────────────────────────────────────────
                _buildCenterContent(isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // Legend
          // ─────────────────────────────────────────────────
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildCenterContent(bool isDark) {
    if (_touchedIndex >= 0 && _touchedIndex < widget.data.length) {
      final item = widget.data[_touchedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(item['percentage'] ?? 0).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDark),
            ),
          ),
          Text(
            _currencyFormat.format((item['amount'] ?? 0).round()),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.data.length}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.getText(isDark),
          ),
        ),
        Text(
          widget.keyName == 'kindName' ? 'أنواع' : 'فروع',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSections(bool isDark) {
    return widget.data.asMap().entries.map((e) {
      final index = e.key;
      final item = e.value;
      final isTouched = index == _touchedIndex;
      final value = (item['amount'] ?? 0).toDouble();
      final color = AppColors.getChartColor(index);

      return PieChartSectionData(
        color: color,
        value: value,
        title: '',
        radius: isTouched ? 30 : 22,
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 3)
            : BorderSide.none,
      );
    }).toList();
  }

  Widget _buildLegend(bool isDark) {
    final displayItems = widget.data.take(5).toList();
    final hasMore = widget.data.length > 5;

    return Column(
      children: [
        ...displayItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final color = AppColors.getChartColor(index);
          final percentage = (item['percentage'] ?? 0).toDouble();
          final amount = (item['amount'] ?? 0).toDouble();
          final isSelected = index == _touchedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _touchedIndex = _touchedIndex == index ? -1 : index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item[widget.keyName] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getText(isDark),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_currencyFormat.format(amount.round())} ج.م',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'و ${widget.data.length - 5} آخرين...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(isDark),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}