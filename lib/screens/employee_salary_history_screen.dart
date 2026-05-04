import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EmployeeSalaryHistoryScreen extends StatefulWidget {
  final int empId;
  final String empName;
  final String? job;
  final String? branchName;

  const EmployeeSalaryHistoryScreen({
    Key? key,
    required this.empId,
    required this.empName,
    this.job,
    this.branchName,
  }) : super(key: key);

  @override
  State<EmployeeSalaryHistoryScreen> createState() =>
      _EmployeeSalaryHistoryScreenState();
}

class _EmployeeSalaryHistoryScreenState
    extends State<EmployeeSalaryHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _salaryHistory = [];

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

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar_EG');
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

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
  // تحميل البيانات
  // =============================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await ApiService.getEmployeeSalaryHistory(_currentEmpId);

      if (mounted) {
        setState(() {
          _salaryHistory = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
  // إضافة زيادة راتب
  // =============================================
  void _showAddSalaryDialog(bool isDark) {
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF252836) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_chart_rounded,
                      color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضافة زيادة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _currentEmpName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // المبلغ
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'الراتب الأساسي الجديد',
                    labelStyle:
                        TextStyle(color: Colors.grey.shade500),
                    suffixText: 'ج.م',
                    suffixStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                        Icons.attach_money_rounded,
                        color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E1E2E)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF10B981), width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // التاريخ
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(
                          () => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E2E)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dateFormat.format(selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.expand_more_rounded,
                            color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),

                // تنبيه
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF3B82F6), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم إضافة سجل جديد بالراتب الأساسي',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        amountController.dispose();
                        Navigator.pop(dialogContext);
                      },
                child: Text('إلغاء',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('أدخل مبلغ صحيح'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        final result =
                            await ApiService.addEmployeeSalary(
                          empId: _currentEmpId,
                          baseSalary: amount,
                          increseDate: selectedDate,
                        );

                        amountController.dispose();
                        Navigator.pop(dialogContext);

                        if (result['success'] == true) {
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white),
                                    const SizedBox(width: 10),
                                    Text(result['message']),
                                  ],
                                ),
                                backgroundColor:
                                    const Color(0xFF10B981),
                                behavior:
                                    SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                margin:
                                    const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: Colors.red,
                                behavior:
                                    SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                margin:
                                    const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // =============================================
  // تأكيد الحذف
  // =============================================
  void _showDeleteConfirmation(
      dynamic salary, bool isDark) {
    final amount = (salary['BaseSalary'] ?? 0).toDouble();
    final dateStr = salary['increseDate']?.toString() ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF252836) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف هذا السجل؟',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currencyFormat.format(amount)} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 16,
                    ),
                  ),
                  if (date != null)
                    Text(
                      _dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لا يمكن التراجع عن هذا الإجراء',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final result =
                  await ApiService.deleteEmployeeSalary(
                empId: _currentEmpId,
                salaryId: salary['ID'],
              );

              if (result['success'] == true) {
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white),
                          const SizedBox(width: 10),
                          Text(result['message']),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حذف',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // Build
  // =============================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    // الراتب الحالي (أول سجل لأنهم مرتبين من الأحدث)
    final currentSalary = _salaryHistory.isNotEmpty
        ? (_salaryHistory.first['BaseSalary'] ?? 0).toDouble()
        : 0.0;

    // الراتب السابق
    final previousSalary = _salaryHistory.length > 1
        ? (_salaryHistory[1]['BaseSalary'] ?? 0).toDouble()
        : 0.0;

    final salaryDiff = currentSalary - previousSalary;

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
            SliverToBoxAdapter(
                child: _buildEmployeeCard(isDark)),
            SliverToBoxAdapter(
              child: _buildCurrentSalaryCard(
                isDark: isDark,
                currentSalary: currentSalary,
                salaryDiff: salaryDiff,
                totalRecords: _salaryHistory.length,
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
                : _salaryHistory.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(isDark))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildSalaryCard(
                              _salaryHistory[index],
                              isDark,
                              index,
                            ),
                            childCount: _salaryHistory.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(
                child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddSalaryDialog(isDark),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded,
              color: Colors.white),
          label: const Text('إضافة زيادة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
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
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "سجل الراتب",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "تاريخ الزيادات والأساسي",
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                                color: Colors.white
                                    .withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _currentJob!,
                                style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.7),
                                    fontSize: 12),
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (_currentJob != null &&
                              _currentBranchName != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6),
                              child: Text('•',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.5))),
                            ),
                          if (_currentBranchName != null)
                            Text(
                              _currentBranchName!,
                              style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.7),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(
                      () => _isSearchMode = !_isSearchMode),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                ),
              ],
            ),
          ),

          // البحث
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
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'ابحث باسم الموظف أو الوظيفة...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500),
                      prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6366F1),
                          size: 20),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors
                                          .grey.shade500),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() =>
                                        _searchResults = []);
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1)),
                      ),
                    )
                  else if (_searchResults.isNotEmpty)
                    Container(
                      constraints:
                          const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final emp = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (emp['empName'] ?? '?')[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              emp['empName'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              emp['job'] ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey.shade500),
                            ),
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
  // كارت الراتب الحالي
  // =============================================
  Widget _buildCurrentSalaryCard({
    required bool isDark,
    required double currentSalary,
    required double salaryDiff,
    required int totalRecords,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الراتب الحالي
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الراتب الحالي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${_currencyFormat.format(currentSalary)} ج.م',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (salaryDiff != 0 && _salaryHistory.length > 1)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: salaryDiff > 0
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          salaryDiff > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: salaryDiff > 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${salaryDiff > 0 ? '+' : ''}${_currencyFormat.format(salaryDiff)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: salaryDiff > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // عدد الزيادات
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '$totalRecords',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                Text(
                  'زيادة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timeline_rounded,
                color: Color(0xFF6366F1), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'سجل الزيادات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            'من الأحدث للأقدم',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // كارت سجل الراتب
  // =============================================
  Widget _buildSalaryCard(
      dynamic salary, bool isDark, int index) {
    final amount = (salary['BaseSalary'] ?? 0).toDouble();
    final dateStr = salary['increseDate']?.toString() ?? '';
    final isFirst = index == 0;

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    // حساب الفرق مع السجل التالي (الأقدم)
    double diff = 0;
    if (index < _salaryHistory.length - 1) {
      final prevAmount =
          (_salaryHistory[index + 1]['BaseSalary'] ?? 0).toDouble();
      diff = amount - prevAmount;
    }

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
          border: isFirst
              ? Border.all(
                  color:
                      const Color(0xFF10B981).withOpacity(0.3),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isFirst
                      ? const Color(0xFF10B981)
                      : Colors.grey)
                  .withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Timeline dot
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1)
                              .withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFirst
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isFirst ||
                      _salaryHistory.length > 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: const Color(0xFF6366F1)
                          .withOpacity(0.2),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isFirst)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            margin: const EdgeInsets.only(
                                left: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'الحالي',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currencyFormat.format(amount)} ج.م',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          date != null
                              ? _dateFormat.format(date)
                              : dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (diff != 0) ...[
                          const SizedBox(width: 12),
                          Icon(
                            diff > 0
                                ? Icons.arrow_upward_rounded
                                : Icons
                                    .arrow_downward_rounded,
                            size: 14,
                            color: diff > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${diff > 0 ? '+' : ''}${_currencyFormat.format(diff)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: diff > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // حذف
              GestureDetector(
                onTap: () => _showDeleteConfirmation(
                    salary, isDark),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 18),
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
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          Text(
            'لا يوجد سجل رواتب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لتسجيل الراتب الأساسي',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}