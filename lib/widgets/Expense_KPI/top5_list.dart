import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';

class Top5List extends StatelessWidget {
  const Top5List({super.key});

  static const List<Color> _rankColors = [
    Color(0xFFFFD700), // ذهبي
    Color(0xFFC0C0C0), // فضي
    Color(0xFFCD7F32), // برونزي
    Color(0xFF3498DB), // أزرق
    Color(0xFF95A5A6), // رمادي
  ];

  static const List<String> _rankIcons = ['🥇', '🥈', '🥉', '4', '5'];

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData || provider.kpiData!.top5Expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        final top5 = provider.kpiData!.top5Expenses;

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
                  Icon(Icons.emoji_events, color: Color(0xFFf39c12), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'أعلى 5 بنود مصروفات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // القائمة
              ...List.generate(top5.length, (index) {
                final item = top5[index];
                return _buildItem(item, index);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(dynamic item, int index) {
    const maxPercent = 100.0;
    final barWidth = (item.percent / maxPercent).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: index < 4 ? 10 : 0),
      child: Column(
        children: [
          Row(
            children: [
              // الترتيب
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _rankColors[index].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: index < 3
                    ? Text(
                        _rankIcons[index],
                        style: const TextStyle(fontSize: 16),
                      )
                    : Text(
                        _rankIcons[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _rankColors[index],
                        ),
                      ),
              ),

              const SizedBox(width: 10),

              // الاسم والمجموعة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.group} • ${item.transactions} معاملة',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),

              // المبلغ والنسبة
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(item.amount)} ج.م',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    '${item.percent}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: _rankColors[index],
                      fontWeight: FontWeight.bold,
                    ),
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
              minHeight: 4,
              backgroundColor: const Color(0xFFECF0F1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _rankColors[index].withOpacity(0.7),
              ),
            ),
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