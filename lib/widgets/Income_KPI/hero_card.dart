import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class HeroCard extends StatefulWidget {
  final double totalAmount;
  final double previousAmount;
  final double changePercent;
  final List<double> sparklineData;
  final String compareWith;
  final DateTime fromDate;
  final DateTime toDate;

  const HeroCard({
    super.key,
    required this.totalAmount,
    required this.previousAmount,
    required this.changePercent,
    this.sparklineData = const [],
    this.compareWith = 'previousPeriod',
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final safeTotal = widget.totalAmount.isFinite ? widget.totalAmount : 0.0;

    _countAnimation = Tween<double>(
      begin: 0,
      end: safeTotal,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      final safeOldTotal =
          oldWidget.totalAmount.isFinite ? oldWidget.totalAmount : 0.0;
      final safeNewTotal =
          widget.totalAmount.isFinite ? widget.totalAmount : 0.0;

      _countAnimation = Tween<double>(
        begin: safeOldTotal,
        end: safeNewTotal,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
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
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    // حماية من القيم غير الصالحة
    final safeChangePercent =
        widget.changePercent.isFinite ? widget.changePercent : 0.0;
    final isPositive = safeChangePercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // العنوان والأيقونة
          // ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إجمالي الإيرادات',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // نسبة التغيير
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${safeChangePercent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color:
                            isPositive ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // المبلغ المتحرك
          // ─────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              final value = _countAnimation.value.isFinite
                  ? _countAnimation.value
                  : 0.0;
              return Text(
                '${_currencyFormat.format(value.round())} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ─────────────────────────────────────────────────
          // المقارنة النصية مع توضيح الفترة
          // ─────────────────────────────────────────────────
          Text(
            'مقارنة بـ ${_currencyFormat.format(_getSafePreviousAmount().round())} ج.م',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getComparisonPeriodText(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // شريط المقارنة
          // ─────────────────────────────────────────────────
          _buildComparisonBar(),

          // ─────────────────────────────────────────────────
          // Sparkline
          // ─────────────────────────────────────────────────
          if (widget.sparklineData.isNotEmpty &&
              widget.sparklineData.length >= 2) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: CustomPaint(
                size: const Size(double.infinity, 50),
                painter: _HeroSparklinePainter(
                  data: widget.sparklineData,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🛡️ الحصول على المبلغ السابق بشكل آمن
  // ═══════════════════════════════════════════════════════════
  double _getSafePreviousAmount() {
    if (widget.previousAmount.isFinite && widget.previousAmount >= 0) {
      return widget.previousAmount;
    }
    return 0.0;
  }

  // ═══════════════════════════════════════════════════════════
  // 📅 نص فترة المقارنة
  // ═══════════════════════════════════════════════════════════
  String _getComparisonPeriodText() {
    final dateFormat = DateFormat('yyyy/MM/dd');

    try {
      if (widget.compareWith == 'lastYear') {
        final lastYearFrom = DateTime(
          widget.fromDate.year - 1,
          widget.fromDate.month,
          widget.fromDate.day,
        );
        final lastYearTo = DateTime(
          widget.toDate.year - 1,
          widget.toDate.month,
          widget.toDate.day,
        );
        return 'في الفترة (${dateFormat.format(lastYearFrom)} - ${dateFormat.format(lastYearTo)})';
      } else {
        // الفترة السابقة
        final duration = widget.toDate.difference(widget.fromDate);
        final prevFrom =
            widget.fromDate.subtract(duration + const Duration(days: 1));
        final prevTo = widget.fromDate.subtract(const Duration(days: 1));
        return 'في الفترة (${dateFormat.format(prevFrom)} - ${dateFormat.format(prevTo)})';
      }
    } catch (e) {
      return 'الفترة السابقة';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 شريط المقارنة
  // ═══════════════════════════════════════════════════════════
  Widget _buildComparisonBar() {
    // حماية من القسمة على صفر والقيم غير الصالحة
    final safeTotal = widget.totalAmount.isFinite ? widget.totalAmount : 0.0;
    final safePrevious = _getSafePreviousAmount();

    final maxAmount = safeTotal > safePrevious ? safeTotal : safePrevious;

    double currentPercent = 0.0;
    double previousPercent = 0.0;

    if (maxAmount > 0) {
      currentPercent = (safeTotal / maxAmount).clamp(0.0, 1.0);
      previousPercent = (safePrevious / maxAmount).clamp(0.0, 1.0);
    }

    // حماية إضافية
    if (currentPercent.isNaN || currentPercent.isInfinite) {
      currentPercent = 0.0;
    }
    if (previousPercent.isNaN || previousPercent.isInfinite) {
      previousPercent = 0.0;
    }

    return Column(
      children: [
        // ─────────────────────────────────────────────────
        // الفترة الحالية
        // ─────────────────────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 50,
              child: Text(
                'الحالي',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: currentPercent,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ─────────────────────────────────────────────────
        // الفترة السابقة
        // ─────────────────────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 50,
              child: Text(
                'السابق',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: previousPercent,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🎨 رسم الـ Sparkline للـ Hero Card
// ══════════════════════════════════════════════════════════════
class _HeroSparklinePainter extends CustomPainter {
  final List<double> data;

  _HeroSparklinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    // حماية من البيانات الفارغة
    if (data.isEmpty || data.length < 2) return;

    // فلترة القيم غير الصالحة
    final validData = data.where((d) => d.isFinite).toList();
    if (validData.isEmpty || validData.length < 2) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final minVal = validData.reduce((a, b) => a < b ? a : b);
    final maxVal = validData.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;

    // لو كل القيم متساوية، ارسم خط مستقيم
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
        final prevX = ((i - 1) / (validData.length - 1)) * size.width;
        final prevY = size.height -
            ((validData[i - 1] - minVal) / range) * size.height * 0.8 -
            size.height * 0.1;

        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
        fillPath.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // نقطة في النهاية
    final lastX = size.width;
    final lastY = size.height -
        ((validData.last - minVal) / range) * size.height * 0.8 -
        size.height * 0.1;

    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      8,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}