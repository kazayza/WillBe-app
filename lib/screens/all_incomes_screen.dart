import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AllIncomesScreen extends StatefulWidget {
  const AllIncomesScreen({super.key});

  @override
  State<AllIncomesScreen> createState() => _AllIncomesScreenState();
}

class _AllIncomesScreenState extends State<AllIncomesScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════════════════════════
  
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  // ═══════════════════════════════════════════════════════════════
  // Animation Controllers
  // ═══════════════════════════════════════════════════════════════
  
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnimation;

  // ═══════════════════════════════════════════════════════════════
  // Data
  // ═══════════════════════════════════════════════════════════════
  
  List<dynamic> _incomes = [];
  List<dynamic> _sessions = [];
  List<dynamic> _branches = [];
  List<dynamic> _kinds = [];
  List<dynamic> _children = [];
  List<dynamic> _filteredChildren = [];

  // ═══════════════════════════════════════════════════════════════
  // Filters
  // ═══════════════════════════════════════════════════════════════
  
  int? _selectedSessionId;
  int? _selectedBranchId;
  int? _selectedKindId;
  int? _selectedChildId;
  String? _selectedChildName;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  String _selectedQuickFilter = 'month';

  // ═══════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════
  
  bool _isLoading = true;
  bool _isFilterLoading = false;
  bool _showChildSearch = false;
  bool _isLookupsLoading = true;
  String? _error;
  double? _lastMonthTotal;

  // ═══════════════════════════════════════════════════════════════
  // Constants
  // ═══════════════════════════════════════════════════════════════
  
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);
  
  static const Map<String, Color> _kindColors = {
    'اشتراك': Color(0xFF6366F1),
    'كورس': Color(0xFF8B5CF6),
    'نشاط': Color(0xFF06B6D4),
    'مبيعات': Color(0xFFF59E0B),
    'أخرى': Color(0xFF64748B),
  };

  final _currencyFormat = NumberFormat('#,###', 'ar_EG');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');
  final _dayFormat = DateFormat('EEEE dd MMMM yyyy', 'ar_EG');

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setDefaultDateFilter();
    _initData();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimController.forward();
  }

  void _setDefaultDateFilter() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadLookups(),
      _fetchIncomes(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Load Data
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadLookups() async {
    setState(() => _isLookupsLoading = true);

    try {
      final sessions = await ApiService.get('general/sessions');
      _sessions = _toList(sessions);
    } catch (e) {
      debugPrint('❌ Sessions Error: $e');
    }

    try {
      final branches = await ApiService.get('general/branches');
      _branches = _toList(branches);
    } catch (e) {
      debugPrint('❌ Branches Error: $e');
    }

    try {
      final kinds = await ApiService.get('incomes/kinds/all');
      _kinds = _toList(kinds);
    } catch (e) {
      debugPrint('❌ Kinds Error: $e');
    }

    try {
      final children = await ApiService.get('children');
      _children = _toList(children);
    } catch (e) {
      debugPrint('❌ Children Error: $e');
    }

    if (mounted) {
      setState(() {
        _filteredChildren = _children.take(15).toList();
        _isLookupsLoading = false;
      });
    }
  }

  List<dynamic> _toList(dynamic data) {
    if (data is List) return List<dynamic>.from(data);
    return [];
  }

  Future<void> _fetchIncomes() async {
    setState(() {
      _isFilterLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.filterIncomes(
        sessionId: _selectedSessionId,
        branchId: _selectedBranchId,
        kindId: _selectedKindId,
        childId: _selectedChildId,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (_selectedQuickFilter == 'month') {
        await _fetchLastMonthTotal();
      } else {
        _lastMonthTotal = null;
      }

      if (mounted) {
        setState(() {
          _incomes = data;
          _isLoading = false;
          _isFilterLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFilterLoading = false;
          _error = e.toString();
        });
        _showSnackBar('خطأ في تحميل البيانات', isError: true);
      }
    }
  }

  Future<void> _fetchLastMonthTotal() async {
    try {
      final now = DateTime.now();
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      final data = await ApiService.filterIncomes(
        fromDate: lastMonthStart,
        toDate: lastMonthEnd,
      );

      double total = 0;
      for (var item in data) {
        total += (item['incomeAmount'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() => _lastMonthTotal = total);
      }
    } catch (e) {
      debugPrint('Error fetching last month: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Quick Filters
  // ═══════════════════════════════════════════════════════════════

  void _applyQuickFilter(String filter) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();

    setState(() {
      _selectedQuickFilter = filter;

      switch (filter) {
        case 'today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          _fromDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'custom':
          break;
      }
    });

    if (filter != 'custom') {
      _fetchIncomes();
    } else {
      _showDateRangePicker();
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              onSurface: _isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _fetchIncomes();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Child Search
  // ═══════════════════════════════════════════════════════════════

  void _filterChildren(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredChildren = _children.take(15).toList();
        } else {
          _filteredChildren = _children.where((child) {
            final name = _getChildName(child).toLowerCase();
            final code = (child['id'] ?? child['ID'] ?? '').toString();
            return name.contains(query.toLowerCase()) || code.contains(query);
          }).take(20).toList();
        }
      });
    });
  }

  String _getChildName(dynamic child) {
    return child['fullNameArabic']?.toString() ??
           child['FullNameArabic']?.toString() ??
           'غير معروف';
  }

  int? _getChildId(dynamic child) {
    return child['id'] ?? child['ID'] ?? child['ID_Child'];
  }

  void _selectChild(Map<String, dynamic>? child) {
    HapticFeedback.lightImpact();
    setState(() {
      if (child == null) {
        _selectedChildId = null;
        _selectedChildName = null;
      } else {
        _selectedChildId = child['ID_Child'];
        _selectedChildName = child['FullNameArabic'];
      }
      _showChildSearch = false;
      _searchController.clear();
      _searchQuery = '';
      _filteredChildren = _children.take(15).toList();
    });
    _fetchIncomes();
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSessionId = null;
      _selectedBranchId = null;
      _selectedKindId = null;
    });
    _fetchIncomes();
  }

  void _resetToDefaults() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedSessionId = null;
      _selectedBranchId = null;
      _selectedKindId = null;
      _selectedChildId = null;
      _selectedChildName = null;
      _selectedQuickFilter = 'month';
    });
    _setDefaultDateFilter();
    _fetchIncomes();
  }
    // ═══════════════════════════════════════════════════════════════
  // Delete Income
  // ═══════════════════════════════════════════════════════════════

  Future<void> _deleteIncome(Map<String, dynamic> item) async {
  // ✅ رسالة تأكيد
  final confirm = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded, color: _errorColor, size: 40),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'حذف الإيراد',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Message
          Text(
            'هل أنت متأكد من حذف إيراد "${item['ChildName'] ?? 'غير معروف'}" بمبلغ ${_currencyFormat.format(item['incomeAmount'] ?? 0)} ج.م؟',
            textAlign: TextAlign.center,
            style: TextStyle(color: _isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          
          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _warningColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'هذا الإجراء لا يمكن التراجع عنه!',
                    style: TextStyle(
                      color: _warningColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: _isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: _isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_rounded, size: 20),
                  label: const Text('نعم، احذف', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    ),
  );

  // ✅ لو وافق على الحذف
  if (confirm == true) {
    HapticFeedback.mediumImpact();
    
    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              SizedBox(height: 16),
              Text('جاري الحذف...'),
            ],
          ),
        ),
      ),
    );
    
    try {
      final result = await ApiService.deleteIncome(item['ID']);
      
      // Close loading
      Navigator.pop(context);
      
      if (result['success'] == true) {
        setState(() {
          _incomes.removeWhere((i) => i['ID'] == item['ID']);
        });
        _showSnackBar('تم حذف الإيراد بنجاح ✅');
      } else {
        _showSnackBar(result['message'] ?? 'فشل الحذف', isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('خطأ في الحذف: $e', isError: true);
    }
  }
}

  Future<bool?> _showDeleteConfirmation(Map<String, dynamic> item) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _errorColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'حذف الإيراد',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هل أنت متأكد من حذف إيراد "${item['ChildName'] ?? 'غير معروف'}" بمبلغ ${_currencyFormat.format(item['incomeAmount'] ?? 0)} ج.م؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: _isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers & Calculations
  // ═══════════════════════════════════════════════════════════════

  double get _totalAmount {
    return _incomes.fold<double>(0, (sum, item) => sum + (item['incomeAmount'] ?? 0).toDouble());
  }

  double? get _percentageChange {
    if (_lastMonthTotal == null || _lastMonthTotal == 0) return null;
    return ((_totalAmount - _lastMonthTotal!) / _lastMonthTotal!) * 100;
  }

  Map<String, List<dynamic>> get _groupedIncomes {
    Map<String, List<dynamic>> grouped = {};
    for (var item in _incomes) {
      try {
        final date = DateTime.parse(item['incomeDate'].toString());
        final dateKey = _dayFormat.format(date);
        grouped.putIfAbsent(dateKey, () => []).add(item);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    return grouped;
  }

  Map<String, double> get _statsByKind {
    Map<String, double> stats = {};
    for (var item in _incomes) {
      final kind = item['kindGroup'] ?? item['KindName'] ?? 'أخرى';
      stats[kind] = (stats[kind] ?? 0) + (item['incomeAmount'] ?? 0).toDouble();
    }
    return stats;
  }

  String get _filterTitle {
    switch (_selectedQuickFilter) {
      case 'today': return 'إجمالي اليوم';
      case 'week': return 'إجمالي الأسبوع';
      case 'month': return 'إجمالي الشهر الحالي';
      case 'year': return 'إجمالي السنة';
      case 'custom': return 'الفترة المحددة';
      default: return 'الإجمالي';
    }
  }

  bool get _hasActiveFilters {
    return _selectedSessionId != null || _selectedBranchId != null || _selectedKindId != null;
  }

  String _formatDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  
  try {
    final date = DateTime.parse(dateStr);
    
    // تنسيق التاريخ والوقت
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');
    final timeFormat = DateFormat('hh:mm a', 'ar_EG');
    
    final dateText = dateFormat.format(date);
    final timeText = timeFormat.format(date);
    
    return '$dateText - $timeText';
  } catch (e) {
    return '';
  }
}

  Color _getKindColor(String? kindGroup) {
    if (kindGroup == null) return _kindColors['أخرى']!;
    for (var entry in _kindColors.entries) {
      if (kindGroup.contains(entry.key)) return entry.value;
    }
    return _kindColors['أخرى']!;
  }

  IconData _getKindIcon(String kind) {
    if (kind.contains('اشتراك')) return Icons.school_rounded;
    if (kind.contains('كورس')) return Icons.menu_book_rounded;
    if (kind.contains('نشاط')) return Icons.sports_soccer_rounded;
    if (kind.contains('مبيعات')) return Icons.shopping_bag_rounded;
    return Icons.category_rounded;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchIncomes,
        color: _primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSummaryCard(),
                  if (_statsByKind.isNotEmpty) _buildStatsRow(),
                  _buildQuickFilters(),
                  if (_showChildSearch) _buildChildSearchSection(),
                  _buildFiltersSection(),
                  if (_selectedChildId != null) _buildChildFilterChip(),
                ],
              ),
            ),
            _buildContent(auth),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _isDark ? const Color(0xFF1A1A2E) : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _isDark ? Colors.white : Colors.black87),
        ),
      ),
      title: Text(
        'سجل الإيرادات',
        style: TextStyle(color: _isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => setState(() => _showChildSearch = !_showChildSearch),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _showChildSearch ? _primaryColor.withOpacity(0.2) : (_isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.search_rounded, size: 18, color: _showChildSearch ? _primaryColor : (_isDark ? Colors.white : Colors.black87)),
          ),
        ),
        IconButton(
          onPressed: _fetchIncomes,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isFilterLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor))
                : Icon(Icons.refresh_rounded, size: 18, color: _isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCard() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_filterTitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('${_incomes.length} إيراد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('${_currencyFormat.format(_totalAmount)} ج.م', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            if (_percentageChange != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (_percentageChange! >= 0 ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_percentageChange! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${_percentageChange!.abs().toStringAsFixed(1)}% ${_percentageChange! >= 0 ? 'زيادة' : 'انخفاض'} عن الشهر السابق',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    final stats = _statsByKind;
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final kind = stats.keys.elementAt(index);
          final amount = stats[kind]!;
          final color = _getKindColor(kind);

          return Container(
            margin: EdgeInsets.only(right: index < stats.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_getKindIcon(kind), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kind, style: TextStyle(fontSize: 12, color: _isDark ? Colors.grey[400] : Colors.grey[600])),
                    Text('${_currencyFormat.format(amount)} ج.م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK FILTERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickFilters() {
    final filters = [
      {'id': 'today', 'label': 'اليوم', 'icon': Icons.today_rounded},
      {'id': 'week', 'label': 'الأسبوع', 'icon': Icons.date_range_rounded},
      {'id': 'month', 'label': 'الشهر', 'icon': Icons.calendar_month_rounded},
      {'id': 'year', 'label': 'السنة', 'icon': Icons.calendar_today_rounded},
      {'id': 'custom', 'label': 'مخصص', 'icon': Icons.tune_rounded},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedQuickFilter == filter['id'];

          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => _applyQuickFilter(filter['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [_primaryColor, Color(0xFF8B5CF6)]) : null,
                  color: isSelected ? null : (_isDark ? const Color(0xFF1E1E2E) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? Colors.transparent : (_isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                  boxShadow: isSelected ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Row(
                  children: [
                    Icon(filter['icon'] as IconData, size: 18, color: isSelected ? Colors.white : (_isDark ? Colors.grey[400] : Colors.grey[600])),
                    const SizedBox(width: 8),
                    Text(filter['label'] as String, style: TextStyle(color: isSelected ? Colors.white : (_isDark ? Colors.grey[400] : Colors.grey[600]), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHILD SEARCH
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو الكود...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: _primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); _filterChildren(''); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.transparent,
            ),
            onChanged: _filterChildren,
          ),
          if (_filteredChildren.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _filteredChildren.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _isDark ? Colors.grey[800] : Colors.grey[200]),
                itemBuilder: (context, index) {
                  final child = _filteredChildren[index];
                  final name = _getChildName(child);
                  final code = _getChildId(child)?.toString() ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: Text(name.isNotEmpty ? name[0] : 'ط', style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: TextStyle(color: _isDark ? Colors.white : Colors.black87)),
                    subtitle: Text('كود: $code', style: TextStyle(fontSize: 12, color: _isDark ? Colors.grey[500] : Colors.grey[600])),
                    onTap: () => _selectChild({'ID_Child': _getChildId(child), 'FullNameArabic': name}),
                  );
                },
              ),
            ),
          if (_filteredChildren.isEmpty && _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('لا توجد نتائج لـ "$_searchQuery"', style: TextStyle(color: _isDark ? Colors.grey[500] : Colors.grey[600])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFiltersSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: _clearAllFilters,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _errorColor, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          _buildFilterDropdown(hint: 'العام المالي', value: _selectedSessionId, items: _sessions, valueKey: 'IDSession', textKey: 'Sessions', icon: Icons.calendar_today_rounded, onChanged: (val) { setState(() => _selectedSessionId = val); _fetchIncomes(); }),
          const SizedBox(width: 10),
          _buildFilterDropdown(hint: 'الفرع', value: _selectedBranchId, items: _branches, valueKey: 'IDbranch', textKey: 'branchName', icon: Icons.location_city_rounded, onChanged: (val) { setState(() => _selectedBranchId = val); _fetchIncomes(); }),
          const SizedBox(width: 10),
          _buildFilterDropdown(hint: 'النوع', value: _selectedKindId, items: _kinds, valueKey: 'ID', textKey: 'incomeKind', icon: Icons.category_rounded, onChanged: (val) { setState(() => _selectedKindId = val); _fetchIncomes(); }),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String hint, required int? value, required List<dynamic> items, required String valueKey, required String textKey, required IconData icon, required Function(int?) onChanged}) {
    final validValue = (value != null && items.any((item) => item[valueKey] == value)) ? value : null;
    final isSelected = validValue != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor.withOpacity(0.1) : (_isDark ? const Color(0xFF1E1E2E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _primaryColor : (_isDark ? Colors.grey[700]! : Colors.grey[300]!)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validValue,
          hint: Row(children: [Icon(icon, size: 16, color: _isDark ? Colors.grey[500] : Colors.grey[600]), const SizedBox(width: 8), Text(hint, style: TextStyle(fontSize: 13, color: _isDark ? Colors.grey[500] : Colors.grey[600]))]),
          icon: Icon(Icons.arrow_drop_down, color: isSelected ? _primaryColor : (_isDark ? Colors.grey[500] : Colors.grey[600])),
          isDense: true,
          dropdownColor: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          items: items.map<DropdownMenuItem<int>>((item) => DropdownMenuItem(value: item[valueKey], child: Text(item[textKey]?.toString() ?? '', style: TextStyle(fontSize: 13, color: _isDark ? Colors.white : Colors.black87)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChildFilterChip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primaryColor, Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.child_care, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(_selectedChildName ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _selectChild(null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    // ═══════════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContent(AuthProvider auth) {
    if (_isLoading) {
      return SliverFillRemaining(child: _buildSkeletonLoading());
    }
    if (_error != null) {
      return SliverFillRemaining(child: _buildErrorState());
    }
    if (_incomes.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }
    return _buildIncomesList(auth);
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: _isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(14))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 150, height: 16, decoration: BoxDecoration(color: _isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, decoration: BoxDecoration(color: _isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                      ],
                    ),
                  ),
                  Container(width: 80, height: 20, decoration: BoxDecoration(color: _isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _errorColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 64, color: _errorColor),
          ),
          const SizedBox(height: 24),
          Text('حدث خطأ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_error ?? '', style: TextStyle(color: _isDark ? Colors.grey[500] : Colors.grey[600]), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchIncomes,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _isDark ? const Color(0xFF1E1E2E) : Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined, size: 64, color: _isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text('لا توجد إيرادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('لا توجد بيانات تطابق الفلاتر المحددة', style: TextStyle(color: _isDark ? Colors.grey[500] : Colors.grey[600])),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _resetToDefaults, icon: const Icon(Icons.refresh), label: const Text('إعادة تعيين الفلاتر')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INCOMES LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildIncomesList(AuthProvider auth) {
    final grouped = _groupedIncomes;
    final dates = grouped.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final date = dates[index];
            final items = grouped[date]!;
            final dayTotal = items.fold<double>(0, (sum, item) => sum + (item['incomeAmount'] ?? 0).toDouble());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDark ? _primaryColor.withOpacity(0.1) : _primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.calendar_today_rounded, color: _primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date, style: TextStyle(fontWeight: FontWeight.bold, color: _isDark ? Colors.white : Colors.black87, fontSize: 13)),
                            Text('${items.length} إيراد', style: TextStyle(fontSize: 11, color: _isDark ? Colors.grey[500] : Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _successColor, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_currencyFormat.format(dayTotal)} ج.م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                // Income Cards
                ...items.asMap().entries.map((entry) => _buildIncomeCard(entry.value, entry.key, auth)),
              ],
            );
          },
          childCount: dates.length,
        ),
      ),
    );
  }

  Widget _buildIncomeCard(Map<String, dynamic> item, int index, AuthProvider auth) {
    final kindGroup = item['kindGroup']?.toString() ?? '';
    final kindColor = _getKindColor(kindGroup);
    final canEdit = auth.canEdit('frmListIncome');
    final canDelete = auth.canDelete('frmListIncome');

      return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 150)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Transform.translate(
      offset: Offset(20 * (1 - value), 0),
      child: Opacity(opacity: value, child: child),
    ),
    // ✅ شيلنا الـ Dismissible وحطينا Container مباشرة
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kindColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kindColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(_getKindIcon(kindGroup), color: kindColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['ChildName'] ?? 'بدون اسم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: kindColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(item['KindName'] ?? '-', style: TextStyle(fontSize: 10, color: kindColor, fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text('${item['branchName'] ?? '-'}', style: TextStyle(fontSize: 11, color: _isDark ? Colors.grey[500] : Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyFormat.format(item['incomeAmount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _successColor)),
                      const Text('ج.م', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      if (item['ReceiptNumber'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _isDark ? Colors.grey[800] : Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                          child: Text('#${item['ReceiptNumber']}', style: TextStyle(fontSize: 9, color: _isDark ? Colors.grey[400] : Colors.grey[600])),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Add Info
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person_add_outlined, size: 14, color: _successColor.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['userAdd'] ?? '-', style: TextStyle(fontSize: 11, color: _isDark ? Colors.grey[400] : Colors.grey[700]), overflow: TextOverflow.ellipsis),
                              Text(_formatDateTime(item['Addtime']?.toString()), style: TextStyle(fontSize: 9, color: _isDark ? Colors.grey[600] : Colors.grey[500])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit Info
                  if (item['useredit'] != null) ...[
                    Container(width: 1, height: 25, color: _isDark ? Colors.grey[800] : Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 10)),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: _warningColor.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['useredit'] ?? '', style: TextStyle(fontSize: 11, color: _isDark ? Colors.grey[400] : Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                Text(_formatDateTime(item['editTime']?.toString()), style: TextStyle(fontSize: 9, color: _isDark ? Colors.grey[600] : Colors.grey[500])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Actions
                  if (canEdit || canDelete) ...[
                    Container(width: 1, height: 25, color: _isDark ? Colors.grey[800] : Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 10)),
                    if (canEdit)
                      GestureDetector(
                        onTap: () => _openEditSheet(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit_rounded, size: 16, color: _primaryColor),
                        ),
                      ),
                    if (canEdit && canDelete) const SizedBox(width: 8),
                    if (canDelete)
                      GestureDetector(
                        onTap: () => _deleteIncome(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_rounded, size: 16, color: _errorColor),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EDIT SHEET
  // ═══════════════════════════════════════════════════════════════

  void _openEditSheet(Map<String, dynamic> income) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditIncomeSheet(
        income: income,
        sessions: _sessions,
        branches: _branches,
        kinds: _kinds,
        isDark: _isDark,
        onSave: () {
          Navigator.pop(context);
          _fetchIncomes();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EDIT INCOME SHEET
// ═══════════════════════════════════════════════════════════════

class _EditIncomeSheet extends StatefulWidget {
  final Map<String, dynamic> income;
  final List<dynamic> sessions;
  final List<dynamic> branches;
  final List<dynamic> kinds;
  final bool isDark;
  final VoidCallback onSave;

  const _EditIncomeSheet({
    required this.income,
    required this.sessions,
    required this.branches,
    required this.kinds,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends State<_EditIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _receiptCtrl;

  int? _branchId;
  int? _kindId;
  int? _sessionId;
  DateTime? _payDate;
  bool _isSaving = false;

  static const _primaryColor = Color(0xFF6366F1);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.income['incomeAmount']?.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.income['Notes'] ?? '');
    _receiptCtrl = TextEditingController(text: widget.income['ReceiptNumber']?.toString() ?? '');

    _branchId = widget.income['BranchId'] ?? widget.income['branchId'];
    _kindId = widget.income['KindId'] ?? widget.income['kindId'];
    _sessionId = widget.income['incomeSessiontxt'] ?? widget.income['sessionId'];

    if (widget.income['incomeDate'] != null) {
      try {
        _payDate = DateTime.parse(widget.income['incomeDate'].toString());
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _receiptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final user = Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? 'System';

    try {
      await ApiService.put(
        'incomes/${widget.income['ID']}',
        {
          'amount': double.tryParse(_amountCtrl.text) ?? 0,
          'childId': widget.income['ID_Child'] ?? widget.income['childId'],
          'branchId': _branchId ?? widget.income['BranchId'] ?? widget.income['branchId'],
          'kindId': _kindId ?? widget.income['KindId'] ?? widget.income['kindId'],
          'sessionId': _sessionId ?? widget.income['incomeSessiontxt'] ?? widget.income['sessionId'],
          'receiptNo': _receiptCtrl.text,
          'notes': _notesCtrl.text,
          'payDate': _payDate?.toIso8601String(),
          'useredit': user,
          'editTime': DateTime.now().toIso8601String(),
        },
      );
      widget.onSave();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التعديل: $e'), backgroundColor: _errorColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(top: 20, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.edit_rounded, color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تعديل الإيراد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Text(widget.income['ChildName'] ?? 'بدون اسم', style: const TextStyle(fontSize: 14, color: _primaryColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('#${widget.income['ID'] ?? '-'}', style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : (double.tryParse(v) == null ? 'قيمة غير صالحة' : null),
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: _primaryColor),
                  filled: true,
                  fillColor: widget.isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              // Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _payDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _payDate = picked);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: _primaryColor),
                      const SizedBox(width: 12),
                      Text(_payDate != null ? DateFormat('yyyy/MM/dd').format(_payDate!) : 'اختر التاريخ', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Kind & Branch
              Row(
                children: [
                  Expanded(child: _buildDropdown(label: 'النوع', value: _kindId, items: widget.kinds, valueKey: 'ID', textKey: 'incomeKind', onChanged: (v) => setState(() => _kindId = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown(label: 'الفرع', value: _branchId, items: widget.branches, valueKey: 'IDbranch', textKey: 'branchName', onChanged: (v) => setState(() => _branchId = v))),
                ],
              ),
              const SizedBox(height: 16),
              // Receipt
              TextFormField(
                controller: _receiptCtrl,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'رقم الإيصال',
                  prefixIcon: const Icon(Icons.receipt_rounded, color: _primaryColor),
                  filled: true,
                  fillColor: widget.isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: const Icon(Icons.notes_rounded, color: _primaryColor),
                  filled: true,
                  fillColor: widget.isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_rounded), SizedBox(width: 8), Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required int? value, required List<dynamic> items, required String valueKey, required String textKey, required Function(int?) onChanged}) {
    final validValue = (value != null && items.any((item) => item[valueKey] == value)) ? value : null;

    return DropdownButtonFormField<int>(
      initialValue: validValue,
      isExpanded: true,
      items: items.map<DropdownMenuItem<int>>((item) => DropdownMenuItem(
      value: item[valueKey],
      child: Text(
        item[textKey]?.toString() ?? '',
        style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white : Colors.black87),
        overflow: TextOverflow.ellipsis,  // ✅ لو النص طويل يقطعه بـ ...
        maxLines: 1,
      ),
    )).toList(),
      onChanged: onChanged,
      dropdownColor: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: widget.isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}