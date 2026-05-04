import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class BranchesChart extends StatelessWidget {
  const BranchesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData || provider.kpiData!.branchesData.isEmpty) {
          return const SizedBox.shrink();
        }

        final branches = provider.kpiData!.branchesData;

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
                  Icon(Icons.business, color: Color(0xFF16A085), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'تحليل الفروع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // قائمة الفروع
              ...List.generate(branches.length, (index) {
                return _buildBranchItem(branches[index], index, branches);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchItem(
    BranchData branch,
    int index,
    List<BranchData> allBranches,
  ) {
    final maxAmount = allBranches.isNotEmpty
        ? allBranches.map((b) => b.current).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final barWidth = maxAmount > 0 ? (branch.current / maxAmount).clamp(0.0, 1.0) : 0.0;

    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
      const Color(0xFFE74C3C),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];

    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // الصف الأول: الاسم + المبلغ
          Row(
            children: [
              // أيقونة الترتيب
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // الاسم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${branch.percentOfTotal}% من الإجمالي',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),

              // المبلغ
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(branch.current)} ج.م',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // مقارنة بالسابق
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: branch.vsPrevious.isIncrease
                              ? const Color(0xFFE74C3C).withOpacity(0.1)
                              : const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${branch.vsPrevious.isIncrease ? '↑' : '↓'}${branch.vsPrevious.change.abs()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: branch.vsPrevious.isIncrease
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFF27AE60),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // مقارنة بالعام السابق
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: branch.vsLastYear.isIncrease
                              ? const Color(0xFFE67E22).withOpacity(0.1)
                              : const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'سنوي ${branch.vsLastYear.isIncrease ? '↑' : '↓'}${branch.vsLastYear.change.abs()}%',
                          style: TextStyle(
                            fontSize: 9,
                            color: branch.vsLastYear.isIncrease
                                ? const Color(0xFFE67E22)
                                : const Color(0xFF27AE60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // شريط النسبة
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barWidth,
              minHeight: 6,
              backgroundColor: const Color(0xFFECF0F1),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }
}