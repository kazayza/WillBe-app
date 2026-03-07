import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/crm_kpi_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📈 Growth Chart Widget
// ═══════════════════════════════════════════════════════════════════════════

class GrowthChart extends StatefulWidget {
  final List<PeriodStats> data;
  final PeriodType selectedPeriod;
  final Function(PeriodType) onPeriodChanged;
  final bool isDark;

  const GrowthChart({
    super.key,
    required this.data,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isDark,
  });

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo);
    _controller.forward();
  }

  @override
  void didUpdateWidget(GrowthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.selectedPeriod != widget.selectedPeriod) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigoAccent.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 8),

          // Summary Stats
          _buildSummaryStats(),

          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 200,
            child: widget.data.isEmpty
                ? _buildEmptyChart()
                : AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) => _buildLineChart(),
                  ),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "نمو العملاء المحتملين",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPeriodLabel(),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Period Selector
        _buildPeriodSelector(),
      ],
    );
  }

  // ==================== PERIOD SELECTOR ====================
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PeriodType.values.map((period) {
          final isSelected = widget.selectedPeriod == period;
          return GestureDetector(
            onTap: () => widget.onPeriodChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigoAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getPeriodShortName(period),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodShortName(PeriodType period) {
    switch (period) {
      case PeriodType.daily:
        return 'D';
      case PeriodType.weekly:
        return 'W';
      case PeriodType.monthly:
        return 'M';
    }
  }

  String _getPeriodLabel() {
  switch (widget.selectedPeriod) {
    case PeriodType.daily:
      return 'أداء آخر 30 يوم';
    case PeriodType.weekly:
      return 'أداء آخر 12 أسبوع';
    case PeriodType.monthly:
      return 'أداء آخر 12 شهر';
  }
}

  // ==================== SUMMARY STATS ====================
  Widget _buildSummaryStats() {
    final totalLeads = widget.data.fold<int>(0, (sum, e) => sum + e.totalLeads);
    final totalConverted = widget.data.fold<int>(0, (sum, e) => sum + e.convertedLeads);
    final avgPerPeriod = widget.data.isNotEmpty 
        ? (totalLeads / widget.data.length).round() 
        : 0;

    return Row(
      children: [
        _buildMiniStat('الإجمالى', totalLeads.toString(), Colors.indigoAccent),
        const SizedBox(width: 24),
        _buildMiniStat('المحولين', totalConverted.toString(), const Color(0xFF10B981)),
        const SizedBox(width: 24),
        _buildMiniStat('المتوسط', avgPerPeriod.toString(), Colors.amber),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== LINE CHART ====================
  Widget _buildLineChart() {
  return LineChart(
    LineChartData(
      gridData: _buildGridData(),
      titlesData: _buildTitlesData(),
      borderData: FlBorderData(show: false),
      lineTouchData: _buildLineTouchData(),
      minY: 0,
      maxY: _getMaxY(),
      lineBarsData: [
        // Total Leads Line (الأزرق)
        LineChartBarData(
          spots: _getAnimatedSpots(true),
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.indigoAccent,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: Colors.indigoAccent,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigoAccent.withOpacity(0.3),
                Colors.indigoAccent.withOpacity(0.0),
              ],
            ),
          ),
        ),

        // Converted Leads Line (الأخضر) - محسّن
        LineChartBarData(
          spots: _getAnimatedSpots(false),
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xFF10B981),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,  // 👈 خليناها true
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF10B981),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,  // 👈 أضفنا area تحت الخط
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF10B981).withOpacity(0.2),
                const Color(0xFF10B981).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: _getMaxY() / 4,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: widget.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getMaxY() / 4,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _getBottomInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.data.length) {
              return const SizedBox();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatPeriodLabel(widget.data[index].period),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

 LineTouchData _buildLineTouchData() {
  return LineTouchData(
    enabled: true,
    touchCallback: (event, response) {
      setState(() {
        if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
          _touchedIndex = response.lineBarSpots!.first.spotIndex;
        } else {
          _touchedIndex = null;
        }
      });
    },
    touchTooltipData: LineTouchTooltipData(
      getTooltipItems: (spots) {
        return spots.map((spot) {
          final isConverted = spot.barIndex == 1;
          return LineTooltipItem(
            '${isConverted ? "Converted" : "Total"}: ${spot.y.toInt()}',
            TextStyle(
              color: isConverted ? const Color(0xFF10B981) : Colors.indigoAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList();
      },
    ),
  );
}

  List<FlSpot> _getAnimatedSpots(bool isTotal) {
    return widget.data.asMap().entries.map((e) {
      final value = isTotal ? e.value.totalLeads : e.value.convertedLeads;
      return FlSpot(
        e.key.toDouble(),
        value.toDouble() * _animation.value,
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.data.isEmpty) return 10;
    final max = widget.data.map((e) => e.totalLeads).reduce((a, b) => a > b ? a : b);
    return (max * 1.3).ceilToDouble().clamp(10, double.infinity);
  }

  double _getBottomInterval() {
    if (widget.data.length <= 7) return 1;
    if (widget.data.length <= 15) return 2;
    return (widget.data.length / 6).ceil().toDouble();
  }

  String _formatPeriodLabel(String period) {
    if (period.length >= 10) {
      // Daily: 2024-01-15 → 15
      return period.substring(8, 10);
    } else if (period.length == 7) {
      // Monthly: 2024-01 → Jan
      final month = int.tryParse(period.substring(5, 7)) ?? 1;
      return _getMonthAbbr(month);
    }
    return period;
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  // ==================== EMPTY CHART ====================
  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No data available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEGEND ====================
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('إجمالى العملاء', Colors.indigoAccent, false),
        const SizedBox(width: 24),
        _buildLegendItem('المحولين', const Color(0xFF10B981), true),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
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
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 4,
                          height: 3,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    );
                  },
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}