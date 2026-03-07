import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/crm_kpi_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🍩 Source Donut Chart Widget
// ═══════════════════════════════════════════════════════════════════════════

class SourceDonutChart extends StatefulWidget {
  final List<SourcePerformance> sources;
  final bool isDark;
  final Function(SourcePerformance)? onSourceTap;

  const SourceDonutChart({
    super.key,
    required this.sources,
    required this.isDark,
    this.onSourceTap,
  });

  @override
  State<SourceDonutChart> createState() => _SourceDonutChartState();
}

class _SourceDonutChartState extends State<SourceDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _touchedIndex;

  final List<Color> _defaultColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF84CC16), // Lime
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo);
    _controller.forward();
  }

  @override
  void didUpdateWidget(SourceDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 24),

          // Chart & Legend
          widget.sources.isEmpty
              ? _buildEmptyState()
              : Row(
                  children: [
                    // Donut Chart
                    Expanded(
                      flex: 2,
                      child: _buildDonutChart(),
                    ),

                    const SizedBox(width: 16),

                    // Legend
                    Expanded(
                      flex: 3,
                      child: _buildLegend(),
                    ),
                  ],
                ),

          // View All Button
          if (widget.sources.length > 5) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAllSources(context),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: Text('View All ${widget.sources.length} Sources'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigoAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    final totalLeads = widget.sources.fold<int>(0, (sum, s) => sum + s.totalLeads);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "مصادر العملاء",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "التوزيع والأداء",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        // Total Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigoAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalLeads Leads',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DONUT CHART ====================
  Widget _buildDonutChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  startDegreeOffset: -90 * _animation.value,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.touchedSection != null) {
                          _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                          if (widget.onSourceTap != null &&
                              _touchedIndex != null &&
                              _touchedIndex! >= 0 &&
                              _touchedIndex! < widget.sources.length) {
                            widget.onSourceTap!(widget.sources[_touchedIndex!]);
                          }
                        } else {
                          _touchedIndex = null;
                        }
                      });
                    },
                  ),
                  sections: _getSections(),
                ),
              ),

              // Center Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.sources.length.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'مصدر',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
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

  List<PieChartSectionData> _getSections() {
    if (widget.sources.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.3),
          value: 100,
          radius: 20,
          title: '',
        ),
      ];
    }

    return widget.sources.asMap().entries.map((e) {
      final isTouched = e.key == _touchedIndex;
      final color = _getColor(e.key, e.value.color);

      return PieChartSectionData(
        color: color,
        value: (e.value.totalLeads.toDouble() * _animation.value).clamp(0.1, double.infinity),
        radius: isTouched ? 30 : 22,
        title: isTouched ? '${e.value.totalLeads}' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // ==================== LEGEND ====================
  Widget _buildLegend() {
    return Column(
      children: widget.sources.take(5).toList().asMap().entries.map((e) {
        return _buildLegendItem(e.value, e.key);
      }).toList(),
    );
  }

  Widget _buildLegendItem(SourcePerformance source, int index) {
    final color = _getColor(index, source.color);
    final isSelected = index == _touchedIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _touchedIndex = index);
        if (widget.onSourceTap != null) {
          widget.onSourceTap!(source);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            // Color Indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(width: 10),

            // Source Name
            Expanded(
              child: Text(
                source.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${source.totalLeads}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${source.conversionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No sources data',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER ====================
  Color _getColor(int index, String? hexColor) {
    if (hexColor != null && hexColor.isNotEmpty) {
      try {
        return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return _defaultColors[index % _defaultColors.length];
  }

  // ==================== SHOW ALL SOURCES ====================
  void _showAllSources(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('📊 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'All Lead Sources',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.sources.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildLegendItem(widget.sources[index], index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}