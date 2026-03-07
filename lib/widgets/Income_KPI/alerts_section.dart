import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Income_kpi_analysis_models.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/kpi_service.dart';

class AlertsSection extends StatefulWidget {
  final List<KpiAlert> alerts;

  const AlertsSection({
    super.key,
    required this.alerts,
  });

  @override
  State<AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<AlertsSection> {
  final Set<String> _dismissedAlerts = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    
    // فلترة التنبيهات المغلقة
    final visibleAlerts = widget.alerts
        .where((alert) => !_dismissedAlerts.contains(alert.id))
        .toList();

    if (visibleAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─────────────────────────────────────────────────
        // العنوان
        // ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تنبيهات تحتاج انتباهك',
                style: TextStyle(
                  color: AppColors.getText(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${visibleAlerts.length} تنبيه',
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ─────────────────────────────────────────────────
        // قائمة التنبيهات
        // ─────────────────────────────────────────────────
        ...visibleAlerts.map((alert) => _buildAlertCard(alert, isDark)),
      ],
    );
  }

  Widget _buildAlertCard(KpiAlert alert, bool isDark) {
  final config = _getAlertConfig(alert.type);

  return Dismissible(
    key: Key(alert.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) {
      setState(() {
        _dismissedAlerts.add(alert.id);
      });
    },
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // الأيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: config['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              config['icon'],
              color: config['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: config['color'],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // زر الإغلاق
          IconButton(
            onPressed: () {
              setState(() {
                _dismissedAlerts.add(alert.id);
              });
            },
            icon: Icon(
              Icons.close,
              size: 18,
              color: AppColors.getTextSecondary(isDark),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    ),
  );
}

  Map<String, dynamic> _getAlertConfig(String type) {
    switch (type) {
      case 'danger':
        return {
          'color': AppColors.error,
          'icon': Icons.error_outline,
        };
      case 'success':
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle_outline,
        };
      case 'warning':
      default:
        return {
          'color': AppColors.warning,
          'icon': Icons.warning_amber_rounded,
        };
    }
  }

  void _showActionDialog(KpiAlert alert) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          alert.title,
          style: TextStyle(
            color: AppColors.getText(isDark),
          ),
        ),
        content: Text(
          alert.message,
          style: TextStyle(
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: تنفيذ الإجراء الفعلي
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(alert.action ?? 'تنفيذ'),
          ),
        ],
      ),
    );
  }
}