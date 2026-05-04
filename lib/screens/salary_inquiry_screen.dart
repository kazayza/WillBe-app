import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class SalaryInquiryScreen extends StatefulWidget {
  final int? empId;
  final String? empName;

  const SalaryInquiryScreen({Key? key, this.empId, this.empName})
      : super(key: key);

  @override
  State<SalaryInquiryScreen> createState() => _SalaryInquiryScreenState();
}

class _SalaryInquiryScreenState extends State<SalaryInquiryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _payrollData = [];
  bool _isLoading = false;
  bool _isRangeMode = false;

  // فلتر شهر واحد
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // فلتر فترة
  int _fromMonth = DateTime.now().month;
  int _fromYear = DateTime.now().year;
  int _toMonth = DateTime.now().month;
  int _toYear = DateTime.now().year;

  // فلاتر عامة
  int? _selectedBranchId;
  int? _selectedEmpId;
  String? _selectedEmpName;

  // قوائم
  List<dynamic> _branches = [];
  List<dynamic> _employees = [];
  bool _isLoadingLookups = true;

  // إحصائيات
  double _totalBaseSalary = 0;
  double _totalAdditions = 0;
  double _totalDeductions = 0;
  double _totalNetEmployee = 0;
  double _totalNetDB = 0;
  double _totalSolfa = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'ar_EG');

  final List<String> _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.empId != null) {
      _selectedEmpId = widget.empId;
      _selectedEmpName = widget.empName;
    }

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final branches = await ApiService.getBranches();
      final employees = await ApiService.getEmployees();
      if (mounted) {
        setState(() {
          _branches = branches;
          _employees = employees
              .where((e) => e['empstatus'] == true || e['empstatus'] == 1)
              .toList();
          _isLoadingLookups = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_isRangeMode) {
        result = await ApiService.queryPayroll(
          fromMonth: _fromMonth,
          fromYear: _fromYear,
          toMonth: _toMonth,
          toYear: _toYear,
          branchId: _selectedBranchId,
          empId: _selectedEmpId,
        );
      } else {
        result = await ApiService.queryPayroll(
          fromMonth: _selectedMonth,
          fromYear: _selectedYear,
          toMonth: _selectedMonth,
          toYear: _selectedYear,
          branchId: _selectedBranchId,
          empId: _selectedEmpId,
        );
      }

      if (mounted) {
        setState(() {
          _payrollData = result['data'] ?? [];
          _isLoading = false;
          _calculateTotals();
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    double baseSalary = 0, additions = 0, deductions = 0;
    double netEmployee = 0, netDB = 0, solfa = 0;

    for (var emp in _payrollData) {
      final base = _d(emp['BaseSalary']);
      final extra = _d(emp['extraTime']);
      final badal = _d(emp['badal']);
      final reward = _d(emp['Reward']);
      final penalty = _d(emp['penalty']);
      final busSub = _d(emp['busSub']);
      final qstSolfa = _d(emp['qstSolfa']);
      final solfaVal = _d(emp['Solfa']);
      final absence = _d(emp['absenceAmount'] ?? emp['absence']);
      final netEmp = _d(emp['netForEmployee']);
      final netDbVal = _d(emp['netForDB'] ?? emp['expenseAmount']);

      baseSalary += base;
      additions += extra + badal + reward;
      deductions += penalty + busSub + qstSolfa + absence;
      solfa += solfaVal;
      netEmployee += netEmp;
      netDB += netDbVal;
    }

    setState(() {
      _totalBaseSalary = baseSalary;
      _totalAdditions = additions;
      _totalDeductions = deductions;
      _totalSolfa = solfa;
      _totalNetEmployee = netEmployee;
      _totalNetDB = netDB;
    });
  }

  double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final isEmpMode = widget.empId != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark, isEmpMode),
          SliverToBoxAdapter(child: _buildFilters(isDark, isEmpMode)),
          if (_payrollData.isNotEmpty)
            SliverToBoxAdapter(child: _buildSummary(isDark)),
          SliverToBoxAdapter(child: _buildResultsHeader(isDark)),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF10B981)),
                  ),
                )
              : _payrollData.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty(isDark))
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildCard(_payrollData[i], isDark, i),
                          ),
                          childCount: _payrollData.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // =============================================
  // AppBar
  // =============================================
  Widget _buildAppBar(bool isDark, bool isEmpMode) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF10B981),
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
          onPressed: _payrollData.isNotEmpty ? _fetchData : null,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEmpMode
                                ? 'رواتب ${widget.empName ?? ""}'
                                : 'استعلام الرواتب',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEmpMode
                                ? 'عرض تفاصيل الراتب الشهري'
                                : 'عرض وتحليل رواتب الموظفين',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
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
  // الفلاتر
  // =============================================
  Widget _buildFilters(bool isDark, bool isEmpMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModeToggle(isDark),
          const SizedBox(height: 14),
          if (_isRangeMode)
            _buildRangeFilter(isDark)
          else
            _buildSingleMonthFilter(isDark),
          if (!isEmpMode) ...[
            const SizedBox(height: 12),
            _buildBranchFilter(isDark),
            const SizedBox(height: 12),
            _buildEmployeeFilter(isDark),
          ],
          if (isEmpMode) ...[
            const SizedBox(height: 12),
            _buildLockedEmployee(isDark),
          ],
          const SizedBox(height: 16),
          _buildSearchButton(isDark),
        ],
      ),
    );
  }

  Widget _buildModeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRangeMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isRangeMode
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'شهر واحد',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !_isRangeMode ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRangeMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isRangeMode
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'فترة من - إلى',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isRangeMode ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMonthFilter(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMonthDropdown(isDark, _selectedMonth,
              (v) => setState(() => _selectedMonth = v)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildYearDropdown(isDark, _selectedYear,
              (v) => setState(() => _selectedYear = v)),
        ),
      ],
    );
  }

  Widget _buildRangeFilter(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('من',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMonthDropdown(isDark, _fromMonth,
                  (v) => setState(() => _fromMonth = v)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildYearDropdown(isDark, _fromYear,
                  (v) => setState(() => _fromYear = v)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('إلى',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMonthDropdown(
                  isDark, _toMonth, (v) => setState(() => _toMonth = v)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildYearDropdown(
                  isDark, _toYear, (v) => setState(() => _toYear = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthDropdown(
      bool isDark, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87),
          items: List.generate(
              12,
              (i) => DropdownMenuItem(
                  value: i + 1, child: Text(_monthNames[i]))),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildYearDropdown(
      bool isDark, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87),
          items: List.generate(
              6,
              (i) => DropdownMenuItem(
                  value: DateTime.now().year - i,
                  child: Text('${DateTime.now().year - i}'))),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildBranchFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded,
              size: 18, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedBranchId,
                hint: Text('كل الفروع',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
                isDense: true,
                isExpanded: true,
                dropdownColor:
                    isDark ? const Color(0xFF252836) : Colors.white,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('كل الفروع',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ),
                  ..._branches.map((b) => DropdownMenuItem<int?>(
                      value: b['IDbranch'],
                      child: Text(b['branchName'] ?? ''))),
                ],
                onChanged: (v) => setState(() => _selectedBranchId = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilter(bool isDark) {
    return GestureDetector(
      onTap: () => _showEmployeePicker(isDark),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedEmpId != null
                ? const Color(0xFF10B981).withOpacity(0.5)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person_search_rounded,
                size: 18,
                color: _selectedEmpId != null
                    ? const Color(0xFF10B981)
                    : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedEmpName ?? 'كل الموظفين',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _selectedEmpId != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: _selectedEmpId != null
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade500,
                ),
              ),
            ),
            if (_selectedEmpId != null)
              GestureDetector(
                onTap: () => setState(() {
                  _selectedEmpId = null;
                  _selectedEmpName = null;
                }),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedEmployee(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded,
              color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.empName ?? '',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981))),
          ),
          const Icon(Icons.lock_rounded,
              color: Color(0xFF10B981), size: 16),
        ],
      ),
    );
  }

  Widget _buildSearchButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _fetchData,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded, color: Colors.white),
          label: Text(
              _isLoading ? 'جاري الاستعلام...' : 'استعلام',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // =============================================
  // الملخص
  // =============================================
  Widget _buildSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniCard(Icons.account_balance_rounded, 'الأساسي',
                    _totalBaseSalary, const Color(0xFF3B82F6), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCard(Icons.add_circle_rounded, 'الاستحقاقات',
                    _totalAdditions, const Color(0xFF10B981), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCard(Icons.remove_circle_rounded, 'الاستقطاعات',
                    _totalDeductions, const Color(0xFFEF4444), isDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniCard(Icons.money_off_rounded, 'السلف',
                    _totalSolfa, const Color(0xFFF59E0B), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCard(Icons.payments_rounded, 'صافي الموظفين',
                    _totalNetEmployee, const Color(0xFF8B5CF6), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCard(Icons.receipt_long_rounded,
                    'صافي المحاسبة', _totalNetDB,
                    const Color(0xFF06B6D4), isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _miniCard(IconData icon, String label, double value, Color color,
      bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(value),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(fontSize: 9, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // =============================================
  // عنوان النتائج
  // =============================================
  Widget _buildResultsHeader(bool isDark) {
    if (_payrollData.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.list_alt_rounded,
                color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 10),
          Text('تفاصيل الرواتب',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_payrollData.length} موظف',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // كارت الراتب
  // =============================================
  Widget _buildCard(dynamic emp, bool isDark, int index) {
    final base = _d(emp['BaseSalary']);
    final extra = _d(emp['extraTime']);
    final badal = _d(emp['badal']);
    final reward = _d(emp['Reward']);
    final penalty = _d(emp['penalty']);
    final busSub = _d(emp['busSub']);
    final qstSolfa = _d(emp['qstSolfa']);
    final solfa = _d(emp['Solfa']);
    final absDays = emp['AbsenceDays'] ?? 0;
    final absAmount =
        _d(emp['absenceAmount'] ?? emp['absence']);
    final netEmp = _d(emp['netForEmployee']);
    final netDB = _d(emp['netForDB'] ?? emp['expenseAmount']);
    final name = emp['empName'] ?? '';
    final month = emp['salaryMonth'];
    final year = emp['salaryYear'];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
            title: Text(name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (emp['job'] != null)
                  Text(emp['job'],
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                if (month != null && year != null)
                  Text('${_monthNames[month - 1]} $year',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'صافي: ${_currencyFormat.format(netEmp)} ج.م',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
            children: [
              _detailSection(
                'الاستحقاقات',
                Icons.add_circle_rounded,
                const Color(0xFF10B981),
                isDark,
                [
                  _detailRow('الراتب الأساسي', base, isDark),
                  _detailRow('إضافي', extra, isDark),
                  _detailRow('بدل', badal, isDark),
                  _detailRow('مكافأة', reward, isDark),
                ],
              ),
              const SizedBox(height: 12),
              _detailSection(
                'الاستقطاعات',
                Icons.remove_circle_rounded,
                const Color(0xFFEF4444),
                isDark,
                [
                  _detailRow('جزاءات / إشراف', penalty, isDark,
                      ded: true),
                  _detailRow('اشتراك باص', busSub, isDark,
                      ded: true),
                  _detailRow('قسط سلفة', qstSolfa, isDark,
                      ded: true),
                  _detailRow('غياب ($absDays يوم)', absAmount,
                      isDark,
                      ded: true),
                ],
              ),
              const SizedBox(height: 12),
              if (solfa > 0) ...[
                _detailSection(
                  'السلف المصروفة',
                  Icons.money_off_rounded,
                  const Color(0xFFF59E0B),
                  isDark,
                  [
                    _detailRow('سلفة مصروفة', solfa, isDark,
                        ded: true),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _netBox('صافي استلام الموظف', netEmp,
                  const Color(0xFF10B981), isDark),
              const SizedBox(height: 8),
              _netBox('صافي التسجيل المحاسبي', netDB,
                  const Color(0xFF3B82F6), isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, IconData icon, Color color,
      bool isDark, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _detailRow(String label, double value, bool isDark,
      {bool ded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600)),
          Text(
            '${ded && value > 0 ? "-" : ""}${_currencyFormat.format(value)} ج.م',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value == 0
                  ? Colors.grey.shade400
                  : (ded
                      ? const Color(0xFFEF4444)
                      : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netBox(
      String label, double value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          Text('${_currencyFormat.format(value)} ج.م',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // =============================================
  // حالة فارغة
  // =============================================
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 60,
              color: isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('لا توجد بيانات رواتب',
              style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('اختر الفترة واضغط استعلام',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // =============================================
  // اختيار الموظف
  // =============================================
  void _showEmployeePicker(bool isDark) {
    String search = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = search.isEmpty
                ? _employees
                : _employees
                    .where((e) => (e['empName'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(search.toLowerCase()))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث عن موظف...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black12
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => setSheet(() => search = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final emp = filtered[i];
                        final isSel =
                            _selectedEmpId == emp['ID'];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF10B981)
                                      .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                (emp['empName'] ?? '?')[0],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(
                                            0xFF10B981)),
                              ),
                            ),
                          ),
                          title: Text(emp['empName'] ?? '',
                              style: TextStyle(
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87)),
                          subtitle: Text(emp['job'] ?? ''),
                          trailing: isSel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedEmpId = emp['ID'];
                              _selectedEmpName = emp['empName'];
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}