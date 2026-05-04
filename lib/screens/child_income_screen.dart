import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/report_income_kind_provider.dart';
import '../providers/theme_provider.dart';
import '../models/income_models.dart';

class ChildIncomeScreen extends StatefulWidget {
  const ChildIncomeScreen({Key? key}) : super(key: key);

  @override
  State<ChildIncomeScreen> createState() => _ChildIncomeScreenState();
}

class _ChildIncomeScreenState extends State<ChildIncomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DateTimeRange? _selectedDateRange;
  bool _showSearchResults = false;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar_EG');
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // =============================================
  // البحث
  // =============================================
  void _onSearchChanged(String value, ReportIncomeKindProvider provider) {
    if (value.trim().length >= 2) {
      setState(() => _showSearchResults = true);
      provider.searchChildren(value.trim());
    } else {
      setState(() => _showSearchResults = false);
    }
  }

  void _selectChild(ReportIncomeKindProvider provider, ChildModel child) {
    provider.selectChild(child);
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _selectedDateRange = null;
    });
    _searchFocusNode.unfocus();
    provider.clearError();
    provider.loadChildIncomes(childId: child.id);
  }

  void _clearChild(ReportIncomeKindProvider provider) {
    _searchController.clear();
    provider.selectChild(null);
    setState(() {
      _showSearchResults = false;
      _selectedDateRange = null;
    });
  }

  // =============================================
  // فلتر التاريخ
  // =============================================
  Future<void> _pickDateRange(ReportIncomeKindProvider provider) async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: _selectedDateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
        locale: const Locale('ar', 'EG'),
      );

      if (picked != null) {
        setState(() => _selectedDateRange = picked);
        _applyFilter(provider);
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار التاريخ: $e');
    }
  }

  void _clearDateRange(ReportIncomeKindProvider provider) {
    setState(() => _selectedDateRange = null);
    _applyFilter(provider);
  }

  void _applyFilter(ReportIncomeKindProvider provider) {
    if (provider.selectedChild == null) return;
    provider.clearError();
    provider.loadChildIncomes(
      childId: provider.selectedChild!.id,
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
    );
  }

  // =============================================
  // Build
  // =============================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: Consumer<ReportIncomeKindProvider>(
        builder: (context, provider, _) {
          return GestureDetector(
            onTap: () {
              _searchFocusNode.unfocus();
              setState(() => _showSearchResults = false);
            },
            child: Column(
              children: [
                // البحث
                _buildSearchBar(provider, isDark),

                // الطفل المختار + فلتر التاريخ
                if (provider.selectedChild != null)
                  _buildSelectedChildSection(provider, isDark),

                // المحتوى
                Expanded(child: _buildContent(provider, isDark)),
              ],
            ),
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
        'إيرادات الطفل',
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
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<ReportIncomeKindProvider>(
          builder: (context, provider, _) {
            if (provider.selectedChild == null) return const SizedBox();
            return PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded,
                    color: Colors.white, size: 18),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (value) async {
                if (value == 'excel') {
                  await provider.exportChildIncomesToExcel();
                } else if (value == 'pdf') {
                  await provider.exportChildIncomesToPDF();
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
              itemBuilder: (_) => [
                _buildPopupItem('excel', Icons.table_chart_rounded,
                    'تصدير Excel', const Color(0xFF10B981)),
                _buildPopupItem('pdf', Icons.picture_as_pdf_rounded,
                    'تصدير PDF', const Color(0xFFEF4444)),
              ],
            );
          },
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
  // شريط البحث
  // =============================================
  Widget _buildSearchBar(ReportIncomeKindProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          // حقل البحث
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (val) => _onSearchChanged(val, provider),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الطفل أو الرقم القومي...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF6366F1), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: Colors.grey.shade500),
                        onPressed: () => _clearChild(provider),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // نتائج البحث
          if (_showSearchResults) _buildSearchResults(provider, isDark),
        ],
      ),
    );
  }

  // =============================================
  // نتائج البحث
  // =============================================
  Widget _buildSearchResults(
      ReportIncomeKindProvider provider, bool isDark) {
    if (provider.childrenList.isEmpty &&
        _searchController.text.length >= 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      );
    }

    if (provider.childrenList.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: provider.childrenList.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        itemBuilder: (context, index) {
          final child = provider.childrenList[index];
          return ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded,
                  size: 18, color: Color(0xFF6366F1)),
            ),
            title: Text(
              child.fullName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                if (child.className != null)
                  Text(
                    child.className!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                if (child.className != null && child.branchName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('•',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400)),
                  ),
                if (child.branchName != null)
                  Text(
                    child.branchName!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF6366F1)),
            onTap: () => _selectChild(provider, child),
          );
        },
      ),
    );
  }

  // =============================================
  // الطفل المختار + فلتر التاريخ
  // =============================================
  Widget _buildSelectedChildSection(
      ReportIncomeKindProvider provider, bool isDark) {
    final child = provider.selectedChild!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // بطاقة الطفل
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (child.className != null) ...[
                            Icon(Icons.class_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              child.className!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12),
                            ),
                          ],
                          if (child.className != null &&
                              child.branchName != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('•',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 10)),
                            ),
                          if (child.branchName != null)
                            Text(
                              child.branchName!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // زر تغيير الطفل
                GestureDetector(
                  onTap: () => _clearChild(provider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // فلتر التاريخ
          GestureDetector(
            onTap: () => _pickDateRange(provider),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDateRange != null
                      ? const Color(0xFF6366F1).withOpacity(0.3)
                      : (isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _selectedDateRange != null
                        ? const Color(0xFF6366F1)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}'
                          : 'كل الفترات',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedDateRange != null
                            ? const Color(0xFF6366F1)
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        fontWeight: _selectedDateRange != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    GestureDetector(
                      onTap: () => _clearDateRange(provider),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF6366F1)),
                    )
                  else
                    Icon(Icons.expand_more_rounded,
                        size: 18, color: Colors.grey.shade500),
                ],
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
  Widget _buildContent(ReportIncomeKindProvider provider, bool isDark) {
    // لم يتم اختيار طفل
    if (provider.selectedChild == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded,
                size: 60,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ابحث عن طفل واختره لعرض إيراداته',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // تحميل
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    // خطأ
    if (provider.errorMessage != null) {
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
                  color: isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _applyFilter(provider),
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

    // فارغ
    if (provider.childIncomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 60,
                color:
                    isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد إيرادات في هذه الفترة',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // عرض البيانات
    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: () async => _applyFilter(provider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          // الملخص
          if (provider.childSummary != null)
            _buildSummaryRow(provider.childSummary!, isDark),

          const SizedBox(height: 12),

          // عدد النتائج
          _buildResultsHeader(provider.childIncomes.length, isDark),

          const SizedBox(height: 8),

          // القائمة
          ...provider.childIncomes
              .map((item) => _buildIncomeCard(item, isDark))
              .toList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =============================================
  // الملخص
  // =============================================
  Widget _buildSummaryRow(ChildIncomeSummary summary, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            icon: Icons.attach_money_rounded,
            label: 'الإجمالي',
            value: '${_currencyFormat.format(summary.totalAmount)}',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniCard(
            icon: Icons.receipt_rounded,
            label: 'المعاملات',
            value: '${summary.totalTransactions}',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
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

  // =============================================
  // عنوان النتائج
  // =============================================
  Widget _buildResultsHeader(int count, bool isDark) {
    return Row(
      children: [
        Icon(Icons.list_rounded,
            size: 18,
            color:
                isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          'المعاملات ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // =============================================
  // كارت الإيراد
  // =============================================
  Widget _buildIncomeCard(ChildIncomeModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // أيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(item.incomeDate),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (item.receiptNumber != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.tag_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.receiptNumber!,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.notes != null &&
                    item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // المبلغ
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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