import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'add_eshraf_screen.dart';

class EshrafHistoryScreen extends StatefulWidget {
  const EshrafHistoryScreen({Key? key}) : super(key: key);

  @override
  State<EshrafHistoryScreen> createState() => _EshrafHistoryScreenState();
}

class _EshrafHistoryScreenState extends State<EshrafHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ==================== State Variables ====================
  bool _isLoading = false;
  List<dynamic> _transactions = [];

    // ✅ Filters - تاريخ الشهر الحالي
  late DateTime _fromDate;
  late DateTime _toDate;
  int? _selectedEmpId;
  String? _selectedEmpName;
  String _filterType = 'all';
  String? _selectedKind;
  List<dynamic> _eshrafTypes = [];

  // Totals
  double _totalDeductions = 0;
  double _totalAdditions = 0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== Lifecycle ====================
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1); // أول يوم في الشهر
    _toDate = DateTime(now.year, now.month + 1, 0); // آخر يوم في الشهر

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadTypes();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await ApiService.getEshrafTypes();
      setState(() {
        _eshrafTypes = types;
      });
    } catch (e) {
      debugPrint('Error loading types: $e');
    }
  }

  // ==================== Data Loading ====================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.searchEshraf(
        empId: _selectedEmpId,
        fromDate: _fromDate,
        toDate: _toDate,
        kind: _selectedKind,
      );

      setState(() {
        _transactions = data;
        _calculateTotals();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('خطأ في التحميل: $e');
      }
    }
  }

  void _calculateTotals() {
    double ded = 0;
    double add = 0;

    for (var item in _filteredTransactions) {
      double amount = double.tryParse(item['amountPenalty'].toString()) ?? 0;
      if (_isDeduction(item['KindPenalty'])) {
        ded += amount;
      } else {
        add += amount;
      }
    }

    setState(() {
      _totalDeductions = ded;
      _totalAdditions = add;
    });
  }

  // ==================== Snackbars ====================
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== Logic Helpers ====================
  bool _isDeduction(String? kind) {
    if (kind == null) return true;

    final String normalized = kind.trim();
    final additionsKeywords = [
      'مكافاه', 'مكافأة',
      'بدل',
      'حافز',
      'اضافى', 'اضافي', 'إضافي', 'إضافى'
    ];

    for (var word in additionsKeywords) {
      if (normalized.contains(word)) return false;
    }
    return true;
  }

  List<dynamic> get _filteredTransactions {
    if (_filterType == 'all') return _transactions;

    return _transactions.where((t) {
      bool isDed = _isDeduction(t['KindPenalty']);
      return _filterType == 'deduction' ? isDed : !isDed;
    }).toList();
  }

  // ==================== Actions ====================
  Future<void> _deleteTransaction(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(ctx).isDark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف هذا السجل نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteEshraf(id);
        await _loadData();
        if (mounted) {
          _showSuccessSnackBar('تم الحذف بنجاح');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorSnackBar('فشل الحذف: $e');
        }
      }
    }
  }

  Future<void> _editTransaction(Map<String, dynamic> item) async {
  
  final amountCtrl =
      TextEditingController(text: item['amountPenalty'].toString());
  final notesCtrl =
      TextEditingController(text: item['notesPenalty'] ?? '');
  final isDark =
      Provider.of<ThemeProvider>(context, listen: false).isDark;

  String? selectedKindId;
  String? selectedKindName = item['KindPenalty']?.toString();

  // ✅ محاولة تحديد النوع الحالي من القائمة المحملة
  for (final type in _eshrafTypes) {
    final typeId = type['id']?.toString();
    final typeName = type['name']?.toString();

    if (typeId == item['KindPenalty']?.toString() ||
        typeName == item['KindPenalty']?.toString()) {
      selectedKindId = typeId;
      selectedKindName = typeName;
      break;
    }
  }

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعديل',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    selectedKindName ?? 'اختر النوع',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ النوع
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedKindId,
                  isExpanded: true,
                  dropdownColor:
                      isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'النوع',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.category_rounded,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                  items: _eshrafTypes.map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(
                      value: type['id']?.toString(),
                      child: Text(
                        type['name'] ?? type['id'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedKindId = value;
                      final selectedType = _eshrafTypes.firstWhere(
                        (t) => t['id']?.toString() == value,
                        orElse: () => {'name': value},
                      );
                      selectedKindName =
                          selectedType['name']?.toString() ?? value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ✅ المبلغ
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    suffixText: 'ج.م',
                    suffixStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ الملاحظات
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.notes,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedKindId == null) {
                _showErrorSnackBar('اختر النوع');
                return;
              }

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final auth =
                    Provider.of<AuthProvider>(context, listen: false);

                await ApiService.updateEshraf(item['ID'], {
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'notes': notesCtrl.text,
                  'kind': selectedKindId, // ✅ النوع بعد التعديل
                  'user': auth.user?.fullName ?? 'Unknown',
                  'date': item['datePenalty'],
                });

                await _loadData();

                if (mounted) {
                  _showSuccessSnackBar('تم التعديل بنجاح');
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  _showErrorSnackBar('فشل التعديل: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'حفظ التعديلات',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _selectDateRange() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  // ==================== UI Build ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final filteredList = _filteredTransactions;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ✅ 1. AppBar محسن
          _buildSliverAppBar(isDark),

          // ✅ 2. Summary Cards
          SliverToBoxAdapter(
            child: _buildSummarySection(isDark),
          ),

          // ✅ 3. Filters Section
          SliverToBoxAdapter(
            child: _buildFiltersSection(isDark),
          ),

          // ✅ 4. Results Header
          SliverToBoxAdapter(
            child: _buildResultsHeader(isDark, filteredList.length),
          ),

          // ✅ 5. Transactions List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: _LoadingWidget()),
                )
              : filteredList.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(isDark),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildTransactionCard(
                                filteredList[index],
                                isDark,
                                index,
                              ),
                            );
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
        ],
      ),
      // ✅ 6. Extended FAB
      floatingActionButton: _buildFAB(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // ==================== AppBar ====================
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.blue.shade700,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D44)]
                  : [Colors.blue.shade700, Colors.blue.shade500],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سجل الجزاءات والمكافآت',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'إدارة ومتابعة المعاملات المالية',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==================== Summary Section ====================
  Widget _buildSummarySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildGradientSummaryCard(
              title: 'إجمالي الخصومات',
              value: _totalDeductions,
              icon: Icons.trending_down_rounded,
              gradientColors: [
                const Color(0xFFFF6B6B),
                const Color(0xFFEE5A5A),
              ],
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGradientSummaryCard(
              title: 'إجمالي الإضافات',
              value: _totalAdditions,
              icon: Icons.trending_up_rounded,
              gradientColors: [
                const Color(0xFF51CF66),
                const Color(0xFF40C057),
              ],
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              Icon(
                Icons.more_horiz,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,##0').format(value)} ج.م',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Progress indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: _totalDeductions + _totalAdditions > 0
                  ? value / (_totalDeductions + _totalAdditions)
                  : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Filters Section ====================
  Widget _buildFiltersSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Date & Employee
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_month_rounded,
                  label: '${DateFormat('dd/MM').format(_fromDate)} - ${DateFormat('dd/MM').format(_toDate)}',
                  color: Colors.blue,
                  isActive: true,
                  onTap: _selectDateRange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.person_rounded,
                  label: _selectedEmpName ?? 'كل الموظفين',
                  color: Colors.purple,
                  isActive: _selectedEmpId != null,
                  onTap: _showEmployeesListDialog,
                  onClear: _selectedEmpId != null
                      ? () {
                          setState(() {
                            _selectedEmpId = null;
                            _selectedEmpName = null;
                          });
                          _loadData();
                        }
                      : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Kind Filter
          _buildFilterButton(
            icon: Icons.category_rounded,
            label: _selectedKind ?? 'كل الأنواع',
            color: Colors.orange,
            isActive: _selectedKind != null,
            onTap: _showKindFilterSheet,
            onClear: _selectedKind != null
                ? () {
                    setState(() => _selectedKind = null);
                    _loadData();
                  }
                : null,
            isDark: isDark,
            fullWidth: true,
          ),
          const SizedBox(height: 12),

          // Row 3: Type Chips
          Row(
            children: [
              Expanded(child: _buildTypeChip('الكل', 'all', Colors.blue, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTypeChip('خصومات', 'deduction', Colors.red, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTypeChip('إضافات', 'addition', Colors.green, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
    required bool isDark,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? color : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? color : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: color),
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down_rounded,
                color: isActive ? color : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, Color color, bool isDark) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filterType = value;
          _calculateTotals();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (value == 'deduction')
              Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: isSelected ? Colors.white : color,
              )
            else if (value == 'addition')
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
            if (value != 'all') const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Results Header ====================
  Widget _buildResultsHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'النتائج',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count سجل',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Transaction Card ====================
  Widget _buildTransactionCard(dynamic item, bool isDark, int index) {
  final bool isDed = _isDeduction(item['KindPenalty']);
  final Color color = isDed ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  final String amount = NumberFormat('#,##0').format(item['amountPenalty'] ?? 0);

  final DateTime date = DateTime.parse(item['datePenalty']);
  final String dateStr = DateFormat('dd MMM yyyy', 'ar').format(date);

  final String kindName = item['KindPenalty'] ?? 'غير محدد';
  final String empName = item['empName'] ?? 'غير معروف';

  // ✅ بيانات الإنشاء
  final String? createdBy = item['userAdd'];
  final String? createdAt = item['Addtime'] != null
      ? DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(DateTime.parse(item['Addtime']))
      : null;

  // ✅ بيانات التعديل
  final String? editedBy = item['userEdit'];
  final String? editedAt = item['editTime'] != null
      ? DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(DateTime.parse(item['editTime']))
      : null;

  final bool wasEdited = editedBy != null && editedBy.isNotEmpty;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          // Colored Side Bar
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            empName[0].toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name & Kind
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    kindName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // ✅ علامة "معدّل" لو اتعدل
                                if (wasEdited)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 10,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'معدّل',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDed
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$amount ج.م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Notes (if exists)
                  if (item['notesPenalty'] != null &&
                      item['notesPenalty'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['notesPenalty'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ✅ معلومات الإنشاء والتعديل
                  const SizedBox(height: 10),
                  _buildUserInfoSection(
                    createdBy: createdBy,
                    createdAt: createdAt,
                    editedBy: editedBy,
                    editedAt: editedAt,
                    isDark: isDark,
                  ),

                  // Actions Row
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'تعديل',
                        color: Colors.blue,
                        onTap: () => _editTransaction(item),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'حذف',
                        color: Colors.red,
                        onTap: () => _deleteTransaction(item['ID']),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ Widget لعرض معلومات المستخدم (الإنشاء والتعديل)
Widget _buildUserInfoSection({
  required String? createdBy,
  required String? createdAt,
  required String? editedBy,
  required String? editedAt,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.blueGrey.shade900.withOpacity(0.3)
          : Colors.blueGrey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark ? Colors.blueGrey.shade700 : Colors.blueGrey.shade100,
      ),
    ),
    child: Column(
      children: [
        // ✅ بيانات الإنشاء
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.person_add_rounded,
                size: 14,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تم الإنشاء بواسطة',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdBy ?? 'غير معروف',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (createdAt != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // ✅ بيانات التعديل (لو موجودة)
        if (editedBy != null && editedBy.isNotEmpty) ...[
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark ? Colors.blueGrey.shade700 : Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر تعديل بواسطة',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      editedBy,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (editedAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        editedAt,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

  // ==================== Empty State ====================
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد سجلات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الفلاتر أو التاريخ',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEshrafScreen()),
              );
              _loadData();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة سجل جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FAB ====================
  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEshrafScreen()),
        );
        _loadData();
      },
      backgroundColor: Colors.blue.shade600,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'إضافة',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== Bottom Sheets ====================
  void _showKindFilterSheet() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'اختر النوع',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              height: 1,
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // All Option
                    _buildKindOptionTile(
                      icon: Icons.all_inclusive_rounded,
                      label: 'كل الأنواع',
                      color: Colors.blue,
                      isSelected: _selectedKind == null,
                      onTap: () {
                        setState(() => _selectedKind = null);
                        Navigator.pop(context);
                        _loadData();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // Deductions Section
                    _buildSectionHeader('الخصومات', Colors.red, Icons.remove_circle, isDark),
                    ..._eshrafTypes
                        .where((t) => t['type'] == 'deduction')
                        .map((type) => _buildKindOptionTile(
                              icon: Icons.remove_circle_outline,
                              label: type['name'] ?? type['id'],
                              color: Colors.red,
                              isSelected: _selectedKind == type['id'],
                              onTap: () {
                                setState(() => _selectedKind = type['id']);
                                Navigator.pop(context);
                                _loadData();
                              },
                              isDark: isDark,
                            ))
                        .toList(),
                    const SizedBox(height: 8),
                    // Additions Section
                    _buildSectionHeader('الإضافات', Colors.green, Icons.add_circle, isDark),
                    ..._eshrafTypes
                        .where((t) => t['type'] == 'addition')
                        .map((type) => _buildKindOptionTile(
                              icon: Icons.add_circle_outline,
                              label: type['name'] ?? type['id'],
                              color: Colors.green,
                              isSelected: _selectedKind == type['id'],
                              onTap: () {
                                setState(() => _selectedKind = type['id']);
                                Navigator.pop(context);
                                _loadData();
                              },
                              isDark: isDark,
                            ))
                        .toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKindOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEmployeesListDialog() async {
    try {
      final employees = await ApiService.getEmployees();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _EmployeesBottomSheet(
          employees: employees,
          selectedId: _selectedEmpId,
          onSelect: (id, name) {
            setState(() {
              _selectedEmpId = id;
              _selectedEmpName = name;
            });
            _loadData();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }
}

// ==================== Loading Widget ====================
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'جاري التحميل...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ==================== Employees Bottom Sheet ====================
class _EmployeesBottomSheet extends StatefulWidget {
  final List<dynamic> employees;
  final int? selectedId;
  final Function(int id, String name) onSelect;

  const _EmployeesBottomSheet({
    Key? key,
    required this.employees,
    this.selectedId,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<_EmployeesBottomSheet> createState() => _EmployeesBottomSheetState();
}

class _EmployeesBottomSheetState extends State<_EmployeesBottomSheet> {
  List<dynamic> _filteredList = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
void initState() {
  super.initState();
  _filteredList = widget.employees.where((e) {
    return e['empstatus'] == true || e['empstatus'] == 1;
  }).toList();
}

  void _filter(String query) {
  final activeEmployees = widget.employees.where((e) {
    return e['empstatus'] == true || e['empstatus'] == 1;
  }).toList();

  setState(() {
    if (query.isEmpty) {
      _filteredList = activeEmployees;
    } else {
      _filteredList = activeEmployees.where((e) {
          final name = (e['empName'] ?? '').toString().toLowerCase();
          final job = (e['job'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              job.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختر موظف',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${widget.employees.where((e) => e['empstatus'] == true || e['empstatus'] == 1).length} موظف',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الوظيفة...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _filter,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            height: 1,
          ),
          // List
          Expanded(
            child: _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade600 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final emp = _filteredList[index];
                      final isSelected = widget.selectedId == emp['ID'];
                      final name = emp['empName'] ?? 'غير معروف';
                      final job = emp['job'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onSelect(emp['ID'], name);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purple
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [Colors.purple, Colors.purple.shade300]
                                          : [Colors.blue.shade400, Colors.blue.shade300],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      if (job.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          job,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}