import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/kpi_service.dart';

class BranchRanking extends StatelessWidget {
  final List<DistributionItem> branches;

  const BranchRanking({
    super.key,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final currency = NumberFormat('#,###', 'ar_EG');

    if (branches.isEmpty) {
      return const SizedBox.shrink();
    }

    // ترتيب الفروع حسب المبلغ
    final sortedBranches = List<DistributionItem>.from(branches)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final maxAmount = sortedBranches.first.amount;

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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ترتيب الفروع',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getText(isDark),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${branches.length} فرع',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // قائمة الفروع
          // ─────────────────────────────────────────────────
          ...sortedBranches.asMap().entries.map((entry) {
            final index = entry.key;
            final branch = entry.value;
            final progress = maxAmount > 0 ? branch.amount / maxAmount : 0.0;

            return _buildBranchItem(
              rank: index + 1,
              name: branch.name,
              amount: currency.format(branch.amount.round()),
              percentage: branch.percentage,
              progress: progress,
              isDark: isDark,
              isLast: index == sortedBranches.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBranchItem({
    required int rank,
    required String name,
    required String amount,
    required double percentage,
    required double progress,
    required bool isDark,
    required bool isLast,
  }) {
    // ألوان الميداليات للـ Top 3
    Color? medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // ذهبي
      medalIcon = Icons.workspace_premium;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // فضي
      medalIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // برونزي
      medalIcon = Icons.workspace_premium;
    }

    final progressColor = _getProgressColor(rank);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        children: [
          Row(
            children: [
              // ─────────────────────────────────────────────────
              // الترتيب / الميدالية
              // ─────────────────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: medalColor?.withOpacity(0.2) ??
                      AppColors.getBorder(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: medalIcon != null
                      ? Icon(
                          medalIcon,
                          color: medalColor,
                          size: 20,
                        )
                      : Text(
                          '$rank',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // ─────────────────────────────────────────────────
              // اسم الفرع
              // ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.getText(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$amount ج.م',
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ─────────────────────────────────────────────────
              // النسبة المئوية
              // ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─────────────────────────────────────────────────
          // شريط التقدم
          // ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  width: double.infinity,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor,
                            progressColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // ذهبي
      case 2:
        return const Color(0xFF94A3B8); // فضي
      case 3:
        return const Color(0xFFCD7F32); // برونزي
      default:
        return AppColors.primary;
    }
  }
}