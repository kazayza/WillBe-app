import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/Income_kpi_analysis_models.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class SmartSummary extends StatelessWidget {
  final PerformanceAnalysis analysis;
  final double totalAmount;
  final int activeDays;

  const SmartSummary({
    super.key,
    required this.analysis,
    required this.totalAmount,
    required this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final currencyFormat = NumberFormat('#,###', 'ar_EG');

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────
          // العنوان
          // ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.yellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'التحليل المالي الذكي',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────
          // ملخص الأداء
          // ─────────────────────────────────────────────────
          _buildSection(
            icon: Icons.analytics,
            title: 'ملخص الأداء',
            child: Text(
              analysis.summary,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          // ─────────────────────────────────────────────────
          // التوصيات
          // ─────────────────────────────────────────────────
          if (analysis.recommendations.isNotEmpty)
            _buildSection(
              icon: Icons.tips_and_updates,
              title: 'التوصيات',
              child: Column(
                children: analysis.recommendations.map((rec) {
                  return _buildRecommendationItem(rec);
                }).toList(),
              ),
            ),

          // ─────────────────────────────────────────────────
          // التوقعات
          // ─────────────────────────────────────────────────
          if (analysis.prediction != null)
            _buildSection(
              icon: Icons.trending_up,
              title: 'التوقعات',
              child: _buildPrediction(analysis.prediction!, currencyFormat),
            ),

          // ─────────────────────────────────────────────────
          // ملخص سريع
          // ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    icon: Icons.show_chart,
                    label: 'معدل النمو',
                    value: '${analysis.changePercent >= 0 ? '+' : ''}${analysis.changePercent.toStringAsFixed(1)}%',
                    valueColor: analysis.changePercent >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildQuickStat(
                    icon: Icons.calendar_today,
                    label: 'أيام النشاط',
                    value: '$activeDays يوم',
                    valueColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(KpiRecommendation recommendation) {
    Color priorityColor;
    IconData priorityIcon;

    switch (recommendation.priority) {
      case 'high':
        priorityColor = Colors.redAccent;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = Colors.orangeAccent;
        priorityIcon = Icons.remove;
        break;
      default:
        priorityColor = Colors.greenAccent;
        priorityIcon = Icons.check;
    }

    IconData recIcon;
    switch (recommendation.icon) {
      case IconType.warning:
        recIcon = Icons.warning_amber;
        break;
      case IconType.trending:
        recIcon = Icons.trending_up;
        break;
      case IconType.target:
        recIcon = Icons.gps_fixed;
        break;
      case IconType.users:
        recIcon = Icons.people;
        break;
      default:
        recIcon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recIcon,
              color: priorityColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      priorityIcon,
                      size: 12,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPriorityText(recommendation.priority),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'أولوية عالية';
      case 'medium':
        return 'أولوية متوسطة';
      default:
        return 'أولوية منخفضة';
    }
  }

  Widget _buildPrediction(PredictionData prediction, NumberFormat currencyFormat) {
    final confidenceColor = prediction.confidence == 'high'
        ? Colors.greenAccent
        : prediction.confidence == 'medium'
            ? Colors.orangeAccent
            : Colors.white70;

    final confidenceText = prediction.confidence == 'high'
        ? 'دقة عالية'
        : prediction.confidence == 'medium'
            ? 'دقة متوسطة'
            : 'دقة منخفضة';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بناءً على الأداء الحالي، متوقع تحقيق:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${currencyFormat.format(prediction.projectedAmount.round())} ج.م',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights,
                    size: 14,
                    color: confidenceColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    confidenceText,
                    style: TextStyle(
                      color: confidenceColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'متبقي ${prediction.daysRemaining} يوم على نهاية الشهر',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}