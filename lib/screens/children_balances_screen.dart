import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'child_debt_details_screen.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ChildrenBalancesScreen extends StatefulWidget {
  const ChildrenBalancesScreen({super.key});

  @override
  State<ChildrenBalancesScreen> createState() => _ChildrenBalancesScreenState();
}

class _ChildrenBalancesScreenState extends State<ChildrenBalancesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoadingLookups = true;

  List<dynamic> _allDebts = [];
  List<dynamic> _filteredDebts = [];

  List<dynamic> _sessions = [];
  List<dynamic> _branches = [];

  int? _selectedSessionId;
  String? _selectedSessionName;
  int? _selectedBranchId;
  String _selectedType = 'all';
  final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
bool _isExporting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'ar_EG');

  double _totalRequired = 0;
  double _totalPaid = 0;
  double _totalRemaining = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final sessions = await ApiService.getSessions();
      final branches = await ApiService.get('general/branches');

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _branches = branches is List ? branches : [];
          _isLoadingLookups = false;

          if (_sessions.isNotEmpty) {
            _selectedSessionId = _sessions.first['IDSession'];
            _selectedSessionName = _sessions.first['Sessions'];
          }
        });
        if (_selectedSessionId != null) _fetchData();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _fetchData() async {
    if (_selectedSessionId == null) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getAllDebts(_selectedSessionId!);
      if (mounted) {
        setState(() {
          _allDebts = data;
          _isLoading = false;
        });
        _applyFilters();
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
  List<dynamic> result = List.from(_allDebts);

  if (_selectedBranchId != null) {
    result = result.where((i) => i['Branch'] == _selectedBranchId).toList();
  }

  if (_selectedType != 'all') {
    result = result.where((i) {
      final kind = (i['Kind_subscrip'] ?? '').toString();
      if (_selectedType == 'study') return kind == 'اشتراك الدراسة السنوى';
      if (_selectedType == 'bus') return kind == 'اشتراك الباص';
      return true;
    }).toList();
  }

  if (_searchQuery.isNotEmpty) {
    result = result.where((i) {
      final name = (i['FullNameArabic'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  double req = 0, paid = 0, rem = 0;
  for (final i in result) {
    final a = _d(i['amount_Sub']);
    final p = _d(i['totalPaid']);
    final r = (a - p).clamp(0, a);
    req += a;
    paid += p;
    rem += r;
  }

  setState(() {
    _filteredDebts = result;
    _totalRequired = req;
    _totalPaid = paid;
    _totalRemaining = rem;
  });
}

  double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
void dispose() {
  _animationController.dispose();
  _searchController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(child: _buildFilters(isDark)),
          if (!_isLoading && _filteredDebts.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildSummary(isDark)),
            SliverToBoxAdapter(child: _buildTableHeader(isDark)),
          ],
          if (_isLoading || _isLoadingLookups)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            )
          else if (_filteredDebts.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(isDark))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildTableRow(_filteredDebts[i], isDark, i),
                  ),
                  childCount: _filteredDebts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================
  // AppBar
  // =============================================
  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 150,
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
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
  // تصدير
  if (_filteredDebts.isNotEmpty)
    PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isExporting
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'excel') _exportToExcel();
        if (value == 'pdf') _exportToPDF();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 12),
              Text('تصدير Excel'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 12),
              Text('تصدير PDF'),
            ],
          ),
        ),
      ],
    ),
  // تحديث
  IconButton(
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
    ),
    onPressed: _fetchData,
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
                right: -50, top: -50,
                child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 24, left: 20, right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أرصدة الأطفال',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'استعلام الأرصدة حسب العام المالي',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
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
  Widget _buildFilters(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // العام المالي
          _filterDropdown(
            isDark: isDark,
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF6366F1),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedSessionId,
                isExpanded: true,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                items: _sessions.map((s) => DropdownMenuItem<int>(
                  value: s['IDSession'],
                  child: Text(s['Sessions'] ?? ''),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    final sel = _sessions.firstWhere((s) => s['IDSession'] == v, orElse: () => null);
                    setState(() {
                      _selectedSessionId = v;
                      _selectedSessionName = sel?['Sessions'];
                    });
                    _fetchData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // الفرع
          _filterDropdown(
            isDark: isDark,
            icon: Icons.store_rounded,
            color: const Color(0xFF10B981),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedBranchId,
                isExpanded: true,
                isDense: true,
                hint: Text('كل الفروع', style: TextStyle(color: Colors.grey[500])),
                dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('كل الفروع')),
                  ..._branches.map((b) => DropdownMenuItem<int?>(
                    value: b['IDbranch'],
                    child: Text(b['branchName'] ?? ''),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _selectedBranchId = v);
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // البحث
Container(
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
  ),
  child: TextField(
    controller: _searchController,
    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
    onChanged: (val) {
      _searchQuery = val;
      _applyFilters();
    },
    decoration: InputDecoration(
      hintText: 'بحث باسم الطفل...',
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              },
            )
          : null,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  ),
),
const SizedBox(height: 12),

          // نوع الاشتراك
          Row(
            children: [
              Expanded(child: _typeChip('الكل', 'all', const Color(0xFF6366F1), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _typeChip('الدراسة', 'study', const Color(0xFF10B981), isDark)),
              const SizedBox(width: 8),
              Expanded(child: _typeChip('الباص', 'bus', const Color(0xFFF59E0B), isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({required bool isDark, required IconData icon, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _typeChip(String label, String value, Color color, bool isDark) {
    final sel = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = value);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: [color, color.withOpacity(0.8)]) : null,
          color: sel ? null : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? Colors.transparent : color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? Colors.white : color)),
        ),
      ),
    );
  }

  // =============================================
  // الملخص مع عدد الأطفال
  // =============================================
  Widget _buildSummary(bool isDark) {
    final uniqueChildren = _filteredDebts.map((e) => e['Child_Id']).toSet().length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // عدد الأطفال
              Expanded(
                child: _summaryCard(
                  title: 'عدد الأطفال',
                  value: uniqueChildren.toString(),
                  isCurrency: false,
                  icon: Icons.child_care_rounded,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  title: 'الإجمالي',
                  value: _currencyFormat.format(_totalRequired),
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  title: 'المدفوع',
                  value: _currencyFormat.format(_totalPaid),
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  title: 'المتبقي',
                  value: _currencyFormat.format(_totalRemaining),
                  icon: Icons.warning_rounded,
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isCurrency = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // =============================================
  // Table Header
  // =============================================
  Widget _buildTableHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _headerCell('الاسم', flex: 5),
_headerCell('النوع', flex: 2),
_headerCell('الإجمالي', flex: 3),
_headerCell('المدفوع', flex: 3),
_headerCell('المتبقي', flex: 3),
_headerCell('%', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // =============================================
  // Table Row
  // =============================================
  Widget _buildTableRow(dynamic item, bool isDark, int index) {
    final reqAmount = _d(item['amount_Sub']);
    final paidAmount = _d(item['totalPaid']);
    final remaining = (reqAmount - paidAmount).clamp(0.0, reqAmount);
    final progress = reqAmount > 0 ? ((paidAmount / reqAmount) * 100).clamp(0.0, 100.0) : 0.0;

    final kind = (item['Kind_subscrip'] ?? '').toString();
    final isStudy = kind == 'اشتراك الدراسة السنوى';
    final kindColor = isStudy ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    Color progressColor;
    if (progress >= 100) {
      progressColor = const Color(0xFF10B981);
    } else if (progress >= 50) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = const Color(0xFFEF4444);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildDebtDetailsScreen(
                childId: item['Child_Id'],
                childName: item['FullNameArabic'] ?? '',
                sessionId: _selectedSessionId!,
                sessionName: _selectedSessionName ?? '',
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              right: BorderSide(color: kindColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // الاسم
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['FullNameArabic'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['branchName'] != null)
                      Text(
                        item['branchName'],
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // النوع
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: kindColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isStudy ? 'دراسة' : 'باص',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kindColor),
                    ),
                  ),
                ),
              ),

              // الإجمالي
              Expanded(
                flex: 3,
                child: Text(
                  _currencyFormat.format(reqAmount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // المدفوع
              Expanded(
                flex: 3,
                child: Text(
                  _currencyFormat.format(paidAmount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // المتبقي
              Expanded(
                flex: 3,
                child: Text(
                  _currencyFormat.format(remaining),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // النسبة
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // =============================================
// تصدير Excel
// =============================================
Future<void> _exportToExcel() async {
  setState(() => _isExporting = true);

  try {
    final excel = Excel.createExcel();
    final sheet = excel['أرصدة الأطفال'];

    sheet.appendRow([
      TextCellValue('اسم الطفل'),
      TextCellValue('الفرع'),
      TextCellValue('نوع الاشتراك'),
      TextCellValue('الإجمالي'),
      TextCellValue('المدفوع'),
      TextCellValue('المتبقي'),
      TextCellValue('النسبة'),
    ]);

    for (final item in _filteredDebts) {
      final req = _d(item['amount_Sub']);
      final paid = _d(item['totalPaid']);
      final rem = (req - paid).clamp(0.0, req);
      final pct = req > 0 ? ((paid / req) * 100) : 0.0;

      sheet.appendRow([
        TextCellValue(item['FullNameArabic'] ?? ''),
        TextCellValue(item['branchName'] ?? ''),
        TextCellValue(item['Kind_subscrip'] ?? ''),
        DoubleCellValue(req),
        DoubleCellValue(paid),
        DoubleCellValue(rem),
        TextCellValue('${pct.toStringAsFixed(1)}%'),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('الإجمالي'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(_totalRequired),
      DoubleCellValue(_totalPaid),
      DoubleCellValue(_totalRemaining),
      TextCellValue(''),
    ]);

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل إنشاء الملف');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/أرصدة_الأطفال_${_selectedSessionName ?? ''}.xlsx');
    await file.writeAsBytes(Uint8List.fromList(bytes));

    await Share.shareXFiles([XFile(file.path)], text: 'أرصدة الأطفال');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التصدير: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isExporting = false);
  }
}

// =============================================
// تصدير PDF
// =============================================
Future<void> _exportToPDF() async {
  setState(() => _isExporting = true);

  try {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    final tableData = _filteredDebts.map((item) {
      final req = _d(item['amount_Sub']);
      final paid = _d(item['totalPaid']);
      final rem = (req - paid).clamp(0.0, req);
      final pct = req > 0 ? ((paid / req) * 100) : 0.0;

      return [
        item['FullNameArabic'] ?? '',
        item['branchName'] ?? '',
        (item['Kind_subscrip'] ?? '').toString().contains('دراسة') ? 'دراسة' : 'باص',
        _currencyFormat.format(req),
        _currencyFormat.format(paid),
        _currencyFormat.format(rem),
        '${pct.toStringAsFixed(1)}%',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'أرصدة الأطفال - ${_selectedSessionName ?? ''}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'عدد الأطفال: ${_filteredDebts.map((e) => e['Child_Id']).toSet().length} | الإجمالي: ${_currencyFormat.format(_totalRequired)} | المدفوع: ${_currencyFormat.format(_totalPaid)} | المتبقي: ${_currencyFormat.format(_totalRemaining)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 14),
                pw.Table.fromTextArray(
                  headers: ['الاسم', 'الفرع', 'النوع', 'الإجمالي', 'المدفوع', 'المتبقي', '%'],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerRight,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/أرصدة_الأطفال_${_selectedSessionName ?? ''}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'أرصدة الأطفال');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التصدير: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isExporting = false);
  }
}

  // =============================================
  // حالة فارغة
  // =============================================
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات',
            style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر العام المالي والفرع ونوع الاشتراك',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}