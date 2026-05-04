import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/kpi_service.dart';
import '../../services/pdf_service.dart';

class QuickActions extends StatelessWidget {
  final double totalAmount;
  final int totalTransactions;
  final double changePercent;
  final String period;
  final DashboardData? dashboardData;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback? onRefresh;

  const QuickActions({
    super.key,
    required this.totalAmount,
    required this.totalTransactions,
    required this.changePercent,
    required this.period,
    this.dashboardData,
    this.fromDate,
    this.toDate,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────
          // العنوان
          // ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getText(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // الصف الأول: تصدير PDF + مشاركة
          // ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'تصدير PDF',
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: () => _handleExportPDF(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share,
                  label: 'مشاركة',
                  color: AppColors.info,
                  isDark: isDark,
                  onTap: () => _handleShare(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─────────────────────────────────────────────────
          // الصف الثاني: طباعة + تحديث
          // ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.print,
                  label: 'طباعة',
                  color: AppColors.success,
                  isDark: isDark,
                  onTap: () => _handleExportPDF(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.refresh,
                  label: 'تحديث',
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => _handleRefresh(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📄 تصدير PDF
  // ═══════════════════════════════════════════════════════════
  void _handleExportPDF(BuildContext context) async {
  if (dashboardData == null || fromDate == null || toDate == null) {
    _showSnackBar(
        context, 'لا توجد بيانات لتصديرها', Icons.error, AppColors.error);
    return;
  }

  _showSnackBar(context, 'جاري إنشاء ملف PDF...', Icons.picture_as_pdf,
      AppColors.warning);

  try {
    await PdfService.generateAndShareReport(
      context: context,
      data: dashboardData!,
      period: period,
      fromDate: fromDate!,
      toDate: toDate!,
      analysis: null, // هنمررها من الشاشة الرئيسية
    );
  } catch (e) {
    if (context.mounted) {
      _showSnackBar(
          context, 'حدث خطأ في إنشاء PDF', Icons.error, AppColors.error);
    }
  }
}

  // ═══════════════════════════════════════════════════════════
  // 📤 مشاركة
  // ═══════════════════════════════════════════════════════════
  void _handleShare(BuildContext context) async {
    final currencyFormat = NumberFormat('#,###', 'ar_EG');

    final safeTotal = totalAmount.isFinite ? totalAmount : 0.0;
    final safeChange = changePercent.isFinite ? changePercent : 0.0;
    final changeSign = safeChange >= 0 ? '+' : '';

    final shareText = '''
📊 تقرير مؤشرات أداء الإيرادات - $period

💰 إجمالي الإيرادات: ${currencyFormat.format(safeTotal.round())} ج.م
📈 نسبة التغيير: $changeSign${safeChange.toStringAsFixed(1)}%
🧾 عدد العمليات: $totalTransactions عملية

تم إنشاء التقرير بواسطة التطبيق
''';

    try {
      await Share.share(shareText, subject: 'تقرير مؤشرات أداء الإيرادات');
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
            context, 'حدث خطأ في المشاركة', Icons.error, AppColors.error);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 تحديث
  // ═══════════════════════════════════════════════════════════
  void _handleRefresh(BuildContext context) {
    if (onRefresh != null) {
      onRefresh!();
      _showSnackBar(
          context, 'جاري تحديث البيانات...', Icons.refresh, AppColors.primary);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💬 إظهار SnackBar
  // ═══════════════════════════════════════════════════════════
  void _showSnackBar(
      BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🔘 زر الإجراء
// ══════════════════════════════════════════════════════════════
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color.withOpacity(0.2)
              : widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color.withOpacity(_isPressed ? 0.5 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}