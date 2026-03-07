import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class TrendIndicator extends StatelessWidget {
  final String trend;
  final double changePercent;
  final List<double> sparklineData;

  const TrendIndicator({
    super.key,
    required this.trend,
    required this.changePercent,
    required this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final safeChangePercent = changePercent.isFinite ? changePercent : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.getCardDecoration(isDark),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTrendColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTrendIcon(),
              color: _getTrendColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاتجاه العام',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(isDark),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getTrendText(),
                      style: TextStyle(
                        color: AppColors.getText(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTrendColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trend == 'up'
                                ? Icons.arrow_upward
                                : trend == 'down'
                                    ? Icons.arrow_downward
                                    : Icons.remove,
                            size: 12,
                            color: _getTrendColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${safeChangePercent.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _getTrendColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (sparklineData.isNotEmpty && sparklineData.length >= 2)
            SizedBox(
              width: 80,
              height: 40,
              child: CustomPaint(
                painter: _SparklinePainter(
                  data: sparklineData,
                  color: _getTrendColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (trend) {
      case 'up':
        return AppColors.success;
      case 'down':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _getTrendIcon() {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendText() {
    switch (trend) {
      case 'up':
        return 'اتجاه صاعد';
      case 'down':
        return 'اتجاه هابط';
      default:
        return 'مستقر';
    }
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({
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
      ..color = color.withOpacity(0.1)
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
      final y = size.height - ((validData[i] - minVal) / range) * size.height;

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

    final lastX = size.width;
    final lastY =
        size.height - ((validData.last - minVal) / range) * size.height;

    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}