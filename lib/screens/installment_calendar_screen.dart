import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/debt_provider.dart';
import '../providers/children_provider.dart';
import '../providers/theme_provider.dart';

class InstallmentCalendarScreen extends StatefulWidget {
  const InstallmentCalendarScreen({super.key});

  @override
  State<InstallmentCalendarScreen> createState() =>
      _InstallmentCalendarScreenState();
}

class _InstallmentCalendarScreenState extends State<InstallmentCalendarScreen> {
  int? _selectedSessionId;

  static const _primary = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);
  static const _blue = Color(0xFF3B82F6);

  final _monthNames = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  final _academicOrder = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8];

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
      _loadCalendar();
    }
  }

  Future<void> _loadCalendar() async {
    if (_selectedSessionId != null) {
      await Provider.of<DebtProvider>(context, listen: false)
          .fetchMonthlyCalendar(_selectedSessionId!);
    }
  }

  // ═══════════════════════════════════════════════════
  //                 دوال مساعدة
  // ═══════════════════════════════════════════════════
  double _safe(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  String _formatCurrency(dynamic amount) {
    double val = _safe(amount);
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      DateTime d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '-';
    }
  }

  Map<String, dynamic>? _getMonthData(List data, int month) {
    try {
      return data.firstWhere((m) => m['monthNum'] == month);
    } catch (_) {
      return null;
    }
  }

  int _getYearForMonth(int month, List data) {
    try {
      final found = data.firstWhere((m) => m['monthNum'] == month);
      return found['yearNum'] ?? DateTime.now().year;
    } catch (_) {
      if (data.isNotEmpty) {
        try {
          final sept = data.firstWhere((m) => (m['monthNum'] ?? 0) >= 9);
          int startYear = sept['yearNum'] ?? DateTime.now().year;
          return month >= 9 ? startYear : startYear + 1;
        } catch (_) {
          try {
            final jan = data.firstWhere((m) => (m['monthNum'] ?? 0) <= 8);
            int endYear = jan['yearNum'] ?? DateTime.now().year;
            return month >= 9 ? endYear - 1 : endYear;
          } catch (_) {
            return DateTime.now().year;
          }
        }
      }
      return DateTime.now().year;
    }
  }

  // ═══════════════════════════════════════════════════
  //                    BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DebtProvider>(context);
    final cp = Provider.of<ChildrenProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('📅 الأقساط المتبقية',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: _primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(cp, dp, isDark, cardColor, textColor),
          Expanded(
            child: dp.isCalendarLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTotalSummary(
                              dp.calendarMonths, isDark, textColor),
                          const SizedBox(height: 12),
                          _buildRealCalendar(dp, isDark, cardColor, textColor,
                              screenWidth, screenHeight),
                          const SizedBox(height: 16),
                          _buildCurrentMonthBranches(
                              dp, isDark, cardColor, textColor),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //                    الفلاتر
  // ═══════════════════════════════════════════════════
  Widget _buildFilters(ChildrenProvider cp, DebtProvider dp, bool isDark,
      Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown<int>(
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
                    _loadCalendar();
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown<int>(
                  value: dp.calendarSelectedBranchId,
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
                      dp.setCalendarBranchFilter(v, _selectedSessionId!);
                    }
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChip('الكل', dp.calendarSelectedType == 'الكل', () {
                if (_selectedSessionId != null)
                  dp.setCalendarTypeFilter('الكل', _selectedSessionId!);
              }, isDark),
              const SizedBox(width: 6),
              _buildChip('📚 دراسة', dp.calendarSelectedType == 'دراسة', () {
                if (_selectedSessionId != null)
                  dp.setCalendarTypeFilter('دراسة', _selectedSessionId!);
              }, isDark),
              const SizedBox(width: 6),
              _buildChip('🚌 باص', dp.calendarSelectedType == 'باص', () {
                if (_selectedSessionId != null)
                  dp.setCalendarTypeFilter('باص', _selectedSessionId!);
              }, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 14, color: _primary),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(hint,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.grey[400]),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChip(
      String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? _primary : Colors.grey.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey)),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //                 الملخص العلوي
  // ═══════════════════════════════════════════════════
  Widget _buildTotalSummary(List data, bool isDark, Color textColor) {
    double totalUnpaid =
        data.fold(0.0, (sum, m) => sum + _safe(m['totalUnpaid']));
    double totalOverdue =
        data.fold(0.0, (sum, m) => sum + _safe(m['overdueAmount']));
    int totalChildren = data.fold(
        0, (sum, m) => sum + ((m['childrenCount'] ?? 0) as int));
    int monthsWithData = data.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('📅', '$monthsWithData شهر', textColor),
          Container(
              width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem('👶', '$totalChildren طفل', textColor),
          Container(
              width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem('💰', _formatCurrency(totalUnpaid), _orange),
          Container(
              width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem('🔴', _formatCurrency(totalOverdue), _red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String icon, String text, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //              الكليندر الحقيقية
  // ═══════════════════════════════════════════════════
  Widget _buildRealCalendar(DebtProvider dp, bool isDark, Color cardColor,
      Color textColor, double screenWidth, double screenHeight) {
    final data = dp.calendarMonths;
    double cellWidth = (screenWidth - 24 - 18) / 4;
    double cellHeight = cellWidth * 1.3;
    double gridHeight = (cellHeight * 3) + 12 + 40;

    return Container(
      height: gridHeight,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Text('الأقساط المتبقية حسب الشهر',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.75,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  int monthNum = _academicOrder[index];
                  Map<String, dynamic>? monthData =
                      _getMonthData(data, monthNum);
                  return _buildCalendarCell(
                      monthNum, monthData, data, isDark, textColor);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('🔴 متأخر', _red),
                const SizedBox(width: 12),
                _buildLegend('🟡 قادم', _orange),
                const SizedBox(width: 12),
                _buildLegend('⚪ لا يوجد', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //               خلية الشهر
  // ═══════════════════════════════════════════════════
  Widget _buildCalendarCell(int monthNum, Map<String, dynamic>? data,
      List allData, bool isDark, Color textColor) {
    int yearNum = data?['yearNum'] ?? _getYearForMonth(monthNum, allData);
    String monthName =
        monthNum > 0 && monthNum <= 12 ? _monthNames[monthNum] : '-';
    bool hasData = data != null;
    int children = data?['childrenCount'] ?? 0;
    double totalUnpaid = _safe(data?['totalUnpaid']);
    int overdueCount = data?['overdueCount'] ?? 0;
    int pendingCount = data?['pendingCount'] ?? 0;

    bool isCurrentMonth =
        monthNum == DateTime.now().month && yearNum == DateTime.now().year;

    Color cellColor;
    Color borderColor;
    if (!hasData) {
      cellColor =
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      borderColor = Colors.grey.withOpacity(0.1);
    } else if (overdueCount > 0) {
      cellColor = _red.withOpacity(isDark ? 0.15 : 0.05);
      borderColor = _red.withOpacity(0.3);
    } else {
      cellColor = _orange.withOpacity(isDark ? 0.15 : 0.05);
      borderColor = _orange.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: hasData
          ? () => _showMonthBottomSheet(monthNum, yearNum, monthName)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentMonth ? _primary : borderColor,
            width: isCurrentMonth ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // اسم الشهر + السنة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: isCurrentMonth
                    ? _primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    monthName.length > 5
                        ? monthName.substring(0, 5)
                        : monthName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrentMonth ? _primary : textColor,
                    ),
                  ),
                  Text(
                    '$yearNum',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: isCurrentMonth
                          ? _primary.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // المحتوى
            Expanded(
              child: hasData
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('👶',
                                  style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 2),
                              Text('$children',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            child: Text(
                              '${_formatCurrency(totalUnpaid)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: overdueCount > 0 ? _red : _orange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (overdueCount > 0) ...[
                                Text('🔴$overdueCount',
                                    style: const TextStyle(fontSize: 8)),
                                const SizedBox(width: 3),
                              ],
                              if (pendingCount > 0)
                                Text('🟡$pendingCount',
                                    style: const TextStyle(fontSize: 8)),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Text('—',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[400])),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //        تفصيلة الشهر الحالي حسب الفروع
  // ═══════════════════════════════════════════════════
  Widget _buildCurrentMonthBranches(
      DebtProvider dp, bool isDark, Color cardColor, Color textColor) {
    if (dp.isCurrentMonthLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: _primary),
      ));
    }

    final branches = dp.currentMonthBranches;
    int currentMonth = dp.currentMonthNum ?? DateTime.now().month;
    String monthName =
        currentMonth > 0 && currentMonth <= 12
            ? _monthNames[currentMonth]
            : '';

    double totalUnpaid =
        branches.fold(0.0, (sum, b) => sum + _safe(b['totalUnpaid']));
    int totalChildren =
        branches.fold(0, (sum, b) => sum + ((b['childrenCount'] ?? 0) as int));
    int totalOverdue =
        branches.fold(0, (sum, b) => sum + ((b['overdueCount'] ?? 0) as int));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.store_rounded, color: _primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تفصيلة شهر $monthName حسب الفروع',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    Text('الأقساط المتبقية غير المسددة',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('👶', '$totalChildren', 'طفل'),
                Container(
                    width: 1,
                    height: 25,
                    color: Colors.grey.withOpacity(0.2)),
                _buildMiniStat('💰', _formatCurrency(totalUnpaid), 'متبقي'),
                Container(
                    width: 1,
                    height: 25,
                    color: Colors.grey.withOpacity(0.2)),
                _buildMiniStat('🔴', '$totalOverdue', 'متأخر'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('الفرع',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                Expanded(
                    flex: 2,
                    child: Text('الأطفال',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                Expanded(
                    flex: 2,
                    child: Text('المتبقي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                Expanded(
                    flex: 1,
                    child: Text('🔴',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (branches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('لا توجد أقساط متبقية هذا الشهر 🎉',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
            )
          else
            ...branches.map((branch) {
              int children = branch['childrenCount'] ?? 0;
              double unpaid = _safe(branch['totalUnpaid']);
              int overdue = branch['overdueCount'] ?? 0;
              bool hasOverdue = overdue > 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasOverdue ? _red : _orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(branch['branchName'] ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('$children',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ),
                    Expanded(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_formatCurrency(unpaid),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: hasOverdue ? _red : _orange)),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: hasOverdue
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('$overdue',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _red)),
                            )
                          : Text('0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(value,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //            Bottom Sheet - تفاصيل الشهر
  // ═══════════════════════════════════════════════════
  void _showMonthBottomSheet(int month, int year, String monthName) {
    if (_selectedSessionId == null) return;

    final dp = Provider.of<DebtProvider>(context, listen: false);
    dp.fetchMonthDetails(
      sessionId: _selectedSessionId!,
      month: month,
      year: year,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer2<DebtProvider, ThemeProvider>(
              builder: (context, dp, tp, _) {
                final isDark = tp.isDark;
                final bgColor =
                    isDark ? const Color(0xFF1E293B) : Colors.white;
                final textColor =
                    isDark ? Colors.white : const Color(0xFF1E293B);

                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: _primary,
                                  size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('أقساط شهر $monthName $year',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor)),
                                  Text('الأقساط المتبقية غير المسددة',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: dp.isMonthDetailsLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: _primary))
                            : dp.monthDetails.isEmpty
                                ? _buildEmptyState()
                                : _buildDetailsList(
                                    dp, scrollController, isDark, textColor),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 50, color: _green),
          const SizedBox(height: 12),
          Text('لا توجد أقساط متبقية 🎉',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDetailsList(DebtProvider dp,
      ScrollController scrollController, bool isDark, Color textColor) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (dp.monthSummary != null)
          _buildSheetSummary(dp.monthSummary!, isDark, textColor),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 4,
                  child: Text('الطالب',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor))),
              Expanded(
                  flex: 2,
                  child: Text('القسط',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor))),
              Expanded(
                  flex: 2,
                  child: Text('الحالة / التاريخ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...dp.monthDetails.map((item) => _buildDetailRow(item, isDark, textColor)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSheetSummary(
      Map<String, dynamic> summary, bool isDark, Color textColor) {
    int overdue = summary['overdueCount'] ?? 0;
    int pending = summary['pendingCount'] ?? 0;
    double totalAmount = _safe(summary['totalAmount']);
    double overdueAmount = _safe(summary['overdueAmount']);
    int children = summary['totalChildren'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF334155), const Color(0xFF1E293B)]
              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSheetSummaryItem('👶', '$children', 'طفل', _blue),
          _buildSheetSummaryItem(
              '💰', _formatCurrency(totalAmount), 'إجمالي', _orange),
          _buildSheetSummaryItem('🔴', '$overdue', 'متأخر', _red),
          _buildSheetSummaryItem('🟡', '$pending', 'قادم', _orange),
        ],
      ),
    );
  }

  Widget _buildSheetSummaryItem(
      String icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildDetailRow(
      Map<String, dynamic> item, bool isDark, Color textColor) {
    String status = item['status'] ?? 'pending';
    String name = item['FullNameArabic'] ?? '';
    double amount = _safe(item['amountPyment']);
    String branch = item['branchName'] ?? '';
    String type = (item['Kind_subscrip'] ?? '').toString();
    bool isStudy = type.contains('الدراسة');
    int daysLate = item['daysLate'] ?? 0;
    String fatherPhone = item['FatherMobile1'] ?? '';
    String motherPhone = item['MotherMobile1'] ?? '';
    bool isOverdue = status == 'overdue';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isOverdue
            ? _red.withOpacity(isDark ? 0.08 : 0.03)
            : isDark
                ? const Color(0xFF334155)
                : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: BorderSide(color: isOverdue ? _red : _orange, width: 3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Text(isStudy ? '📚' : '🚌',
                            style: const TextStyle(fontSize: 9)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(branch,
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_formatCurrency(amount),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? _red : textColor)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? _red.withOpacity(0.1)
                            : _orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOverdue ? 'متأخر' : 'قادم',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? _red : _orange),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_formatDate(item['MonthPayment']),
                        style:
                            TextStyle(fontSize: 8, color: Colors.grey[500])),
                    if (isOverdue)
                      Text('متأخر $daysLate يوم',
                          style: const TextStyle(fontSize: 7, color: _red)),
                  ],
                ),
              ),
            ],
          ),
          if (isOverdue &&
              (fatherPhone.isNotEmpty || motherPhone.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (fatherPhone.isNotEmpty)
                  _buildCallBtn('📞 الأب', fatherPhone),
                if (fatherPhone.isNotEmpty && motherPhone.isNotEmpty)
                  const SizedBox(width: 6),
                if (motherPhone.isNotEmpty)
                  _buildCallBtn('📞 الأم', motherPhone),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallBtn(String label, String phone) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 9, color: _green, fontWeight: FontWeight.bold)),
      ),
    );
  }
}