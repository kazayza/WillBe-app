import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData || provider.kpiData!.insights.isEmpty) {
          return const SizedBox.shrink();
        }

        final insights = provider.kpiData!.insights;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39C12).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF39C12),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تنبيهات ذكية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${insights.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // قائمة التنبيهات
              ...List.generate(insights.length, (index) {
                return _buildInsightItem(insights[index], index, insights.length);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightItem(Insight insight, int index, int total) {
    final config = _getInsightConfig(insight);

    return Container(
      margin: EdgeInsets.only(bottom: index < total - 1 ? 10 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة الحالة
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              insight.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),

          const SizedBox(width: 10),

          // المحتوى
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان + الأولوية
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: config.color,
                        ),
                      ),
                    ),
                    _buildPriorityBadge(insight),
                  ],
                ),

                const SizedBox(height: 4),

                // الرسالة
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🏷️ شارة الأولوية
  // ════════════════════════════════════════════════════════════
  Widget _buildPriorityBadge(Insight insight) {
    Color badgeColor;
    String badgeText;

    switch (insight.priority) {
      case 'high':
        badgeColor = const Color(0xFFE74C3C);
        badgeText = 'عاجل';
        break;
      case 'medium':
        badgeColor = const Color(0xFFE67E22);
        badgeText = 'متوسط';
        break;
      default:
        badgeColor = const Color(0xFF27AE60);
        badgeText = 'منخفض';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🎨 إعدادات الألوان حسب النوع
  // ════════════════════════════════════════════════════════════
  _InsightConfig _getInsightConfig(Insight insight) {
    switch (insight.type) {
      case 'danger':
        return _InsightConfig(
          color: const Color(0xFFE74C3C),
          icon: Icons.error,
        );
      case 'warning':
        return _InsightConfig(
          color: const Color(0xFFE67E22),
          icon: Icons.warning,
        );
      case 'success':
        return _InsightConfig(
          color: const Color(0xFF27AE60),
          icon: Icons.check_circle,
        );
      case 'info':
      default:
        return _InsightConfig(
          color: const Color(0xFF3498DB),
          icon: Icons.info,
        );
    }
  }
}

class _InsightConfig {
  final Color color;
  final IconData icon;

  _InsightConfig({required this.color, required this.icon});
}