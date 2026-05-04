import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';
import 'kpi_theme.dart';

class GroupsChart extends StatelessWidget {
  const GroupsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KPITheme.of(context);

    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData || provider.kpiData!.groupsData.isEmpty) {
          return const SizedBox.shrink();
        }

        final groups = provider.kpiData!.groupsData;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: theme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                children: [
                  Icon(Icons.bar_chart, color: theme.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'تحليل المجموعات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // مفتاح الألوان
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot('الحالي', theme.info, theme),
                  const SizedBox(width: 12),
                  _buildLegendDot('السابق', theme.textMuted, theme),
                  const SizedBox(width: 12),
                  _buildLegendDot('العام السابق', theme.warning, theme),
                ],
              ),

              const SizedBox(height: 14),

              // ✅ عرض المجموعات كقائمة أفقية واضحة
              ...List.generate(groups.length, (index) {
                return _buildGroupItem(groups[index], index, groups, theme);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupItem(
    GroupData group,
    int index,
    List<GroupData> allGroups,
    KPITheme theme,
  ) {
    final maxAmount = allGroups
        .map((g) => g.current)
        .reduce((a, b) => a > b ? a : b);
    final barWidth = maxAmount > 0
        ? (group.current / maxAmount).clamp(0.0, 1.0)
        : 0.0;

    final prevBarWidth = maxAmount > 0
        ? (group.vsPrevious.amount / maxAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.sectionBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف الأول: اسم المجموعة + التغير
          Row(
            children: [
              Expanded(
                child: Text(
                  group.group,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              // نسبة التغير عن السابق
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: group.vsPrevious.isIncrease
                      ? theme.negativeLight
                      : theme.positiveLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      group.vsPrevious.isIncrease
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 12,
                      color: group.vsPrevious.isIncrease
                          ? theme.negative
                          : theme.positive,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${group.vsPrevious.change.abs()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: group.vsPrevious.isIncrease
                            ? theme.negative
                            : theme.positive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // الأرقام
          Row(
            children: [
              // الحالي
              Expanded(
                child: _buildAmountLabel(
                  label: 'الحالي',
                  amount: group.current,
                  color: theme.info,
                  theme: theme,
                ),
              ),
              // السابق
              Expanded(
                child: _buildAmountLabel(
                  label: 'السابق',
                  amount: group.vsPrevious.amount,
                  color: theme.textMuted,
                  theme: theme,
                ),
              ),
              // العام السابق
              Expanded(
                child: _buildAmountLabel(
                  label: 'سنوي',
                  amount: group.vsLastYear.amount,
                  color: theme.warning,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // شريط الحالي
          _buildProgressBar(barWidth, theme.info),
          const SizedBox(height: 4),
          // شريط السابق
          _buildProgressBar(prevBarWidth, theme.textMuted.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _buildAmountLabel({
    required String label,
    required double amount,
    required Color color,
    required KPITheme theme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: theme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          _formatNumber(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'ج.م',
          style: TextStyle(fontSize: 9, color: theme.textMuted),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 5,
        backgroundColor: color.withOpacity(0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color, KPITheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: theme.textSecondary),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}