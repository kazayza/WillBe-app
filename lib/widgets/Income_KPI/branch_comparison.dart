import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/kpi_service.dart';

class BranchComparison extends StatefulWidget {
  final List<DistributionItem> branches;

  const BranchComparison({
    super.key,
    required this.branches,
  });

  @override
  State<BranchComparison> createState() => _BranchComparisonState();
}

class _BranchComparisonState extends State<BranchComparison> {
  int? _selectedBranch1;
  int? _selectedBranch2;
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');

  @override
  void initState() {
    super.initState();
    // اختيار أول فرعين تلقائياً
    if (widget.branches.length >= 2) {
      _selectedBranch1 = 0;
      _selectedBranch2 = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    if (widget.branches.length < 2) {
      return const SizedBox.shrink();
    }

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
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.compare,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة الفروع',
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
          // اختيار الفروع
          // ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildBranchSelector(
                  isDark: isDark,
                  label: 'الفرع الأول',
                  selectedIndex: _selectedBranch1,
                  color: AppColors.primary,
                  onChanged: (index) {
                    setState(() => _selectedBranch1 = index);
                  },
                  excludeIndex: _selectedBranch2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getBorder(isDark),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.getTextSecondary(isDark),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBranchSelector(
                  isDark: isDark,
                  label: 'الفرع الثاني',
                  selectedIndex: _selectedBranch2,
                  color: AppColors.secondary,
                  onChanged: (index) {
                    setState(() => _selectedBranch2 = index);
                  },
                  excludeIndex: _selectedBranch1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─────────────────────────────────────────────────
          // المقارنة
          // ─────────────────────────────────────────────────
          if (_selectedBranch1 != null && _selectedBranch2 != null)
            _buildComparisonContent(isDark),
        ],
      ),
    );
  }

  Widget _buildBranchSelector({
    required bool isDark,
    required String label,
    required int? selectedIndex,
    required Color color,
    required Function(int?) onChanged,
    required int? excludeIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: color),
              dropdownColor: AppColors.getCard(isDark),
              borderRadius: BorderRadius.circular(12),
              hint: Text(
                'اختر فرع',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              items: widget.branches.asMap().entries
                  .where((e) => e.key != excludeIndex)
                  .map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getText(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonContent(bool isDark) {
    final branch1 = widget.branches[_selectedBranch1!];
    final branch2 = widget.branches[_selectedBranch2!];

    // حساب الفائز في كل مؤشر
    final amountWinner = branch1.amount > branch2.amount ? 1 : 2;
    final transactionsWinner = branch1.transactions > branch2.transactions ? 1 : 2;
    final percentageWinner = branch1.percentage > branch2.percentage ? 1 : 2;

    return Column(
      children: [
        // ─────────────────────────────────────────────────
        // أسماء الفروع
        // ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildBranchHeader(
                name: branch1.name,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: _buildBranchHeader(
                name: branch2.name,
                color: AppColors.secondary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─────────────────────────────────────────────────
        // مقارنة الإيرادات
        // ─────────────────────────────────────────────────
        _buildComparisonRow(
          isDark: isDark,
          label: 'الإيرادات',
          icon: Icons.attach_money,
          value1: '${_currencyFormat.format(branch1.amount.round())} ج.م',
          value2: '${_currencyFormat.format(branch2.amount.round())} ج.م',
          winner: amountWinner,
          progress1: _getProgress(branch1.amount, branch2.amount),
          progress2: _getProgress(branch2.amount, branch1.amount),
        ),
        const SizedBox(height: 16),

        // ─────────────────────────────────────────────────
        // مقارنة العمليات
        // ─────────────────────────────────────────────────
        _buildComparisonRow(
          isDark: isDark,
          label: 'عدد العمليات',
          icon: Icons.receipt_long,
          value1: '${branch1.transactions}',
          value2: '${branch2.transactions}',
          winner: transactionsWinner,
          progress1: _getProgress(branch1.transactions.toDouble(), branch2.transactions.toDouble()),
          progress2: _getProgress(branch2.transactions.toDouble(), branch1.transactions.toDouble()),
        ),
        const SizedBox(height: 16),

        // ─────────────────────────────────────────────────
        // مقارنة النسبة
        // ─────────────────────────────────────────────────
        _buildComparisonRow(
          isDark: isDark,
          label: 'نسبة المساهمة',
          icon: Icons.pie_chart,
          value1: '${branch1.percentage.toStringAsFixed(1)}%',
          value2: '${branch2.percentage.toStringAsFixed(1)}%',
          winner: percentageWinner,
          progress1: branch1.percentage / 100,
          progress2: branch2.percentage / 100,
        ),
        const SizedBox(height: 24),

        // ─────────────────────────────────────────────────
        // النتيجة
        // ─────────────────────────────────────────────────
        _buildResultCard(isDark, branch1, branch2),
      ],
    );
  }

  Widget _buildBranchHeader({
    required String name,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildComparisonRow({
    required bool isDark,
    required String label,
    required IconData icon,
    required String value1,
    required String value2,
    required int winner,
    required double progress1,
    required double progress2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.getTextSecondary(isDark)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // الفرع الأول
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (winner == 1)
                        const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                      if (winner == 1) const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          value1,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: winner == 1
                                ? AppColors.primary
                                : AppColors.getText(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress1.clamp(0.0, 1.0),
                      backgroundColor: AppColors.getBorder(isDark),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            // الفرع الثاني
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (winner == 2)
                        const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                      if (winner == 2) const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          value2,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: winner == 2
                                ? AppColors.secondary
                                : AppColors.getText(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress2.clamp(0.0, 1.0),
                      backgroundColor: AppColors.getBorder(isDark),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                      minHeight: 6,
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

  Widget _buildResultCard(bool isDark, DistributionItem branch1, DistributionItem branch2) {
    // حساب الفائز الإجمالي
    int score1 = 0;
    int score2 = 0;

    if (branch1.amount > branch2.amount) {
      score1++;
    } else if (branch2.amount > branch1.amount) score2++;

    if (branch1.transactions > branch2.transactions) {
      score1++;
    } else if (branch2.transactions > branch1.transactions) score2++;

    if (branch1.percentage > branch2.percentage) {
      score1++;
    } else if (branch2.percentage > branch1.percentage) score2++;

    final winner = score1 > score2 ? branch1 : (score2 > score1 ? branch2 : null);
    final winnerColor = score1 > score2 ? AppColors.primary : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: winner != null
            ? LinearGradient(
                colors: [
                  winnerColor.withOpacity(0.1),
                  winnerColor.withOpacity(0.05),
                ],
              )
            : null,
        color: winner == null ? AppColors.getBorder(isDark).withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner != null
              ? winnerColor.withOpacity(0.3)
              : AppColors.getBorder(isDark),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (winner != null) ...[
            const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Text(
              '${winner.name} الأفضل أداءً',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: winnerColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: winnerColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${ score1 > score2 ? score1 : score2}/3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: winnerColor,
                ),
              ),
            ),
          ] else ...[
            Icon(Icons.balance, color: AppColors.getTextSecondary(isDark), size: 24),
            const SizedBox(width: 12),
            Text(
              'الفرعين متعادلين في الأداء',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.getText(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getProgress(double value1, double value2) {
    final max = value1 > value2 ? value1 : value2;
    if (max == 0) return 0;
    return value1 / max;
  }
}