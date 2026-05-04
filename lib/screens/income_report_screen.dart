import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/report_income_kind_provider.dart';
import '../providers/theme_provider.dart';
import '../models/income_models.dart';

class IncomeReportScreen extends StatefulWidget {
  const IncomeReportScreen({Key? key}) : super(key: key);

  @override
  State<IncomeReportScreen> createState() => _IncomeReportScreenState();
}

class _IncomeReportScreenState extends State<IncomeReportScreen> {
  String? _selectedGroup;
  int? _selectedKindId;
  int? _selectedBranchId;
  DateTime? _fromDate;
  DateTime? _toDate;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar_EG');
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final provider =
        Provider.of<ReportIncomeKindProvider>(context, listen: false);
    await provider.loadBranches();
    await provider.loadIncomeGroups();
    await provider.loadIncomesReport();
  }

  void _autoFilter() {
    final provider =
        Provider.of<ReportIncomeKindProvider>(context, listen: false);
    provider.updateFilters(
      fromDate: _fromDate,
      toDate: _toDate,
      branchId: _selectedBranchId,
      group: _selectedGroup,
      kindId: _selectedKindId,
    );
    provider.loadIncomesReport();
  }

  Future<void> _selectDateRange() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: (_fromDate != null && _toDate != null)
            ? DateTimeRange(start: _fromDate!, end: _toDate!)
            : DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
      );

      if (picked != null) {
        setState(() {
          _fromDate = picked.start;
          _toDate = picked.end;
        });
        _autoFilter();
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار التاريخ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: Consumer<ReportIncomeKindProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // الفلاتر
              _buildFiltersBar(provider, isDark, screenWidth),

              // المحتوى
              Expanded(
                child: _buildContent(provider, isDark, screenWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  // =============================================
  // AppBar
  // =============================================
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      title: const Text(
        'تقرير الإيرادات',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // تحديث
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _autoFilter,
        ),
        // تصدير
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) async {
            final provider =
                Provider.of<ReportIncomeKindProvider>(context, listen: false);
            if (value == 'excel') {
              await provider.exportIncomesToExcel();
            } else if (value == 'pdf') {
              await provider.exportIncomesToPDF();
            }
            if (provider.errorMessage != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            _buildPopupItem(
                'excel', Icons.table_chart_rounded, 'تصدير Excel', const Color(0xFF10B981)),
            _buildPopupItem(
                'pdf', Icons.picture_as_pdf_rounded, 'تصدير PDF', const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // =============================================
  // شريط الفلاتر المدمج
  // =============================================
  Widget _buildFiltersBar(
      ReportIncomeKindProvider provider, bool isDark, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الصف الأول: التاريخ + الفرع
          Row(
            children: [
              // التاريخ
              Expanded(
                flex: 3,
                child: _buildFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: (_fromDate != null && _toDate != null)
                      ? '${_dateFormat.format(_fromDate!)} - ${_dateFormat.format(_toDate!)}'
                      : 'الفترة الزمنية',
                  isActive: _fromDate != null,
                  isDark: isDark,
                  onTap: _selectDateRange,
                  onClear: _fromDate != null
                      ? () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                          _autoFilter();
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // الفرع
              Expanded(
                flex: 2,
                child: _buildDropdownFilter(
                  icon: Icons.store_rounded,
                  hint: 'الفرع',
                  isDark: isDark,
                  value: _selectedBranchId,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('كل الفروع', style: TextStyle(fontSize: 13)),
                    ),
                    ...provider.branches.map((b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedBranchId = val);
                    _autoFilter();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // الصف الثاني: المجموعة + النوع
          Row(
            children: [
              // المجموعة
              Expanded(
                child: _buildDropdownFilter(
                  icon: Icons.category_rounded,
                  hint: 'المجموعة',
                  isDark: isDark,
                  value: _selectedGroup,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('كل المجموعات', style: TextStyle(fontSize: 13)),
                    ),
                    ...provider.groups.map((g) => DropdownMenuItem<String>(
                          value: g,
                          child: Text(g,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (String? val) {
  setState(() {
    _selectedGroup = val;
    _selectedKindId = null;
  });
  provider.loadIncomeKindsByGroup(val);
  _autoFilter();
},
                ),
              ),
              const SizedBox(width: 8),
              // النوع
              Expanded(
                child: _buildDropdownFilter(
                  icon: Icons.label_rounded,
                  hint: 'النوع',
                  isDark: isDark,
                  value: _selectedKindId,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('كل الأنواع', style: TextStyle(fontSize: 13)),
                    ),
                    ...provider.kinds.map((k) => DropdownMenuItem<int>(
                          value: k.id,
                          child: Text(k.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: _selectedGroup == null
    ? null
    : (int? val) {
        setState(() => _selectedKindId = val);
        _autoFilter();
      },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================
  // عنصر فلتر (Chip)
  // =============================================
  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : (isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? const Color(0xFF6366F1) : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: Color(0xFF6366F1)),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // عنصر Dropdown Filter
  // =============================================
  Widget _buildDropdownFilter<T>({
    required IconData icon,
    required String hint,
    required bool isDark,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(hint,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.expand_more_rounded,
                    size: 18, color: Colors.grey.shade500),
                items: items,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // المحتوى الرئيسي
  // =============================================
  Widget _buildContent(
    ReportIncomeKindProvider provider, bool isDark, double screenWidth) {
  if (provider.isLoading && provider.incomeItems.isEmpty) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
    );
  }

  if (provider.errorMessage != null && provider.incomeItems.isEmpty) {
    return _buildErrorState(provider, isDark);
  }

  if (provider.incomeItems.isEmpty) {
    return _buildEmptyState(isDark);
  }

  return Column(
    children: [
      if (provider.summary != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildSummaryRow(provider.summary!, isDark, screenWidth),
        ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _buildResultsHeader(provider.incomeItems.length, isDark),
      ),

      const SizedBox(height: 8),

      Expanded(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async => _autoFilter(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: provider.incomeItems.length,
            itemBuilder: (context, index) {
              final item = provider.incomeItems[index];
              return _buildIncomeCard(item, isDark);
            },
          ),
        ),
      ),
    ],
  );
}

  // =============================================
  // حالة الخطأ
  // =============================================
  Widget _buildErrorState(ReportIncomeKindProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _autoFilter,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد إيرادات في هذه الفترة',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // صف الملخص (4 كروت صغيرة)
  // =============================================
  Widget _buildSummaryRow(
      ReportSummaryModel summary, bool isDark, double screenWidth) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniSummaryCard(
            icon: Icons.attach_money_rounded,
            label: 'الإجمالي',
            value: '${_currencyFormat.format(summary.totalAmount)}',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniSummaryCard(
            icon: Icons.receipt_rounded,
            label: 'المعاملات',
            value: '${summary.totalTransactions}',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniSummaryCard(
            icon: Icons.people_rounded,
            label: 'الأطفال',
            value: '${summary.totalChildren}',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniSummaryCard(
            icon: Icons.trending_up_rounded,
            label: 'المتوسط',
            value: '${_currencyFormat.format(summary.averageDaily)}',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // عنوان النتائج
  // =============================================
  Widget _buildResultsHeader(int count, bool isDark) {
    return Row(
      children: [
        Icon(Icons.list_rounded,
            size: 18,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          'النتائج ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // =============================================
  // قائمة الإيرادات (كروت بدل جدول)
  // =============================================
  Widget _buildIncomesList(List<IncomeItemModel> items, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildIncomeCard(item, isDark);
      },
    );
  }

  Widget _buildIncomeCard(IncomeItemModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // أيقونة النوع
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 12),

          // التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نوع الإيراد
                Text(
                  item.incomeKindName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // الطفل + الفرع
                Row(
                  children: [
                    if (item.childName != null) ...[
                      Icon(Icons.person_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.childName!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (item.childName != null && item.branchName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                      ),
                    if (item.branchName != null)
                      Text(
                        item.branchName!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // التاريخ + رقم الإيصال
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(item.incomeDate),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                    if (item.receiptNumber != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.tag_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        item.receiptNumber!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // المبلغ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_currencyFormat.format(item.amount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}