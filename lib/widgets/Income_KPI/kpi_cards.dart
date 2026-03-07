import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class KpiCards extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<double> revenueSparkline;
  final List<double> transactionsSparkline;
  final List<double> avgSparkline;

  const KpiCards({
    super.key,
    required this.data,
    this.revenueSparkline = const [],
    this.transactionsSparkline = const [],
    this.avgSparkline = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final currency = NumberFormat('#,###', 'ar_EG');
    final changes = data['changes'] ?? {};

    return Column(
      children: [
        // ─────────────────────────────────────────────────
        // الصف الأول: المتوسط اليومي + عدد العمليات
        // ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'المتوسط اليومي',
                value: '${currency.format((data['dailyAverage'] ?? 0).round())}',
                subtitle: 'ج.م',
                change: _safeDouble(changes['dailyAverage']),
                icon: Icons.trending_up,
                color: AppColors.success,
                sparklineData: avgSparkline,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'عدد العمليات',
                value: '${data['totalTransactions'] ?? 0}',
                subtitle: 'عملية',
                change: _safeDouble(changes['totalTransactions']),
                icon: Icons.receipt_long,
                color: AppColors.warning,
                sparklineData: transactionsSparkline,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─────────────────────────────────────────────────
        // الصف الثاني: الأطفال المحصلين + أيام النشاط
        // ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'الأطفال المحصلين',
                value: '${data['uniqueChildren'] ?? 0}',
                subtitle: 'طفل',
                change: null,
                icon: Icons.child_care,
                color: const Color(0xFFEC4899),
                sparklineData: const [],
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'أيام النشاط',
                value: '${data['activeDays'] ?? 0}',
                subtitle: 'يوم',
                change: null,
                icon: Icons.calendar_today,
                color: AppColors.info,
                sparklineData: const [],
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double? _safeDouble(dynamic value) {
    if (value == null) return null;
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }
}

// ══════════════════════════════════════════════════════════════
// 🎴 بطاقة KPI واحدة
// ══════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double? change;
  final IconData icon;
  final Color color;
  final List<double> sparklineData;
  final bool isDark;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.change,
    required this.icon,
    required this.color,
    required this.sparklineData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (change ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────
          // العنوان والأيقونة
          // ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─────────────────────────────────────────────────
          // القيمة
          // ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getText(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────────────
          // Sparkline
          // ─────────────────────────────────────────────────
          if (sparklineData.isNotEmpty && sparklineData.length >= 2) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 30,
              child: CustomPaint(
                size: const Size(double.infinity, 30),
                painter: _CardSparklinePainter(
                  data: sparklineData,
                  color: color,
                ),
              ),
            ),
          ],

          // ─────────────────────────────────────────────────
          // نسبة التغيير
          // ─────────────────────────────────────────────────
          if (change != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.success : AppColors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${change!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'من السابق',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🎨 رسم الـ Sparkline للبطاقات
// ══════════════════════════════════════════════════════════════
class _CardSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _CardSparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final validData = data.where((d) => d.isFinite).toList();
    if (validData.isEmpty || validData.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final minVal = validData.reduce((a, b) => a < b ? a : b);
    final maxVal = validData.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;

    if (range == 0) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < validData.length; i++) {
      final x = (i / (validData.length - 1)) * size.width;
      final y = size.height -
          ((validData[i] - minVal) / range) * size.height * 0.8 -
          size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}