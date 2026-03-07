import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expenses_kpi_provider.dart';
import '../../models/expenses_kpi_model.dart';

class FinancialAnalysisCard extends StatefulWidget {
  const FinancialAnalysisCard({super.key});

  @override
  State<FinancialAnalysisCard> createState() => _FinancialAnalysisCardState();
}

class _FinancialAnalysisCardState extends State<FinancialAnalysisCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesKPIProvider>(
      builder: (context, provider, _) {
        if (!provider.hasData) return const SizedBox.shrink();

        final analysis = provider.kpiData!.financialAnalysis;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            border: Border.all(
              color: const Color(0xFF2C3E50).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // الهيدر
              _buildHeader(),

              // الملخص التنفيذي (دايماً ظاهر)
              _buildExecutiveSummary(analysis),

              // باقي التحليل (قابل للتوسيع)
              if (_isExpanded) ...[
                // تحليل الانحرافات
                if (analysis.deviationAnalysis.isNotEmpty)
                  _buildSection(
                    title: 'تحليل الانحرافات',
                    icon: Icons.compare_arrows,
                    color: const Color(0xFF3498DB),
                    items: analysis.deviationAnalysis,
                  ),

                // تحليل المخاطر
                if (analysis.riskAnalysis.isNotEmpty)
                  _buildSection(
                    title: 'تحليل المخاطر والتركز',
                    icon: Icons.warning_amber,
                    color: const Color(0xFFE74C3C),
                    items: analysis.riskAnalysis,
                  ),

                // النقاط الإيجابية
                if (analysis.positivePoints.isNotEmpty)
                  _buildSection(
                    title: 'النقاط الإيجابية',
                    icon: Icons.thumb_up,
                    color: const Color(0xFF27AE60),
                    items: analysis.positivePoints,
                  ),

                // التوقعات
                if (analysis.forecast.isNotEmpty)
                  _buildTextSection(
                    title: 'التوقعات',
                    icon: Icons.auto_graph,
                    color: const Color(0xFF8E44AD),
                    text: analysis.forecast,
                  ),

                // المقارنة السنوية
                if (analysis.yearComparison.isNotEmpty)
                  _buildTextSection(
                    title: 'المقارنة السنوية',
                    icon: Icons.calendar_today,
                    color: const Color(0xFFE67E22),
                    text: analysis.yearComparison,
                  ),

                // التوصيات
                if (analysis.recommendations.isNotEmpty)
                  _buildRecommendations(analysis.recommendations),
              ],

              // زر التوسيع
              _buildExpandButton(),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🔝 الهيدر
  // ════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C3E50),
            const Color(0xFF2C3E50).withOpacity(0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.description, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التحليل المالي للمصروفات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'تقرير تحليلي شامل للمصروفات',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📌 الملخص التنفيذي
  // ════════════════════════════════════════════════════════════
  Widget _buildExecutiveSummary(FinancialAnalysis analysis) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C3E50).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: Color(0xFF2C3E50),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'الملخص التنفيذي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            analysis.executiveSummary,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF34495E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📋 قسم بنقاط
  // ════════════════════════════════════════════════════════════
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // النقاط
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF34495E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📝 قسم نصي
  // ════════════════════════════════════════════════════════════
  Widget _buildTextSection({
    required String title,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF34495E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 💡 التوصيات
  // ════════════════════════════════════════════════════════════
  Widget _buildRecommendations(List<String> recommendations) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF27AE60).withOpacity(0.06),
            const Color(0xFF2ECC71).withOpacity(0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27AE60).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFF27AE60),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'التوصيات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27AE60),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // التوصيات
          ...List.generate(recommendations.length, (index) {
            return Container(
              margin: EdgeInsets.only(
                bottom: index < recommendations.length - 1 ? 10 : 0,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendations[index],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF34495E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🔽 زر التوسيع
  // ════════════════════════════════════════════════════════════
  Widget _buildExpandButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: _isExpanded
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'عرض أقل' : 'عرض التحليل الكامل',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF2C3E50),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}