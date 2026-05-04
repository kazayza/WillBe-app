import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/debt_provider.dart';
import '../providers/children_provider.dart';
import '../providers/theme_provider.dart';

class AdvancedKPIScreen extends StatefulWidget {
  const AdvancedKPIScreen({super.key});

  @override
  State<AdvancedKPIScreen> createState() => _AdvancedKPIScreenState();
}

class _AdvancedKPIScreenState extends State<AdvancedKPIScreen> {
  int? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final cp = Provider.of<ChildrenProvider>(context, listen: false);
    if (cp.sessions.isEmpty) await cp.fetchSessions();
    if (cp.branches.isEmpty) await cp.fetchBranches();

    if (cp.sessions.isNotEmpty) {
      final current = cp.sessions.firstWhere(
        (s) => s['IDSession'] == 4,
        orElse: () => cp.sessions.first,
      );
      setState(() => _selectedSessionId = current['IDSession']);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selectedSessionId != null) {
      await Provider.of<DebtProvider>(context, listen: false)
          .fetchAdvancedKPIs(_selectedSessionId!);
    }
  }

  double _safe(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  String _formatCurrency(dynamic amount) {
    double val = _safe(amount);
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  // ═══════════════════════ الألوان ═══════════════════════
  static const _primary = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);
  static const _blue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DebtProvider>(context);
    final cp = Provider.of<ChildrenProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final data = dp.advancedKpiData;
    final screenWidth = MediaQuery.of(context).size.width;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ═══════════ App Bar ═══════════
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: _primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('💳 تحليل المدفوعات والأقساط',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // ═══════════ الفلاتر ═══════════
          SliverToBoxAdapter(
            child: _buildFilters(cp, dp, isDark, cardColor, textColor, screenWidth),
          ),

          // ═══════════ المحتوى ═══════════
          if (dp.isAdvancedKpiLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else if (data == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_outlined, size: 64, color: subText),
                    const SizedBox(height: 16),
                    Text('اختر العام المالي لعرض المؤشرات',
                        style: TextStyle(color: subText, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMainSummary(data['general'], isDark, screenWidth),
                  const SizedBox(height: 12),

                  _buildStatsGrid(data['general'], isDark, cardColor, textColor, screenWidth),
                  const SizedBox(height: 12),

if (data['types'] != null && (data['types'] as List).isNotEmpty)
  _buildTypesComparison(
    data['types'],
    data['branches'],
    isDark,
    cardColor,
    textColor,
    screenWidth,
  ),
                  const SizedBox(height: 12),

                  if (data['branches'] != null && (data['branches'] as List).isNotEmpty)
                    _buildBranchesSection(data['branches'], isDark, cardColor, textColor),
                  const SizedBox(height: 12),

                  if (data['monthly'] != null && (data['monthly'] as List).isNotEmpty)
                    _buildMonthlyChart(data['monthly'], isDark, cardColor, textColor, screenWidth),
                  const SizedBox(height: 12),

                  _buildInsightsSection(dp.advancedInsights, isDark, cardColor, textColor),
                  const SizedBox(height: 12),

                  if (data['topDebtors'] != null && (data['topDebtors'] as List).isNotEmpty)
                    _buildTopDebtors(data['topDebtors'], isDark, cardColor, textColor, screenWidth),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                     الفلاتر
  // ═══════════════════════════════════════════════════════════
  Widget _buildFilters(ChildrenProvider cp, DebtProvider dp, bool isDark,
      Color cardColor, Color textColor, double screenWidth) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔍 الفلاتر',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 10),

          // العام المالي + الفرع
          screenWidth < 360
              ? Column(
                  children: [
                    _buildStyledDropdown<int>(
                      value: _selectedSessionId,
                      hint: 'العام المالي',
                      icon: Icons.calendar_today_rounded,
                      items: cp.sessions
                          .map((s) => DropdownMenuItem<int>(
                              value: s['IDSession'],
                              child: Text(s['Sessions'],
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedSessionId = v);
                        _loadData();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildStyledDropdown<int>(
                      value: dp.kpiSelectedBranchId,
                      hint: 'كل الفروع',
                      icon: Icons.store_rounded,
                      items: [
                        const DropdownMenuItem<int>(
                            value: null,
                            child: Text('كل الفروع',
                                style: TextStyle(fontSize: 12))),
                        ...cp.branches.map((b) => DropdownMenuItem<int>(
                            value: b['IDbranch'],
                            child: Text(b['branchName'],
                                style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (v) {
                        if (_selectedSessionId != null) {
                          dp.setKpiBranchFilter(v, _selectedSessionId!);
                        }
                      },
                      isDark: isDark,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildStyledDropdown<int>(
                        value: _selectedSessionId,
                        hint: 'العام المالي',
                        icon: Icons.calendar_today_rounded,
                        items: cp.sessions
                            .map((s) => DropdownMenuItem<int>(
                                value: s['IDSession'],
                                child: Text(s['Sessions'],
                                    style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedSessionId = v);
                          _loadData();
                        },
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStyledDropdown<int>(
                        value: dp.kpiSelectedBranchId,
                        hint: 'كل الفروع',
                        icon: Icons.store_rounded,
                        items: [
                          const DropdownMenuItem<int>(
                              value: null,
                              child: Text('كل الفروع',
                                  style: TextStyle(fontSize: 12))),
                          ...cp.branches.map((b) => DropdownMenuItem<int>(
                              value: b['IDbranch'],
                              child: Text(b['branchName'],
                                  style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (v) {
                          if (_selectedSessionId != null) {
                            dp.setKpiBranchFilter(v, _selectedSessionId!);
                          }
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 10),

          // نوع الاشتراك
          Row(
            children: [
              _buildTypeChip('الكل', Icons.apps_rounded, dp, isDark),
              const SizedBox(width: 6),
              _buildTypeChip('دراسة', Icons.menu_book_rounded, dp, isDark),
              const SizedBox(width: 6),
              _buildTypeChip('باص', Icons.directions_bus_rounded, dp, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 14, color: _primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(hint,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[400]),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, DebtProvider dp, bool isDark) {
    final isSelected = dp.kpiSelectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedSessionId != null) {
            dp.setKpiTypeFilter(label, _selectedSessionId!);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? _primary : Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                   الملخص الرئيسي
  // ═══════════════════════════════════════════════════════════
  Widget _buildMainSummary(Map? data, bool isDark, double screenWidth) {
    if (data == null) return const SizedBox();
    double rate = _safe(data['collectionRate']);
    double totalPaid = _safe(data['totalPaid']);
    double totalRequired = _safe(data['totalRequired']);
    double remaining = _safe(data['remaining']);

    String rateLabel = rate > 80
        ? 'أداء ممتاز 🚀'
        : rate > 50
            ? 'أداء متوسط ⚡'
            : 'يحتاج متابعة 🚨';

    double circleSize = screenWidth < 360 ? 70 : 90;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // النسبة الدائرية
              SizedBox(
                height: circleSize,
                width: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: circleSize - 10,
                      width: circleSize - 10,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    SizedBox(
                      height: circleSize - 10,
                      width: circleSize - 10,
                      child: CircularProgressIndicator(
                        value: (rate / 100).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text('${rate.toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 16 : 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نسبة التحصيل الإجمالية',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth < 360 ? 11 : 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(rateLabel,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 360 ? 10 : 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow('المطلوب', _formatCurrency(totalRequired),
                        Colors.white70, screenWidth),
                    _buildSummaryRow(
                        'المحصّل', _formatCurrency(totalPaid), _green, screenWidth),
                    _buildSummaryRow(
                        'المتبقي', _formatCurrency(remaining), _orange, screenWidth),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, Color valueColor, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: screenWidth < 360 ? 10 : 12)),
          Flexible(
            child: Text('$value ج.م',
                style: TextStyle(
                    color: valueColor,
                    fontSize: screenWidth < 360 ? 11 : 13,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                   الكروت الإحصائية
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatsGrid(
      Map? data, bool isDark, Color cardColor, Color textColor, double screenWidth) {
    if (data == null) return const SizedBox();

    final stats = [
      {'title': 'إجمالي الطلاب', 'value': '${data['totalChildren']}', 'icon': Icons.people_rounded, 'color': _blue},
      {'title': 'مسددين بالكامل', 'value': '${data['paidFullCount']}', 'icon': Icons.check_circle_rounded, 'color': _green},
      {'title': 'أقساط متأخرة', 'value': '${data['overdueInstallments']}', 'icon': Icons.warning_rounded, 'color': _red},
      {'title': 'سداد جزئي', 'value': '${data['partialPayCount']}', 'icon': Icons.hourglass_bottom_rounded, 'color': _orange},
      {'title': 'متوسط التأخير', 'value': '${data['avgDaysLate']} يوم', 'icon': Icons.timer_rounded, 'color': Colors.purple},
      {'title': 'أقساط قادمة', 'value': '${data['upcomingInstallments']}', 'icon': Icons.event_rounded, 'color': Colors.teal},
    ];

    int crossAxisCount = screenWidth < 360 ? 2 : 3;
    double childAspectRatio = screenWidth < 360 ? 1.3 : 1.2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat['icon'] as IconData,
                    color: stat['color'] as Color, size: 18),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(stat['value'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(stat['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //                مقارنة الاشتراكات
  // ═══════════════════════════════════════════════════════════
Widget _buildTypesComparison(
    List typesData, List? branchesData, bool isDark, Color cardColor, 
    Color textColor, double screenWidth) {
  return Container(
    padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        Row(
          children: [
            const Icon(Icons.compare_arrows_rounded,
                color: _primary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text('مقارنة الاشتراكات',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const Divider(height: 20),

        // الكارتين الرئيسيين (دراسة vs باص)
        Row(
          children: typesData.map((t) {
            double rate = _safe(t['collectionRate']);
            bool isStudy = t['Kind_subscrip'].toString().contains('الدراسة');
            double required = _safe(t['totalRequired']);
            double paid = _safe(t['totalPaid']);

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    left: isStudy ? 0 : 4, right: isStudy ? 4 : 0),
                padding: EdgeInsets.all(screenWidth < 360 ? 10 : 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isStudy
                            ? Icons.menu_book_rounded
                            : Icons.directions_bus_rounded,
                        color: isStudy ? _blue : _orange,
                        size: screenWidth < 360 ? 22 : 26),
                    const SizedBox(height: 6),
                    FittedBox(
                      child: Text(isStudy ? 'الدراسة' : 'الباص',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      child: Text('${rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: rate > 70 ? _green : _orange)),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      child: Text('${t['totalChildren']} طالب',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500])),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (rate / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(
                            rate > 70 ? _green : _orange),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // تفاصيل المبالغ
                    _buildMiniRow('المطلوب', _formatCurrency(required),
                        textColor, screenWidth),
                    _buildMiniRow('المحصل', _formatCurrency(paid),
                        _green, screenWidth),
                    _buildMiniRow(
                        'المتبقي',
                        _formatCurrency(required - paid),
                        _red,
                        screenWidth),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // جدول تفصيل الفروع
        if (branchesData != null && branchesData.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_rounded,
                        size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text('تفصيل الفروع',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                  ],
                ),
                const SizedBox(height: 10),
                // رأس الجدول
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('الفرع',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textColor))),
                      Expanded(
                          flex: 2,
                          child: Text('📚 دراسة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textColor))),
                      Expanded(
                          flex: 2,
                          child: Text('🚌 باص',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textColor))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // صفوف الفروع
                ...branchesData.map((branch) {
                  double studyRate = _safe(branch['studyRate']);
                  double busRate = _safe(branch['busRate']);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            branch['branchName'] ?? '',
                            style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text('${studyRate.toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: studyRate > 70
                                          ? _green
                                          : studyRate > 50
                                              ? _orange
                                              : _red)),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (studyRate / 100).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor:
                                      Colors.grey.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation(
                                      studyRate > 70
                                          ? _green
                                          : studyRate > 50
                                              ? _orange
                                              : _red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text('${busRate.toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: busRate > 70
                                          ? _green
                                          : busRate > 50
                                              ? _orange
                                              : _red)),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (busRate / 100).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor:
                                      Colors.grey.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation(
                                      busRate > 70
                                          ? _green
                                          : busRate > 50
                                              ? _orange
                                              : _red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // تحليل نصي
                const SizedBox(height: 8),
                _buildBranchTypeInsight(branchesData, textColor),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// صف صغير للمبالغ
Widget _buildMiniRow(
    String label, String value, Color valueColor, double screenWidth) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: screenWidth < 360 ? 8 : 9,
                color: Colors.grey[500])),
        Flexible(
          child: Text('$value ج.م',
              style: TextStyle(
                  fontSize: screenWidth < 360 ? 9 : 10,
                  fontWeight: FontWeight.bold,
                  color: valueColor),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

// تحليل نصي للفروع حسب النوع
Widget _buildBranchTypeInsight(List data, Color textColor) {
  if (data.isEmpty) return const SizedBox();

  // أفضل فرع في الدراسة
  var bestStudy = data.reduce((a, b) =>
      _safe(a['studyRate']) > _safe(b['studyRate']) ? a : b);
  // أفضل فرع في الباص
  var bestBus = data.reduce((a, b) =>
      _safe(a['busRate']) > _safe(b['busRate']) ? a : b);

  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'أفضل فرع في الدراسة: "${bestStudy['branchName']}" بنسبة ${_safe(bestStudy['studyRate']).toStringAsFixed(0)}% | '
            'أفضل فرع في الباص: "${bestBus['branchName']}" بنسبة ${_safe(bestBus['busRate']).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, color: textColor, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

  // ═══════════════════════════════════════════════════════════
  //                    أداء الفروع
  // ═══════════════════════════════════════════════════════════
  Widget _buildBranchesSection(
      List data, bool isDark, Color cardColor, Color textColor) {
    data.sort((a, b) =>
        _safe(b['collectionRate']).compareTo(_safe(a['collectionRate'])));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded, color: _primary, size: 18),
              const SizedBox(width: 6),
              Text('أداء الفروع',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ],
          ),
          const Divider(height: 20),
          ...data.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            double rate = _safe(b['collectionRate']);
            Color barColor = rate > 80 ? _green : rate > 50 ? _orange : _red;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Colors.amber
                          : i == 1
                              ? Colors.grey[400]
                              : i == 2
                                  ? Colors.brown[300]
                                  : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(b['branchName'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('${rate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: barColor,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (rate / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: barColor.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(barColor),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                  '${b['totalChildren']} طالب | ${b['overdueChildren'] ?? 0} متأخر',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Flexible(
                              child: Text(
                                  'متبقي: ${_formatCurrency(b['remaining'])}',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          // التحليل
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getBranchInsight(data),
                    style: TextStyle(
                        fontSize: 11, color: textColor, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBranchInsight(List data) {
    if (data.isEmpty) return '';
    final best = data.first;
    final worst = data.last;
    return 'فرع "${best['branchName']}" يحقق أعلى نسبة تحصيل بـ ${_safe(best['collectionRate']).toStringAsFixed(1)}%. '
        '${data.length > 1 ? 'فرع "${worst['branchName']}" يحتاج متابعة بنسبة ${_safe(worst['collectionRate']).toStringAsFixed(1)}%.' : ''}';
  }

  // ═══════════════════════════════════════════════════════════
  //                  التحصيل الشهري
  // ═══════════════════════════════════════════════════════════
Widget _buildMonthlyChart(
    List data, bool isDark, Color cardColor, Color textColor,
    double screenWidth) {
  final months = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  double maxAmount = 0;
  String maxMonth = '';
  double totalAll = 0;

  for (var m in data) {
    double amt = _safe(m['totalAmount']);
    totalAll += amt;
    if (amt > maxAmount) {
      maxAmount = amt;
      maxMonth = months[m['payMonth'] ?? 0];
    }
  }

  return Container(
    padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: _green, size: 18),
            const SizedBox(width: 6),
            Text('التحصيل الشهري',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('إجمالي: ${_formatCurrency(totalAll)}',
                  style: const TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(height: 20),

        // Bar Chart مع المبالغ فوق كل عمود
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.25,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount > 0 ? maxAmount / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.08),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      int idx = val.toInt();
                      if (idx >= 0 && idx < data.length) {
                        double amount = _safe(data[idx]['totalAmount']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _formatCurrency(amount),
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _green),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      int idx = val.toInt();
                      if (idx >= 0 && idx < data.length) {
                        int monthNum = data[idx]['payMonth'] ?? 0;
                        String name =
                            monthNum > 0 && monthNum <= 12
                                ? months[monthNum]
                                : '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            name.length > 3 ? name.substring(0, 3) : name,
                            style: TextStyle(
                                fontSize: 8, color: Colors.grey[500]),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                double amount = _safe(e.value['totalAmount']);
                bool isMax = amount == maxAmount;

                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: amount,
                      width: screenWidth < 360 ? 14 : 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        colors: isMax
                            ? [_green, const Color(0xFF059669)]
                            : [_blue.withOpacity(0.7), _blue],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    int idx = group.x.toInt();
                    if (idx < data.length) {
                      int monthNum = data[idx]['payMonth'] ?? 0;
                      String month = months[monthNum];
                      int children = data[idx]['childrenCount'] ?? 0;
                      return BarTooltipItem(
                        '$month\n${_formatCurrency(rod.toY)} ج.م\n$children طالب',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // جدول التفاصيل
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // رأس الجدول
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('الشهر',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor))),
                    Expanded(
                        flex: 3,
                        child: Text('المحصّل',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor))),
                    Expanded(
                        flex: 2,
                        child: Text('الطلاب',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor))),
                    Expanded(
                        flex: 2,
                        child: Text('النسبة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor))),
                  ],
                ),
              ),
              // صفوف البيانات
              ...data.asMap().entries.map((entry) {
                final m = entry.value;
                int monthNum = m['payMonth'] ?? 0;
                String monthName =
                    monthNum > 0 && monthNum <= 12
                        ? months[monthNum]
                        : '-';
                double amount = _safe(m['totalAmount']);
                int children = m['childrenCount'] ?? 0;
                double percent =
                    totalAll > 0 ? (amount / totalAll) * 100 : 0;
                bool isMax = amount == maxAmount;

                return Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isMax
                        ? _green.withOpacity(0.05)
                        : Colors.transparent,
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            if (isMax)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text('🏆',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            Flexible(
                              child: Text(monthName,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textColor,
                                      fontWeight: isMax
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('${_formatCurrency(amount)} ج.م',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMax ? _green : textColor)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('$children',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('${percent.toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _primary)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 10),
        // التحليل النصي
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📈', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getMonthlyInsight(data, months, maxMonth, maxAmount, totalAll),
                  style: TextStyle(
                      fontSize: 11, color: textColor, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// تحليل نصي للتحصيل الشهري
String _getMonthlyInsight(
    List data, List<String> months, String maxMonth,
    double maxAmount, double totalAll) {
  if (data.length < 2) {
    return 'أعلى تحصيل كان في شهر $maxMonth بمبلغ ${_formatCurrency(maxAmount)} ج.م.';
  }

  // مقارنة آخر شهرين
  double lastMonth = _safe(data.last['totalAmount']);
  double prevMonth = _safe(data[data.length - 2]['totalAmount']);
  String lastMonthName = months[data.last['payMonth'] ?? 0];
  String prevMonthName = months[data[data.length - 2]['payMonth'] ?? 0];

  String comparison = '';
  if (prevMonth > 0) {
    double changePercent =
        ((lastMonth - prevMonth) / prevMonth) * 100;
    if (changePercent > 0) {
      comparison =
          ' التحصيل في $lastMonthName ارتفع بنسبة ${changePercent.toStringAsFixed(0)}% مقارنة بـ $prevMonthName.';
    } else if (changePercent < 0) {
      comparison =
          ' التحصيل في $lastMonthName انخفض بنسبة ${changePercent.abs().toStringAsFixed(0)}% مقارنة بـ $prevMonthName.';
    }
  }

  return 'أعلى تحصيل كان في شهر $maxMonth بمبلغ ${_formatCurrency(maxAmount)} ج.م.$comparison';
}

  // ═══════════════════════════════════════════════════════════
  //                   التوصيات الذكية
  // ═══════════════════════════════════════════════════════════
  Widget _buildInsightsSection(List<Map<String, dynamic>> insights,
      bool isDark, Color cardColor, Color textColor) {
    if (insights.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: _orange, size: 18),
              const SizedBox(width: 6),
              Text('التوصيات والتحليلات',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ],
          ),
          const Divider(height: 20),
          ...insights.map((insight) {
            Color bgColor;
            Color borderColor;
            switch (insight['type']) {
              case 'danger':
                bgColor = _red.withOpacity(0.08);
                borderColor = _red;
                break;
              case 'warning':
                bgColor = _orange.withOpacity(0.08);
                borderColor = _orange;
                break;
              case 'success':
                bgColor = _green.withOpacity(0.08);
                borderColor = _green;
                break;
              case 'info':
              default:
                bgColor = _blue.withOpacity(0.08);
                borderColor = _blue;
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                    right: BorderSide(color: borderColor, width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight['icon'] ?? '💡',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insight['title'] ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(insight['text'] ?? '',
                            style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 11,
                                height: 1.5)),
                      ],
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

  // ═══════════════════════════════════════════════════════════
  //                  أكثر المتأخرين
  // ═══════════════════════════════════════════════════════════
  Widget _buildTopDebtors(
      List data, bool isDark, Color cardColor, Color textColor, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_off_rounded, color: _red, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text('أكثر المتأخرين',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${data.length} طالب',
                    style: const TextStyle(
                        color: _red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          ...data.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            double required = _safe(item['totalRequired']);
            double paid = _safe(item['totalPaid']);
            double remaining = required - paid;
            int daysLate = item['daysLate'] ?? 0;

            Color riskColor = daysLate > 60
                ? _red
                : daysLate > 30
                    ? _orange
                    : Colors.amber;
            String riskLabel = daysLate > 60
                ? 'حرج'
                : daysLate > 30
                    ? 'متوسط'
                    : 'منخفض';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                    right: BorderSide(color: riskColor, width: 3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: riskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['FullNameArabic'] ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${item['branchName'] ?? ''} | ${(item['Kind_subscrip'] ?? '').toString().contains('الدراسة') ? '📚' : '🚌'}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Text('${_formatCurrency(remaining)} ج.م',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _red,
                                fontSize: 12)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$daysLate يوم - $riskLabel',
                            style: TextStyle(
                                fontSize: 9,
                                color: riskColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}