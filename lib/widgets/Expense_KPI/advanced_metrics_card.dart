import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';

class AdvancedMetricsCard extends StatelessWidget {
  const AdvancedMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData) return const SizedBox.shrink();

        final advanced = provider.kpiData!.advanced;

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
                  Icon(Icons.analytics, color: Color(0xFF2980B9), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'مؤشرات متقدمة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // الصف الأول
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.receipt_long,
                      label: 'عدد المعاملات',
                      value: advanced.totalTransactions.toString(),
                      color: const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.calendar_today,
                      label: 'أيام نشطة',
                      value: advanced.activeDays.toString(),
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.calculate,
                      label: 'متوسط المعاملة',
                      value: _formatNumber(advanced.avgPerTransaction),
                      color: const Color(0xFF8E44AD),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // الصف الثاني
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.arrow_upward,
                      label: 'أعلى مصروف',
                      value: _formatNumber(advanced.maxSingleExpense),
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.arrow_downward,
                      label: 'أقل مصروف',
                      value: _formatNumber(advanced.minSingleExpense),
                      color: const Color(0xFF16A085),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.show_chart,
                      label: 'الانحراف المعياري',
                      value: _formatNumber(advanced.stdDeviation),
                      color: const Color(0xFFE67E22),
                    ),
                  ),
                ],
              ),

              // أكثر بند تكراراً
              if (advanced.mostFrequentKind != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.repeat,
                          color: Color(0xFF2C3E50),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أكثر بند تكراراً',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              advanced.mostFrequentKind!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${advanced.mostFrequentKind!.count} معاملة',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            '${_formatNumber(advanced.mostFrequentKind!.total)} ج.م',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📦 مربع مؤشر واحد
  // ════════════════════════════════════════════════════════════
  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}