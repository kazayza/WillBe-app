import 'package:flutter/material.dart';

class KpiTrends extends StatelessWidget {
  final Map<String, dynamic> data;

  const KpiTrends({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final insights = data['insights'] ?? {};
    final bestDay = insights['bestDay'] ?? {};
    final worstDay = insights['worstDay'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليل الاتجاهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildTrendItem(
            'أفضل يوم للتحصيل',
            bestDay['dayName'] ?? '-',
            Icons.thumb_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'أقل يوم تحصيل',
            worstDay['dayName'] ?? '-',
            Icons.thumb_down,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}