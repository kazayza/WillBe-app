import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../services/kpi_service.dart';
import '../models/Income_kpi_analysis_models.dart';
import '../widgets/Income_KPI/kpi_header.dart';
import '../widgets/Income_KPI/trend_indicator.dart';
import '../widgets/Income_KPI/alerts_section.dart';
import '../widgets/Income_KPI/hero_card.dart';
import '../widgets/Income_KPI/kpi_cards.dart';
import '../widgets/Income_KPI/kpi_line_chart.dart';
import '../widgets/Income_KPI/kpi_comparison_table.dart';
import '../widgets/Income_KPI/branch_ranking.dart';
import '../widgets/Income_KPI/kpi_pie_chart.dart';
import '../widgets/Income_KPI/smart_summary.dart';
import '../widgets/Income_KPI/quick_actions.dart';
import '../widgets/Income_KPI/branch_comparison.dart';
import '../widgets/Income_KPI/monthly_comparison.dart';

class IncomeKpiScreen extends StatefulWidget {
  const IncomeKpiScreen({super.key});

  @override
  State<IncomeKpiScreen> createState() => _IncomeKpiScreenState();
}

class _IncomeKpiScreenState extends State<IncomeKpiScreen> {
  // ═══════════════════════════════════════════════════════════
  // 🎛️ الفلاتر
  // ═══════════════════════════════════════════════════════════
  late DateTime _fromDate;
  late DateTime _toDate;
  int? _branchId;
  int? _kindId;
  String _compareWith = 'previousPeriod';
  String _selectedPeriod = 'month';

  // ═══════════════════════════════════════════════════════════
  // 📊 حالة البيانات
  // ═══════════════════════════════════════════════════════════
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DashboardData? _dashboardData;
  PerformanceAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    // تعيين الفترة الافتراضية (الشهر الحالي)
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1); // أول يوم في الشهر
    _toDate = DateTime(now.year, now.month + 1, 0); // آخر يوم في الشهر
    _fetchData();
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 جلب البيانات
  // ═══════════════════════════════════════════════════════════
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final data = await KpiService.getDashboard(
        fromDate: _fromDate,
        toDate: _toDate,
        branchId: _branchId,
        kindId: _kindId,
        compareWith: _compareWith,
        groupBy: _selectedPeriod == 'year' ? 'monthly' : 'daily',
      );

      // حساب المبلغ السابق بشكل آمن
      double previousAmount = 0.0;
      if (data.mainKPIs.changes?.totalAmount != null &&
          data.mainKPIs.changes!.totalAmount != 0 &&
          data.mainKPIs.changes!.totalAmount! > -100 &&
          data.mainKPIs.totalAmount > 0) {
        final changePercent = data.mainKPIs.changes!.totalAmount!;
        previousAmount = data.mainKPIs.totalAmount / (1 + changePercent / 100);
      } else if (data.mainKPIs.totalAmount > 0) {
        previousAmount = data.mainKPIs.totalAmount * 0.9;
      }

      // حماية من القيم غير الصالحة
      if (previousAmount.isNaN || previousAmount.isInfinite || previousAmount < 0) {
        previousAmount = 0.0;
      }

      // توليد التحليل
      final analysis = PerformanceAnalysis.generate(
        currentKPIs: data.mainKPIs,
        branches: data.distributions.byBranch,
        previousAmount: previousAmount,
      );

      setState(() {
        _dashboardData = data;
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading Dashboard: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🎚️ تغيير الفلاتر
  // ═══════════════════════════════════════════════════════════
  void _onFilterChanged({
    DateTime? from,
    DateTime? to,
    int? branch,
    int? kind,
    String? compare,
    String? period,
  }) {
    setState(() {
      if (from != null) _fromDate = from;
      if (to != null) _toDate = to;
      if (branch != null) _branchId = branch == -1 ? null : branch;
      if (kind != null) _kindId = kind == -1 ? null : kind;
      if (compare != null) _compareWith = compare;
      if (period != null) _selectedPeriod = period;
    });
    _fetchData();
  }

  // ═══════════════════════════════════════════════════════════
  // 🏗️ بناء الواجهة
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // الهيدر والفلاتر
            SliverToBoxAdapter(
              child: KpiHeader(
                fromDate: _fromDate,
                toDate: _toDate,
                selectedPeriod: _selectedPeriod,
                selectedBranch: _branchId,
                selectedKind: _kindId,
                compareWith: _compareWith,
                onFilterChanged: _onFilterChanged,
              ),
            ),

            // المحتوى
            if (_isLoading)
              _buildLoading(isDark)
            else if (_hasError)
              _buildError(isDark)
            else if (_dashboardData != null && _analysis != null)
              _buildContent(isDark)
            else
              _buildEmpty(isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 حالة التحميل
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoading(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSkeletonBox(isDark, height: 80),
            const SizedBox(height: 16),
            _buildSkeletonBox(isDark, height: 180),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(isDark, height: 140)),
                const SizedBox(width: 12),
                Expanded(child: _buildSkeletonBox(isDark, height: 140)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSkeletonBox(isDark, height: 250),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(bool isDark, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary.withOpacity(0.5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ❌ حالة الخطأ
  // ═══════════════════════════════════════════════════════════
  Widget _buildError(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'حدث خطأ في تحميل البيانات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📭 حالة عدم وجود بيانات
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmpty(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getTextSecondary(isDark).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 50,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفترة أو الفلاتر',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 المحتوى الرئيسي
  // ═══════════════════════════════════════════════════════════
  Widget _buildContent(bool isDark) {
    final data = _dashboardData!;
    final analysis = _analysis!;

    // ═══════════════════════════════════════════════════════════
    // 🛡️ حماية البيانات من القيم الفارغة أو غير الصالحة
    // ═══════════════════════════════════════════════════════════

    // استخراج بيانات الـ Sparkline مع حماية
    List<double> sparklineData = [];
    List<double> transactionsSparkline = [];

    if (data.chartData.isNotEmpty) {
      sparklineData = data.chartData
          .map((e) => e.amount)
          .where((a) => a.isFinite)
          .toList();
      transactionsSparkline = data.chartData
          .map((e) => e.transactions.toDouble())
          .where((t) => t.isFinite)
          .toList();
    }

    // حساب المبلغ السابق للمقارنة مع حماية
    double previousAmount = 0.0;

    if (data.mainKPIs.changes?.totalAmount != null &&
        data.mainKPIs.changes!.totalAmount != 0 &&
        data.mainKPIs.changes!.totalAmount! > -100 &&
        data.mainKPIs.totalAmount > 0) {
      final changePercent = data.mainKPIs.changes!.totalAmount!;
      previousAmount = data.mainKPIs.totalAmount / (1 + changePercent / 100);
    } else if (data.mainKPIs.totalAmount > 0) {
      previousAmount = data.mainKPIs.totalAmount * 0.9;
    }

    // حماية من NaN و Infinity
    if (previousAmount.isNaN || previousAmount.isInfinite || previousAmount < 0) {
      previousAmount = 0.0;
    }

    // حماية نسبة التغيير
    final safeChangePercent = (data.mainKPIs.changes?.totalAmount ?? 0).isFinite
        ? (data.mainKPIs.changes?.totalAmount ?? 0)
        : 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─────────────────────────────────────────────────
            // 1. مؤشر الاتجاه
            // ─────────────────────────────────────────────────
            TrendIndicator(
              trend: analysis.trend,
              changePercent: analysis.changePercent.isFinite
                  ? analysis.changePercent
                  : 0.0,
              sparklineData: sparklineData,
            ),
            const SizedBox(height: 16),

            // ─────────────────────────────────────────────────
            // 2. التنبيهات
            // ─────────────────────────────────────────────────
            if (analysis.alerts.isNotEmpty) ...[
              AlertsSection(alerts: analysis.alerts),
              const SizedBox(height: 16),
            ],

            // ─────────────────────────────────────────────────
            // 3. البطاقة الرئيسية (Hero Card)
            // ─────────────────────────────────────────────────
            HeroCard(
              totalAmount: data.mainKPIs.totalAmount,
              previousAmount: previousAmount,
              changePercent: safeChangePercent,
              sparklineData: sparklineData,
              compareWith: _compareWith,
              fromDate: _fromDate,
              toDate: _toDate,
            ),
            const SizedBox(height: 16),

            // ─────────────────────────────────────────────────
            // 4. البطاقات الفرعية
            // ─────────────────────────────────────────────────
            KpiCards(
              data: _mainKPIsToMap(data.mainKPIs),
              revenueSparkline: sparklineData,
              transactionsSparkline: transactionsSparkline,
              avgSparkline: sparklineData,
            ),
            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────
            // 5. الرسم البياني
            // ─────────────────────────────────────────────────
            if (data.chartData.isNotEmpty) ...[
              KpiLineChart(
                data: _chartDataToMap(data.chartData),
                period: _selectedPeriod,
                compareWith: _compareWith,
              ),
              const SizedBox(height: 20),
            ],

            // ─────────────────────────────────────────────────
            // 6. جدول المقارنة
            // ─────────────────────────────────────────────────
            KpiComparisonTable(
              data: _comparisonDataToMap(data.mainKPIs, previousAmount),
            ),
            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────
            // 7. ترتيب الفروع
            // ─────────────────────────────────────────────────
            if (data.distributions.byBranch.isNotEmpty) ...[
              BranchRanking(branches: data.distributions.byBranch),
              const SizedBox(height: 20),
            ],

            // ─────────────────────────────────────────────────
// 8. مقارنة الفروع (جديد)
// ─────────────────────────────────────────────────
if (data.distributions.byBranch.length >= 2) ...[
  BranchComparison(branches: data.distributions.byBranch),
  const SizedBox(height: 20),
],

// ─────────────────────────────────────────────────
// 9. مقارنة الشهور (جديد)
// ─────────────────────────────────────────────────
if (_selectedPeriod == 'year' && data.chartData.isNotEmpty) ...[
  MonthlyComparison(
    monthsData: _convertToMonthData(data.chartData),
    currentYear: _fromDate.year,
  ),
  const SizedBox(height: 20),
],
            // ─────────────────────────────────────────────────
            // 10. التوزيعات (Pie Charts)
            // ─────────────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      if (data.distributions.byKind.isNotEmpty)
                        KpiPieChart(
                          title: 'توزيع الأنواع',
                          data: _distributionToList(data.distributions.byKind),
                          keyName: 'kindName',
                          icon: Icons.category,
                        ),
                      if (data.distributions.byKind.isNotEmpty)
                        const SizedBox(height: 16),
                      if (data.distributions.byBranch.isNotEmpty)
                        KpiPieChart(
                          title: 'توزيع الفروع',
                          data: _distributionToList(data.distributions.byBranch),
                          keyName: 'branchName',
                          icon: Icons.business,
                        ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.distributions.byKind.isNotEmpty)
                      Expanded(
                        child: KpiPieChart(
                          title: 'توزيع الأنواع',
                          data: _distributionToList(data.distributions.byKind),
                          keyName: 'kindName',
                          icon: Icons.category,
                        ),
                      ),
                    if (data.distributions.byKind.isNotEmpty &&
                        data.distributions.byBranch.isNotEmpty)
                      const SizedBox(width: 16),
                    if (data.distributions.byBranch.isNotEmpty)
                      Expanded(
                        child: KpiPieChart(
                          title: 'توزيع الفروع',
                          data: _distributionToList(data.distributions.byBranch),
                          keyName: 'branchName',
                          icon: Icons.business,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────
            // 11. الملخص التنفيذي الذكي
            // ─────────────────────────────────────────────────
            SmartSummary(
              analysis: analysis,
              totalAmount: data.mainKPIs.totalAmount,
              activeDays: data.mainKPIs.activeDays,
              compareWith: _compareWith,
              fromDate: _fromDate,
              toDate: _toDate,
            ),
            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────
            // 12. الإجراءات السريعة
            // ─────────────────────────────────────────────────
            QuickActions(
              totalAmount: data.mainKPIs.totalAmount,
              totalTransactions: data.mainKPIs.totalTransactions,
              changePercent: safeChangePercent,
              period: _getPeriodText(),
              dashboardData: data,
              fromDate: _fromDate,
              toDate: _toDate,
              onRefresh: _fetchData,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 تحويل البيانات
  // ═══════════════════════════════════════════════════════════

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'year':
        return 'هذه السنة';
      default:
        return 'فترة مخصصة';
    }
  }

  Map<String, dynamic> _mainKPIsToMap(MainKPIs kpis) {
    return {
      'totalAmount': kpis.totalAmount,
      'totalTransactions': kpis.totalTransactions,
      'avgTransaction': kpis.avgTransaction,
      'dailyAverage': kpis.dailyAverage,
      'maxTransaction': kpis.maxTransaction,
      'minTransaction': kpis.minTransaction,
      'uniqueChildren': kpis.uniqueChildren,
      'activeDays': kpis.activeDays,
      'changes': kpis.changes != null
          ? {
              'totalAmount': kpis.changes!.totalAmount,
              'totalTransactions': kpis.changes!.totalTransactions,
              'avgTransaction': kpis.changes!.avgTransaction,
              'dailyAverage': kpis.changes!.dailyAverage,
            }
          : null,
    };
  }

  Map<String, dynamic> _chartDataToMap(List<ChartPoint> chartData) {
  // البيانات الحالية
  final currentData = chartData
      .map((e) => {
            'period': e.period,
            'year': e.year,
            'transactions': e.transactions,
            'amount': e.amount,
          })
      .toList();

  // حساب بيانات الفترة السابقة (Simulated)
  // نفترض إن الفترة السابقة كانت أقل بنسبة عشوائية
  final previousData = chartData
      .map((e) {
        // نستخدم نسبة التغيير لو موجودة، أو نفترض 10% أقل
        final changePercent = _dashboardData?.mainKPIs.changes?.totalAmount ?? 10.0;
        final factor = 1 + (changePercent / 100);
        final previousAmount = factor != 0 ? e.amount / factor : e.amount * 0.9;
        
        return {
          'period': e.period,
          'year': e.year != null ? e.year! - 1 : null,
          'transactions': (e.transactions / (factor != 0 ? factor : 1.1)).round(),
          'amount': previousAmount.isFinite ? previousAmount : e.amount * 0.9,
        };
      })
      .toList();

  return {
    'current': currentData,
    'previous': previousData,
  };
}

  Map<String, dynamic> _comparisonDataToMap(
      MainKPIs current, double previousAmount) {
    // حماية من القسمة على صفر
    double prevTransactions = 0.0;
    double prevAvg = 0.0;

    if (current.changes?.totalTransactions != null &&
        current.changes!.totalTransactions != -100) {
      prevTransactions = current.totalTransactions /
          (1 + current.changes!.totalTransactions! / 100);
    } else {
      prevTransactions = current.totalTransactions * 0.9;
    }

    if (current.changes?.avgTransaction != null &&
        current.changes!.avgTransaction != -100) {
      prevAvg =
          current.avgTransaction / (1 + current.changes!.avgTransaction! / 100);
    } else {
      prevAvg = current.avgTransaction * 0.9;
    }

    // حماية من القيم غير الصالحة
    if (prevTransactions.isNaN || prevTransactions.isInfinite) {
      prevTransactions = 0.0;
    }
    if (prevAvg.isNaN || prevAvg.isInfinite) {
      prevAvg = 0.0;
    }

    return {
      'current': {
        'totalAmount': current.totalAmount,
        'transactions': current.totalTransactions,
        'avgAmount': current.avgTransaction,
        'maxAmount': current.maxTransaction,
      },
      'previous': {
        'totalAmount': previousAmount,
        'transactions': prevTransactions.round(),
        'avgAmount': prevAvg,
        'maxAmount': current.maxTransaction * 0.9,
      },
      'changes': {
        'totalAmount': current.changes?.totalAmount ?? 0,
        'transactions': current.changes?.totalTransactions ?? 0,
        'avgAmount': current.changes?.avgTransaction ?? 0,
        'maxAmount': 10.0,
      },
    };
  }

  List<Map<String, dynamic>> _distributionToList(List<DistributionItem> items) {
    return items
        .map((e) => {
              'kindId': e.id,
              'branchId': e.id,
              'kindName': e.name,
              'branchName': e.name,
              'transactions': e.transactions,
              'amount': e.amount,
              'percentage': e.percentage,
            })
        .toList();
  }
  
  // ═══════════════════════════════════════════════════════════
// 📅 تحويل بيانات الرسم البياني لبيانات الشهور
// ═══════════════════════════════════════════════════════════
List<MonthData> _convertToMonthData(List<ChartPoint> chartData) {
  return chartData.map((point) {
    int month = 1;
    if (point.period is int) {
      month = point.period as int;
    } else if (point.period is String) {
      // محاولة استخراج رقم الشهر من النص
      final parsed = int.tryParse(point.period.toString());
      if (parsed != null && parsed >= 1 && parsed <= 12) {
        month = parsed;
      }
    }
    return MonthData(
      month: month.clamp(1, 12),
      amount: point.amount.isFinite ? point.amount : 0.0,
      transactions: point.transactions,
    );
  }).toList();
}

}