import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen>
    with SingleTickerProviderStateMixin {
  // Data
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _expenseKinds = [];

  // State
  bool _isLoading = true;
  String _accessError = '';

  // إجماليات ثابتة (الشهر الحالي)
  double _monthAmount = 0.0;
  int _monthCount = 0;

  // إجماليات الفلتر
  double _filteredAmount = 0.0;
  int _filteredCount = 0;

  // Filters
  int? _selectedBranchId;
  int? _selectedKindId;
  String? _selectedKindGroup;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Kind Groups
  List<String> _kindGroups = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndLoad();
    });
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _checkPermissionAndLoad() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.canView('frm_expenseNOUR1')) {
      setState(() {
        _isLoading = false;
        _accessError = 'عفواً، ليس لديك صلاحية لعرض سجل المصروفات.';
      });
      return;
    }
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadExpenses(),
        _loadBranches(),
        _loadExpenseKinds(),
      ]);
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('فشل تحميل البيانات: $e');
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await ApiService.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = (data as List).map((e) {
            return Map<String, dynamic>.from(e);
          }).toList();
          _calculateMonthTotal(); // حساب إجمالي الشهر (ثابت)
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      throw Exception('فشل تحميل المصروفات: $e');
    }
  }

  Future<void> _loadBranches() async {
    try {
      final data = await ApiService.getBranches();
      if (mounted) {
        setState(() {
          _branches = (data as List).map((b) {
            return {
              'IDbranch': b['IDbranch'],
              'branchName': b['branchName'] ?? '',
            };
          }).toList().cast<Map<String, dynamic>>();
        });
        debugPrint('✅ Branches loaded: ${_branches.length}');
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  Future<void> _loadExpenseKinds() async {
    try {
      final data = await ApiService.getExpenseKinds();
      if (mounted) {
        setState(() {
          _expenseKinds = (data as List).map((k) {
            return {
              'ID': k['ID'],
              'expenseKind': k['expenseKind'] ?? '',
              'KindGroup': k['KindGroup'] ?? '',
            };
          }).toList().cast<Map<String, dynamic>>();

          // استخراج المجموعات الفريدة
          _kindGroups = _expenseKinds
              .map((k) => k['KindGroup']?.toString() ?? '')
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList();
        });
        debugPrint('✅ Kinds loaded: ${_expenseKinds.length}');
        debugPrint('✅ Kind Groups: $_kindGroups');
      }
    } catch (e) {
      debugPrint('Error loading expense kinds: $e');
    }
  }

  /// حساب إجمالي الشهر الحالي (ثابت - لا يتأثر بالفلاتر)
  void _calculateMonthTotal() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double monthTotal = 0;
    int monthCount = 0;

    for (var item in _expenses) {
      final amount = _parseAmount(item['expenseAmount']);
      final date = _parseDate(item['expenseDate']);

      if (date != null && !date.isBefore(monthStart)) {
        monthTotal += amount;
        monthCount++;
      }
    }

    _monthAmount = monthTotal;
    _monthCount = monthCount;
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_expenses);

    // Filter by Branch
    if (_selectedBranchId != null) {
      final branchName = _branches.firstWhere(
        (b) => b['IDbranch'] == _selectedBranchId,
        orElse: () => {'branchName': ''},
      )['branchName'];
      filtered = filtered.where((e) => e['branchName'] == branchName).toList();
    }

    // Filter by Kind Group
    if (_selectedKindGroup != null && _selectedKindGroup!.isNotEmpty) {
      final kindsInGroup = _expenseKinds
          .where((k) => k['KindGroup'] == _selectedKindGroup)
          .map((k) => k['expenseKind'])
          .toList();
      filtered = filtered.where((e) => kindsInGroup.contains(e['KindName'])).toList();
    }

    // Filter by Kind
    if (_selectedKindId != null) {
      final kindName = _expenseKinds.firstWhere(
        (k) => k['ID'] == _selectedKindId,
        orElse: () => {'expenseKind': ''},
      )['expenseKind'];
      filtered = filtered.where((e) => e['KindName'] == kindName).toList();
    }

    // Filter by Date Range
    if (_startDate != null) {
      filtered = filtered.where((e) {
        final date = _parseDate(e['expenseDate']);
        return date != null && !date.isBefore(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((e) {
        final date = _parseDate(e['expenseDate']);
        return date != null && !date.isAfter(endOfDay);
      }).toList();
    }

    // Filter by Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        final kind = (e['KindName'] ?? '').toString().toLowerCase();
        final byan = (e['Byan'] ?? '').toString().toLowerCase();
        final user = (e['userAdd'] ?? '').toString().toLowerCase();
        final branch = (e['branchName'] ?? '').toString().toLowerCase();
        return kind.contains(query) ||
            byan.contains(query) ||
            user.contains(query) ||
            branch.contains(query);
      }).toList();
    }

    // Calculate Filtered Totals
    double filteredTotal = 0;
    for (var item in filtered) {
      filteredTotal += _parseAmount(item['expenseAmount']);
    }

    setState(() {
      _filteredExpenses = filtered;
      _filteredAmount = filteredTotal;
      _filteredCount = filtered.length;
    });
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedBranchId = null;
      _selectedKindId = null;
      _selectedKindGroup = null;
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _selectedBranchId != null ||
      _selectedKindId != null ||
      _selectedKindGroup != null ||
      _startDate != null ||
      _endDate != null;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = theme.isDark;

    bool canAdd = auth.canAdd('frm_tbl_expenses') || auth.canOpen('frm_tbl_expenses');
    bool canEdit = auth.canEdit('frm_tbl_expenses');
    bool canDelete = auth.canDelete('frm_tbl_expenses');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _accessError.isNotEmpty
          ? _buildAccessError(isDark)
          : _buildBody(isDark, canEdit, canDelete),
      floatingActionButton: canAdd && _accessError.isEmpty
          ? _buildFAB(isDark)
          : null,
    );
  }

  Widget _buildBody(bool isDark, bool canEdit, bool canDelete) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(isDark),

        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFEF5350)),
            ),
          )
        else ...[
          // Summary Cards
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSummarySection(isDark),
            ),
          ),

          // Filter Chips
          if (_hasActiveFilters)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFilterChips(isDark),
              ),
            ),

          // Expenses List
          _filteredExpenses.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(isDark))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = _filteredExpenses[index];
                        return _buildExpenseCard(expense, isDark, index, canEdit, canDelete);
                      },
                      childCount: _filteredExpenses.length,
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  // ============ APP BAR ============
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFEF5350),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Filter Button
        IconButton(
          icon: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _showFilterBottomSheet(isDark),
        ),
        // Refresh Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _loadAllData,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF5350), Color(0xFFC62828)],
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
                bottom: 16,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "المصروفات",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_expenses.length} عملية إجمالي",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
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

    // ============ SUMMARY SECTION ============
  Widget _buildSummarySection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "بحث في المصروفات...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFEF5350)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Summary Cards Row
          Row(
            children: [
              // كارد الشهر الحالي (ثابت)
              Expanded(
                child: _buildSummaryCard(
                  title: "الشهر الحالي",
                  amount: _monthAmount,
                  count: _monthCount,
                  icon: Icons.calendar_month_rounded,
                  gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  isDark: isDark,
                  isFixed: true,
                ),
              ),
              const SizedBox(width: 12),
              // كارد الفترة المحددة (متغير)
              Expanded(
                child: _buildSummaryCard(
                  title: _hasActiveFilters ? "الفترة المحددة" : "الإجمالي",
                  amount: _filteredAmount,
                  count: _filteredCount,
                  icon: _hasActiveFilters ? Icons.filter_alt_rounded : Icons.account_balance_wallet_rounded,
                  gradient: [const Color(0xFFEF5350), const Color(0xFFC62828)],
                  isDark: isDark,
                  isFixed: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required int count,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required bool isFixed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (isFixed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "📅 ثابت",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (_hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🔍 فلتر",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${NumberFormat('#,##0').format(amount)} ج.م",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count عملية",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ FILTER CHIPS ============
  Widget _buildFilterChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "الفلاتر النشطة:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("مسح الكل"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedBranchId != null)
                _buildFilterChip(
                  label: _branches.firstWhere(
                    (b) => b['IDbranch'] == _selectedBranchId,
                    orElse: () => {'branchName': 'فرع'},
                  )['branchName'],
                  icon: Icons.store,
                  onDelete: () {
                    setState(() => _selectedBranchId = null);
                    _applyFilters();
                  },
                ),
              if (_selectedKindGroup != null)
                _buildFilterChip(
                  label: _selectedKindGroup!,
                  icon: Icons.folder,
                  onDelete: () {
                    setState(() {
                      _selectedKindGroup = null;
                      _selectedKindId = null;
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedKindId != null)
                _buildFilterChip(
                  label: _expenseKinds.firstWhere(
                    (k) => k['ID'] == _selectedKindId,
                    orElse: () => {'expenseKind': 'نوع'},
                  )['expenseKind'],
                  icon: Icons.category,
                  onDelete: () {
                    setState(() => _selectedKindId = null);
                    _applyFilters();
                  },
                ),
              if (_startDate != null || _endDate != null)
                _buildFilterChip(
                  label: _getDateRangeLabel(),
                  icon: Icons.date_range,
                  onDelete: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _applyFilters();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFEF5350)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF5350),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    final formatter = DateFormat('d/M');
    if (_startDate != null && _endDate != null) {
      return "${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}";
    } else if (_startDate != null) {
      return "من ${formatter.format(_startDate!)}";
    } else if (_endDate != null) {
      return "حتى ${formatter.format(_endDate!)}";
    }
    return "";
  }

  // ============ FILTER BOTTOM SHEET ============
  void _showFilterBottomSheet(bool isDark) {
    // متغيرات مؤقتة للفلتر
    int? tempBranchId = _selectedBranchId;
    int? tempKindId = _selectedKindId;
    String? tempKindGroup = _selectedKindGroup;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // فلترة الأنواع حسب المجموعة
          final filteredKinds = tempKindGroup != null
              ? _expenseKinds.where((k) => k['KindGroup'] == tempKindGroup).toList()
              : _expenseKinds;

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.filter_list_rounded,
                          color: Color(0xFFEF5350),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "تصفية المصروفات",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "اختر معايير البحث",
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempBranchId = null;
                            tempKindId = null;
                            tempKindGroup = null;
                            tempStartDate = null;
                            tempEndDate = null;
                          });
                        },
                        child: const Text("مسح"),
                      ),
                    ],
                  ),
                ),

                Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),

                // Filter Options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Branch Filter
                      _buildFilterDropdown(
                        title: "الفرع",
                        icon: Icons.store_rounded,
                        value: tempBranchId,
                        hint: "اختر الفرع",
                        items: _branches.map((b) {
                          return DropdownMenuItem<int>(
                            value: b['IDbranch'] as int,
                            child: Text(b['branchName'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() => tempBranchId = value);
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Kind Group Filter
                      if (_kindGroups.isNotEmpty)
                        _buildFilterDropdown(
                          title: "مجموعة المصروفات",
                          icon: Icons.folder_rounded,
                          value: tempKindGroup,
                          hint: "اختر المجموعة",
                          items: _kindGroups.map((g) {
                            return DropdownMenuItem<String>(
                              value: g,
                              child: Text(g),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              tempKindGroup = value;
                              tempKindId = null;
                            });
                          },
                          isDark: isDark,
                        ),

                      if (_kindGroups.isNotEmpty) const SizedBox(height: 20),

                      // Kind Filter
                      _buildFilterDropdown(
                        title: "نوع المصروف",
                        icon: Icons.category_rounded,
                        value: tempKindId,
                        hint: "اختر النوع",
                        items: filteredKinds.map((k) {
                          return DropdownMenuItem<int>(
                            value: k['ID'] as int,
                            child: Text(k['expenseKind'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() => tempKindId = value);
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Date Range
                      _buildDateRangeFilter(
                        startDate: tempStartDate,
                        endDate: tempEndDate,
                        onStartDateChanged: (date) {
                          setModalState(() => tempStartDate = date);
                        },
                        onEndDateChanged: (date) {
                          setModalState(() => tempEndDate = date);
                        },
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Quick Date Filters
                      _buildQuickDateFilters(
                        onSelect: (start, end) {
                          setModalState(() {
                            tempStartDate = start;
                            tempEndDate = end;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Apply Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFEF5350)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "إلغاء",
                            style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedBranchId = tempBranchId;
                                _selectedKindId = tempKindId;
                                _selectedKindGroup = tempKindGroup;
                                _startDate = tempStartDate;
                                _endDate = tempEndDate;
                              });
                              _applyFilters();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "تطبيق الفلتر",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String title,
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFEF5350)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              items: items,
              onChanged: onChanged,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter({
    required DateTime? startDate,
    required DateTime? endDate,
    required ValueChanged<DateTime?> onStartDateChanged,
    required ValueChanged<DateTime?> onEndDateChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFFEF5350)),
            const SizedBox(width: 8),
            Text(
              "الفترة الزمنية",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: startDate != null
                    ? DateFormat('d/M/yyyy').format(startDate)
                    : "من تاريخ",
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFEF5350),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  onStartDateChanged(date);
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: endDate != null
                    ? DateFormat('d/M/yyyy').format(endDate)
                    : "إلى تاريخ",
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFEF5350),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  onEndDateChanged(date);
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilters({
    required Function(DateTime start, DateTime end) onSelect,
  }) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFFEF5350)),
            const SizedBox(width: 8),
            Text(
              "اختيار سريع",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateChip("اليوم", () {
              final today = DateTime(now.year, now.month, now.day);
              onSelect(today, now);
            }),
            _buildQuickDateChip("أمس", () {
              final yesterday = now.subtract(const Duration(days: 1));
              final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
              final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
              onSelect(start, end);
            }),
            _buildQuickDateChip("هذا الأسبوع", () {
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              onSelect(DateTime(weekStart.year, weekStart.month, weekStart.day), now);
            }),
            _buildQuickDateChip("هذا الشهر", () {
              onSelect(DateTime(now.year, now.month, 1), now);
            }),
            _buildQuickDateChip("الشهر الماضي", () {
              final lastMonth = DateTime(now.year, now.month - 1, 1);
              final lastDay = DateTime(now.year, now.month, 0);
              onSelect(lastMonth, lastDay);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF5350),
          ),
        ),
      ),
    );
  }

    // ============ EXPENSE CARD ============
  Widget _buildExpenseCard(
    Map<String, dynamic> item,
    bool isDark,
    int index,
    bool canEdit,
    bool canDelete,
  ) {
    final amount = _parseAmount(item['expenseAmount']);
    final dateStr = item['expenseDate'];
    final kind = item['KindName'] ?? 'عام';
    final branch = item['branchName'] ?? '';
    final byan = item['Byan'] ?? '';
    final user = item['userAdd'] ?? '';
    final id = item['ID'];
    final addTime = item['Addtime'];
    final editUser = item['useredit'];
    final editTime = item['editTime'];

    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dismissible(
        key: Key('expense_$id'),
        direction: (canDelete || canEdit)
            ? DismissDirection.horizontal
            : DismissDirection.none,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart && canDelete) {
            return await _showDeleteConfirmation(id, kind, amount);
          } else if (direction == DismissDirection.startToEnd && canEdit) {
            _navigateToEdit(item);
            return false;
          }
          return false;
        },
        background: canEdit
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "تعديل",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
        secondaryBackground: canDelete
            ? Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "حذف",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                  ],
                ),
              )
            : const SizedBox(),
        child: GestureDetector(
          onTap: () => _showExpenseDetails(item, isDark, canEdit, canDelete),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF5350).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Right Border Indicator
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: const Color(0xFFEF5350),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFFEF5350),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kind & Amount Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      kind,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "-${NumberFormat('#,##0').format(amount)} ج.م",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF5350),
                                    ),
                                  ),
                                ],
                              ),
                              // Byan
                              if (byan.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  byan,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              // Date & Branch Row
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('d MMM yyyy', 'ar').format(date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  if (branch.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.store,
                                            size: 10,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            branch,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              // User Row
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      user,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                ],
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
        ),
      ),
    );
  }

  // ============ EXPENSE DETAILS BOTTOM SHEET ============
  void _showExpenseDetails(
    Map<String, dynamic> item,
    bool isDark,
    bool canEdit,
    bool canDelete,
  ) {
    // 1. استخراج البيانات الأساسية
    final amount = _parseAmount(item['expenseAmount']);
    final dateStr = item['expenseDate'];
    final kind = item['KindName'] ?? 'عام';
    final branch = item['branchName'] ?? 'غير محدد';
    final byan = item['Byan'] ?? 'لا يوجد';
    final id = item['ID'];

    // 2. استخراج بيانات المستخدمين (لحل المشكلة) 🔥
    final userAdd = item['userAdd'] ?? 'غير معروف';
    final addTime = item['Addtime'];
    final useredit = item['useredit'];
    final editTime = item['editTime'];

    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تفاصيل المصروف",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "#$id",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "${NumberFormat('#,##0').format(amount)} ج.م",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),

            // Details
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.category_rounded,
                      "النوع",
                      kind,
                      isDark,
                    ),
                    _buildDetailRow(
                      Icons.store_rounded,
                      "الفرع",
                      branch,
                      isDark,
                    ),
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      "تاريخ المصروف",
                      DateFormat('EEEE، d MMMM yyyy', 'ar').format(date),
                      isDark,
                    ),

                    // بيانات الإضافة 🔥
                    _buildDetailRow(
                      Icons.person_add_rounded,
                      "تم الإضافة بواسطة",
                      "$userAdd\n${_formatDateTime(addTime)}",
                      isDark,
                    ),

                    // بيانات التعديل 🔥
                    if (useredit != null && useredit.toString().isNotEmpty)
                      _buildDetailRow(
                        Icons.edit_note_rounded,
                        "آخر تعديل بواسطة",
                        "$useredit\n${_formatDateTime(editTime)}",
                        isDark,
                        // valueColor: Colors.orange, // لو عايز تلونها
                      ),

                    _buildDetailRow(
                      Icons.notes_rounded,
                      "البيان",
                      byan.isEmpty ? "لا يوجد" : byan,
                      isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (canEdit || canDelete)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (canDelete)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _showDeleteConfirmation(id, kind, amount);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text("حذف"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    if (canEdit && canDelete) const SizedBox(width: 12),
                    if (canEdit)
                      Expanded(
                        flex: canDelete ? 2 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToEdit(item);
                            },
                            icon: const Icon(Icons.edit_rounded, color: Colors.white),
                            label: const Text(
                              "تعديل",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFEF5350)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ DELETE CONFIRMATION ============
  Future<bool?> _showDeleteConfirmation(int id, String kind, double amount) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Text("تأكيد الحذف", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("هل أنت متأكد من حذف هذا المصروف؟"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFFEF5350)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${NumberFormat('#,##0').format(amount)} ج.م",
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text(
                  "لا يمكن التراجع عن هذا الإجراء",
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey[600])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context, true);
                await _deleteExpense(id);
              },
              icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
              label: const Text("حذف", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await ApiService.deleteExpense(id);
      _showSuccessSnackBar("تم حذف المصروف بنجاح");
      _loadAllData();
    } catch (e) {
      _showErrorSnackBar("فشل حذف المصروف: $e");
    }
  }

  void _navigateToEdit(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(expense: item),
      ),
    );
    if (result == true) {
      _loadAllData();
    }
  }

  // ============ EMPTY STATE ============
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 60,
                color: Color(0xFFEF5350),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasActiveFilters ? "لا توجد نتائج" : "لا توجد مصروفات",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters
                  ? "جرب تغيير معايير البحث"
                  : "اضغط على + لإضافة مصروف جديد",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text("مسح الفلاتر"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  side: const BorderSide(color: Color(0xFFEF5350)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ ACCESS ERROR ============
  Widget _buildAccessError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_person_rounded, size: 60, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              "غير مصرح",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _accessError,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("العودة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ FAB ============
  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) _loadAllData();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "إضافة مصروف",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
    // ============ HELPER: FORMAT DATE TIME ============
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) return '';
    try {
      // تحويل النص لتاريخ وتنسيقه
      final dt = DateTime.parse(dateTime.toString());
      // تنسيق: 25/10/2023 - 10:30 م
      return DateFormat('d/M/yyyy - h:mm a', 'ar').format(dt); 
    } catch (_) {
      return '';
    }
  }
}