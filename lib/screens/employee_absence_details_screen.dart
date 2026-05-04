import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class EmployeeAbsenceDetailsScreen extends StatefulWidget {
  final int empId;
  final String empName;
  final String? job;
  final String? branchName;
  final int month;
  final int year;

  const EmployeeAbsenceDetailsScreen({
    Key? key,
    required this.empId,
    required this.empName,
    this.job,
    this.branchName,
    required this.month,
    required this.year,
  }) : super(key: key);

  @override
  State<EmployeeAbsenceDetailsScreen> createState() =>
      _EmployeeAbsenceDetailsScreenState();
}

class _EmployeeAbsenceDetailsScreenState
    extends State<EmployeeAbsenceDetailsScreen> {
  bool _isLoading = true;
  List<dynamic> _absenceDates = [];
  int _totalAbsence = 0;

  // فلتر الفترة
  DateTimeRange? _customRange;
  bool _isCustomRange = false;

  // بحث الموظف
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // بيانات الموظف الحالي
  late int _currentEmpId;
  late String _currentEmpName;
  String? _currentJob;
  String? _currentBranchName;

  final List<String> _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل',
    'مايو', 'يونيو', 'يوليو', 'أغسطس',
    'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  final List<String> _dayNames = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
    'الجمعة', 'السبت', 'الأحد'
  ];

  @override
  void initState() {
    super.initState();
    _currentEmpId = widget.empId;
    _currentEmpName = widget.empName;
    _currentJob = widget.job;
    _currentBranchName = widget.branchName;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // =============================================
  // حدود التاريخ الآمنة
  // =============================================
  DateTime _getLastAllowedDate() {
    return DateUtils.dateOnly(DateTime.now());
  }

  DateTimeRange _getDefaultMonthRange() {
    final start = DateTime(widget.year, widget.month, 1);
    final monthEnd = DateTime(widget.year, widget.month + 1, 0);
    final lastAllowed = _getLastAllowedDate();
    final end = monthEnd.isAfter(lastAllowed) ? lastAllowed : monthEnd;

    return DateTimeRange(
      start: start.isAfter(end) ? end : start,
      end: end,
    );
  }

  DateTimeRange _getSafeInitialRange() {
    final firstAllowed = DateTime(2020);
    final lastAllowed = _getLastAllowedDate();

    DateTime start;
    DateTime end;

    if (_customRange != null) {
      start = DateUtils.dateOnly(_customRange!.start);
      end = DateUtils.dateOnly(_customRange!.end);
    } else {
      final defaultRange = _getDefaultMonthRange();
      start = defaultRange.start;
      end = defaultRange.end;
    }

    if (start.isBefore(firstAllowed)) start = firstAllowed;
    if (end.isAfter(lastAllowed)) end = lastAllowed;
    if (start.isAfter(end)) start = end;

    return DateTimeRange(start: start, end: end);
  }

  // =============================================
  // تحميل البيانات
  // =============================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_isCustomRange && _customRange != null) {
        result = await ApiService.getEmpAbsenceDates(
          empId: _currentEmpId,
          fromDate: _customRange!.start,
          toDate: _customRange!.end,
        );
      } else {
        result = await ApiService.getEmpAbsenceDates(
          empId: _currentEmpId,
          month: widget.month,
          year: widget.year,
        );
      }

      if (mounted) {
        setState(() {
          _absenceDates = result['data'] ?? [];
          _totalAbsence = result['totalAbsence'] ?? _absenceDates.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =============================================
  // حساب أيام العمل
  // =============================================
  int _getWorkingDaysInMonth() {
    if (_isCustomRange && _customRange != null) {
      return _getWorkingDaysInRange(_customRange!.start, _customRange!.end);
    }
    final defaultRange = _getDefaultMonthRange();
    return _getWorkingDaysInRange(defaultRange.start, defaultRange.end);
  }

  int _getWorkingDaysInRange(DateTime start, DateTime end) {
    int workingDays = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.friday &&
          current.weekday != DateTime.saturday) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    return workingDays;
  }

  String _getDayName(DateTime date) {
    return _dayNames[date.weekday - 1];
  }

  // =============================================
  // اختيار فترة زمنية
  // =============================================
  Future<void> _pickDateRange() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: _getLastAllowedDate(),
        initialDateRange: _getSafeInitialRange(),
      );

      if (picked != null) {
        setState(() {
          _customRange = DateTimeRange(
            start: DateUtils.dateOnly(picked.start),
            end: DateUtils.dateOnly(picked.end),
          );
          _isCustomRange = true;
        });
        _loadData();
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار التاريخ: $e');
    }
  }

  void _resetToMonth() {
    setState(() {
      _customRange = null;
      _isCustomRange = false;
    });
    _loadData();
  }

  // =============================================
  // بحث الموظف
  // =============================================
  Future<void> _searchEmployees(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final employees = await ApiService.getEmployees();
      final filtered = employees.where((e) {
        final name = (e['empName'] ?? '').toString().toLowerCase();
        final job = (e['job'] ?? '').toString().toLowerCase();
        final isActive = e['empstatus'] == true || e['empstatus'] == 1;
        return isActive &&
            (name.contains(query.toLowerCase()) ||
                job.contains(query.toLowerCase()));
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectEmployee(dynamic emp) {
    setState(() {
      _currentEmpId = emp['ID'];
      _currentEmpName = emp['empName'] ?? '';
      _currentJob = emp['job'];
      _currentBranchName = emp['branchName'];
      _isSearchMode = false;
      _searchController.clear();
      _searchResults = [];
    });
    _loadData();
  }

  // =============================================
  // Build
  // =============================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    final workingDays = _getWorkingDaysInMonth();
    final attendanceDays = (workingDays - _totalAbsence).clamp(0, workingDays);
    final attendancePercent =
        workingDays > 0 ? (attendanceDays / workingDays) * 100 : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: GestureDetector(
        onTap: () {
          _searchFocusNode.unfocus();
          setState(() {
            if (_searchResults.isEmpty) _isSearchMode = false;
          });
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            SliverToBoxAdapter(child: _buildEmployeeCard(isDark)),
            SliverToBoxAdapter(child: _buildDateFilter(isDark)),
            SliverToBoxAdapter(
              child: _buildSummaryCards(
                isDark: isDark,
                workingDays: workingDays,
                absenceDays: _totalAbsence,
                attendanceDays: attendanceDays,
                attendancePercent: attendancePercent,
              ),
            ),
            SliverToBoxAdapter(child: _buildListHeader(isDark)),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6366F1)),
                    ),
                  )
                : _absenceDates.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(isDark))
                    : SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildAbsenceCard(
                                _absenceDates[index], isDark, index),
                            childCount: _absenceDates.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // =============================================
  // AppBar
  // =============================================
  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // بحث موظف
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSearchMode
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSearchMode
                  ? Icons.close_rounded
                  : Icons.person_search_rounded,
              color: _isSearchMode
                  ? const Color(0xFF6366F1)
                  : Colors.white,
              size: 18,
            ),
          ),
          onPressed: () {
            setState(() {
              _isSearchMode = !_isSearchMode;
              if (!_isSearchMode) {
                _searchController.clear();
                _searchResults = [];
              }
            });
          },
        ),
        // تحديث
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 18),
          ),
          onPressed: _loadData,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_busy_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "تفاصيل الغياب",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "عرض أيام الغياب بالتفصيل",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // بطاقة الموظف + البحث
  // =============================================
  Widget _buildEmployeeCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقة الموظف
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _currentEmpName.isNotEmpty
                          ? _currentEmpName[0]
                          : "?",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentEmpName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_currentJob != null) ...[
                            Icon(Icons.work_outline_rounded,
                                size: 13,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentJob!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (_currentJob != null &&
                              _currentBranchName != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Text('•',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.5))),
                            ),
                          if (_currentBranchName != null)
                            Text(
                              _currentBranchName!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // زر تبديل الموظف
                GestureDetector(
                  onTap: () {
                    setState(() => _isSearchMode = !_isSearchMode);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // شريط البحث
          if (_isSearchMode) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252836)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    onChanged: _searchEmployees,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الموظف أو الوظيفة...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF6366F1), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 18,
                                  color: Colors.grey.shade500),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),

                  // نتائج البحث
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    )
                  else if (_searchResults.isNotEmpty)
                    Container(
                      constraints:
                          const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final emp = _searchResults[index];
                          final isCurrentEmp =
                              emp['ID'] == _currentEmpId;

                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrentEmp
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF6366F1)
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (emp['empName'] ?? '?')[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentEmp
                                        ? Colors.white
                                        : const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              emp['empName'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentEmp
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              emp['job'] ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                            trailing: isCurrentEmp
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 20)
                                : null,
                            onTap: () =>
                                _selectEmployee(emp),
                          );
                        },
                      ),
                    )
                  else if (_searchController.text.length >= 2)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // فلتر الفترة الزمنية
  // =============================================
  Widget _buildDateFilter(bool isDark) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // الشهر الأصلي
          Expanded(
            child: GestureDetector(
              onTap: _isCustomRange ? _resetToMonth : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: !_isCustomRange
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : (isDark
                          ? const Color(0xFF252836)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_isCustomRange
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 16,
                        color: !_isCustomRange
                            ? const Color(0xFF6366F1)
                            : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${_monthNames[widget.month - 1]} ${widget.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: !_isCustomRange
                            ? const Color(0xFF6366F1)
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        fontWeight: !_isCustomRange
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // فترة مخصصة
          Expanded(
            child: GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isCustomRange
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : (isDark
                          ? const Color(0xFF252836)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCustomRange
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range_rounded,
                        size: 16,
                        color: _isCustomRange
                            ? const Color(0xFF6366F1)
                            : Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isCustomRange && _customRange != null
                            ? '${dateFormat.format(_customRange!.start)} - ${dateFormat.format(_customRange!.end)}'
                            : 'فترة مخصصة',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isCustomRange
                              ? const Color(0xFF6366F1)
                              : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                          fontWeight: _isCustomRange
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // كروت الملخص
  // =============================================
  Widget _buildSummaryCards({
    required bool isDark,
    required int workingDays,
    required int absenceDays,
    required int attendanceDays,
    required double attendancePercent,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.work_rounded,
                  label: 'أيام العمل',
                  value: '$workingDays',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.check_circle_rounded,
                  label: 'الحضور',
                  value: '$attendanceDays',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  icon: Icons.cancel_rounded,
                  label: 'الغياب',
                  value: '$absenceDays',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // نسبة الحضور
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'نسبة الحضور',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${attendancePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: attendancePercent >= 80
                            ? const Color(0xFF10B981)
                            : attendancePercent >= 60
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: attendancePercent / 100,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      attendancePercent >= 80
                          ? const Color(0xFF10B981)
                          : attendancePercent >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
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

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // =============================================
  // عنوان القائمة
  // =============================================
  Widget _buildListHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_busy_rounded,
                color: Color(0xFFEF4444), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'أيام الغياب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_totalAbsence يوم',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // كارت يوم الغياب
  // =============================================
  Widget _buildAbsenceCard(dynamic absence, bool isDark, int index) {
    final dateStr = absence['absenceDate']?.toString() ?? '';
    final notes = absence['Notes']?.toString() ?? '';
    final dateFormat = DateFormat('yyyy/MM/dd');

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: const Color(0xFFEF4444)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          date != null ? '${date.day}' : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date != null
                                ? dateFormat.format(date)
                                : dateStr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date != null ? _getDayName(date) : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_busy_rounded,
                          color: Color(0xFFEF4444), size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // حالة فارغة
  // =============================================
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                size: 60, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 20),
          Text(
            'لا يوجد غياب! ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isCustomRange
                ? 'لا يوجد غياب في هذه الفترة'
                : 'لا يوجد غياب في هذا الشهر',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}