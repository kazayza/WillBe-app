import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData) return const SizedBox.shrink();

        final forecast = provider.kpiData!.forecast;
        final summary = provider.kpiData!.summary;

        // نسبة التوقع مقارنة بالفترة السابقة
        final projectedVsPrev = summary.vsPrevious.total > 0
            ? ((forecast.projectedTotal - summary.vsPrevious.total) /
                    summary.vsPrevious.total *
                    100)
                .toStringAsFixed(1)
            : '0';

        final isOverBudget = forecast.projectedTotal > summary.vsPrevious.total;

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
                  Icon(Icons.auto_graph, color: Color(0xFF8E44AD), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'توقعات نهاية الشهر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // شريط التقدم
              _buildProgressBar(forecast),

              const SizedBox(height: 16),

              // المعلومات
              Row(
                children: [
                  // المصروف حتى الآن
                  Expanded(
                    child: _buildInfoBox(
                      label: 'حتى الآن',
                      value: _formatNumber(forecast.totalSoFar),
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // المتوسط اليومي
                  Expanded(
                    child: _buildInfoBox(
                      label: 'المتوسط اليومي',
                      value: _formatNumber(forecast.dailyAverage),
                      icon: Icons.today,
                      color: const Color(0xFF8E44AD),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // المتوقع
                  Expanded(
                    child: _buildInfoBox(
                      label: 'المتوقع',
                      value: _formatNumber(forecast.projectedTotal),
                      icon: Icons.flag,
                      color: isOverBudget
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // تنبيه التوقع
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? const Color(0xFFE74C3C).withOpacity(0.08)
                      : const Color(0xFF27AE60).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverBudget ? Icons.warning_amber : Icons.check_circle,
                      size: 16,
                      color: isOverBudget
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF27AE60),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverBudget
                            ? 'المتوقع أعلى من الفترة السابقة بنسبة $projectedVsPrev%'
                            : 'المتوقع أقل من الفترة السابقة بنسبة ${double.parse(projectedVsPrev).abs()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFF27AE60),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // الأيام المتبقية
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 14, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 4),
                  Text(
                    '${forecast.daysElapsed} يوم مضى | ${forecast.daysRemaining} يوم متبقي',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
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
  // 📊 شريط التقدم
  // ════════════════════════════════════════════════════════════
  Widget _buildProgressBar(dynamic forecast) {
    final progress = forecast.daysInMonth > 0
        ? forecast.daysElapsed / forecast.daysInMonth
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}% من الشهر',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
            Text(
              '${forecast.daysElapsed}/${forecast.daysInMonth} يوم',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: const Color(0xFFECF0F1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8
                  ? const Color(0xFFE74C3C)
                  : progress > 0.5
                      ? const Color(0xFFE67E22)
                      : const Color(0xFF27AE60),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📦 صندوق معلومة
  // ════════════════════════════════════════════════════════════
  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
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
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
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