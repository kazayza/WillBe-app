import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData) return const SizedBox.shrink();

        final summary = provider.kpiData!.summary;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // الكارت الرئيسي - إجمالي المصروفات
              _buildMainCard(summary.totalCurrent),

              const SizedBox(height: 12),

              // كارتين المقارنة
              Row(
                children: [
                  // مقارنة بالفترة السابقة
                  Expanded(
                    child: _buildComparisonCard(
                      title: 'vs الفترة السابقة',
                      icon: Icons.compare_arrows,
                      compareTotal: summary.vsPrevious.total,
                      diff: summary.vsPrevious.diff,
                      percent: summary.vsPrevious.percent,
                      isUp: summary.vsPrevious.isUp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // مقارنة بالعام السابق
                  Expanded(
                    child: _buildComparisonCard(
                      title: 'vs العام السابق',
                      icon: Icons.history,
                      compareTotal: summary.vsLastYear.total,
                      diff: summary.vsLastYear.diff,
                      percent: summary.vsLastYear.percent,
                      isUp: summary.vsLastYear.isUp,
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

  // ════════════════════════════════════════════════════════════
  // 💰 الكارت الرئيسي
  // ════════════════════════════════════════════════════════════
  Widget _buildMainCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'إجمالي المصروفات',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatNumber(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ج.م',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📊 كارت المقارنة
  // ════════════════════════════════════════════════════════════
  Widget _buildComparisonCard({
    required String title,
    required IconData icon,
    required double compareTotal,
    required double diff,
    required double percent,
    required bool isUp,
  }) {
    // في المصروفات: الارتفاع سلبي (أحمر) والانخفاض إيجابي (أخضر)
    final Color trendColor = isUp
        ? const Color(0xFFE74C3C)  // أحمر = زيادة مصروفات
        : const Color(0xFF27AE60); // أخضر = توفير

    final IconData trendIcon = isUp
        ? Icons.trending_up
        : Icons.trending_down;

    final String trendLabel = isUp ? 'زيادة' : 'توفير';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Icon(icon, size: 14, color: const Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F8C8D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // المبلغ السابق
          Text(
            _formatNumber(compareTotal),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'ج.م',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFBDC3C7),
            ),
          ),

          const SizedBox(height: 10),

          // الفرق والنسبة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${percent.abs()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // الفرق بالمبلغ
          Text(
            '${isUp ? '+' : '-'} ${_formatNumber(diff.abs())} ج.م',
            style: TextStyle(
              fontSize: 11,
              color: trendColor,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            trendLabel,
            style: TextStyle(
              fontSize: 10,
              color: trendColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🔧 تنسيق الأرقام
  // ════════════════════════════════════════════════════════════
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}