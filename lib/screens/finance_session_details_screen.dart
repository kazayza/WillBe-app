import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/finance_theme.dart';
import '../models/finance_session_details_model.dart';
import '../services/finance_session_details_service.dart';
import '../widgets/child_finance/finance_summary_section.dart';
import '../widgets/child_finance/finance_record_tile.dart';
import 'child_details_screen.dart';
import 'child_finance_screen.dart';

class FinanceSessionDetailsScreen extends StatefulWidget {
  final int sessionId;
  final String sessionName;
  const FinanceSessionDetailsScreen({super.key, required this.sessionId, required this.sessionName});

  @override
  State<FinanceSessionDetailsScreen> createState() => _FinanceSessionDetailsScreenState();
}

class _FinanceSessionDetailsScreenState extends State<FinanceSessionDetailsScreen> {
  bool _isLoadingDashboard = true;
  bool _isLoadingRecords = true;
  String? _error;
  FinanceSessionDashboardModel? _dashboard;
  FinanceSessionRecordsResponse? _recordsResponse;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _selectedBranchId = 'all';
  String _selectedStatus = 'active';
  String _selectedKind = 'all';
  String _viewMode = 'list';
  String _sortBy = 'subDate';
  String _sortOrder = 'desc';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => _loadRecords());
  }

  Future<void> _loadAll() async {
    setState(() { _isLoadingDashboard = true; _isLoadingRecords = true; _error = null; });
    await Future.wait([_loadDashboard(), _loadRecords()]);
  }

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await FinanceSessionDetailsService.getSessionDashboard(widget.sessionId);
      if (mounted) setState(() { _dashboard = dashboard; _isLoadingDashboard = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoadingDashboard = false; });
    }
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoadingRecords = true);
    try {
      final data = await FinanceSessionDetailsService.getSessionRecords(
        sessionId: widget.sessionId, branchId: _selectedBranchId, status: _selectedStatus,
        kind: _selectedKind, viewMode: _viewMode, sortBy: _sortBy, sortOrder: _sortOrder, search: _searchController.text.trim(),
      );
      if (mounted) setState(() { _recordsResponse = data; _isLoadingRecords = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoadingRecords = false; });
    }
  }

  Future<void> _refresh() async => await _loadAll();

  int get _activeFiltersCount => [if (_selectedBranchId != 'all') 1, if (_selectedStatus != 'active') 1, if (_selectedKind != 'all') 1].length;

  void _showSortSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: FinanceTheme.card(context), borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: FinanceTheme.textSec(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('خيارات العرض والترتيب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: FinanceTheme.text(context))),
              const SizedBox(height: 24),
              _buildSortGroup(title: 'العرض', options: [SortOption(label: 'قائمة', value: 'list', icon: Icons.view_list_rounded), SortOption(label: 'شهري', value: 'month', icon: Icons.calendar_view_month_rounded)], selectedValue: _viewMode, onChanged: (val) { setState(() => _viewMode = val); Navigator.pop(context); _loadRecords(); }),
              const SizedBox(height: 16),
              _buildSortGroup(title: 'الترتيب حسب', options: [SortOption(label: 'التاريخ', value: 'subDate', icon: Icons.date_range_rounded), SortOption(label: 'الاسم', value: 'name', icon: Icons.sort_by_alpha_rounded), SortOption(label: 'المبلغ', value: 'amount', icon: Icons.payments_rounded)], selectedValue: _sortBy, onChanged: (val) { setState(() => _sortBy = val); Navigator.pop(context); _loadRecords(); }),
              const SizedBox(height: 16),
              _buildSortGroup(title: 'الاتجاه', options: [SortOption(label: 'تنازلي', value: 'desc', icon: Icons.arrow_downward_rounded), SortOption(label: 'تصاعدي', value: 'asc', icon: Icons.arrow_upward_rounded)], selectedValue: _sortOrder, onChanged: (val) { setState(() => _sortOrder = val); Navigator.pop(context); _loadRecords(); }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortGroup({required String title, required List<SortOption> options, required String selectedValue, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FinanceTheme.textSec(context))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selectedValue == opt.value;
            return GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? FinanceTheme.primary : FinanceTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? FinanceTheme.primary : FinanceTheme.border.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(opt.icon, size: 16, color: isSelected ? Colors.white : FinanceTheme.primary),
                  const SizedBox(width: 6),
                  Text(opt.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : FinanceTheme.text(context))),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceTheme.bg(context),
      appBar: AppBar(
        title: Text(widget.sessionName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3), overflow: TextOverflow.ellipsis),
        centerTitle: true, backgroundColor: FinanceTheme.primary, foregroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, size: 15, color: Colors.white)),
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, size: 21), tooltip: 'تحديث'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: FinanceTheme.accent,
        backgroundColor: FinanceTheme.card(context),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingDashboard && _isLoadingRecords) return _buildLoadingSkeleton();
    if (_error != null && _dashboard == null && _recordsResponse == null) return _buildErrorState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        if (_recordsResponse != null) FinanceSummarySection(summary: _recordsResponse!.summary),
        const SizedBox(height: 20),
        _buildSearchAndFiltersRow(),
        const SizedBox(height: 20),
        if (_showFilters && _dashboard != null) _buildFiltersCard(),
        if (_showFilters && _dashboard != null) const SizedBox(height: 16),
        if (_recordsResponse != null) _buildResultsHeader(),
        if (_recordsResponse != null) const SizedBox(height: 12),
        _buildRecordsArea(),
      ],
    );
  }

  Widget _buildSearchAndFiltersRow() {
    return Row(
      children: [
        Expanded(child: Container(
          height: 50,
          decoration: BoxDecoration(color: FinanceTheme.card(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: FinanceTheme.borderCtx(context).withValues(alpha: 0.5))),
          child: Row(children: [
            const SizedBox(width: 14), Icon(Icons.search_rounded, size: 20, color: FinanceTheme.textHint), const SizedBox(width: 10),
            Expanded(child: TextField(controller: _searchController, onChanged: _onSearchChanged, onSubmitted: (_) => _loadRecords(), style: TextStyle(fontSize: 14, color: FinanceTheme.text(context), fontWeight: FontWeight.w500), decoration: InputDecoration(hintText: 'ابحث باسم الطفل...', hintStyle: TextStyle(fontSize: 13.5, color: FinanceTheme.textHint), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 15)))),
            if (_searchController.text.trim().isNotEmpty)
              GestureDetector(onTap: () { _searchController.clear(); _loadRecords(); setState(() {}); }, child: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.close_rounded, size: 18, color: FinanceTheme.textSec(context)))),
          ]),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() => _showFilters = !_showFilters),
          child: Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: _activeFiltersCount > 0 ? FinanceTheme.accent : FinanceTheme.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _activeFiltersCount > 0 ? FinanceTheme.accent : FinanceTheme.borderCtx(context).withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.tune_rounded, size: 22, color: _activeFiltersCount > 0 ? Colors.white : FinanceTheme.primary),
                if (_activeFiltersCount > 0)
                  Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Text('$_activeFiltersCount', style: const TextStyle(color: FinanceTheme.accent, fontSize: 8, fontWeight: FontWeight.w900)))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showSortSheet,
          child: Container(
            height: 50, width: 50,
            decoration: BoxDecoration(color: FinanceTheme.card(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: FinanceTheme.borderCtx(context).withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Icon(Icons.sort_rounded, size: 22, color: FinanceTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: FinanceTheme.card(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: FinanceTheme.borderCtx(context).withValues(alpha: 0.4))),
      child: Column(
        children: [
          _buildFilterRow('الحالة', _dashboard!.statuses.map((e) => MapEntry(e.key, '${e.label} (${e.count})')).toList(), _selectedStatus, (v) { setState(() => _selectedStatus = v); _loadRecords(); }),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildFilterRow('الاشتراك', _dashboard!.subscriptionKinds.map((e) => MapEntry(e.key, '${e.label} (${e.count})')).toList(), _selectedKind, (v) { setState(() => _selectedKind = v); _loadRecords(); }),
          if (_dashboard!.branches.length > 1) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildFilterRow('الفروع', _dashboard!.branches.map((e) => MapEntry(e.branchId.toString(), '${e.branchName} (${e.count})')).toList(), _selectedBranchId, (v) { setState(() => _selectedBranchId = v); _loadRecords(); }),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow(String title, List<MapEntry<String, String>> items, String selected, Function(String) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FinanceTheme.textSec(context), letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) {
            final sel = selected == item.key;
            return GestureDetector(
              onTap: () => onChange(item.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? FinanceTheme.primary : FinanceTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? FinanceTheme.primary : FinanceTheme.border.withValues(alpha: 0.3)),
                ),
                child: Text(item.value, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? Colors.white : FinanceTheme.text(context))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    final s = _recordsResponse!.summary;
    return Row(
      children: [
        Icon(Icons.list_alt_rounded, size: 20, color: FinanceTheme.textSec(context)),
        const SizedBox(width: 8),
        RichText(text: TextSpan(style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: FinanceTheme.text(context)), children: [
          TextSpan(text: '${s.recordsCount} '),
          TextSpan(text: 'سجل', style: TextStyle(fontWeight: FontWeight.w400, color: FinanceTheme.textSec(context))),
          const TextSpan(text: '  ·  '),
          TextSpan(text: '${s.uniqueChildrenCount} '),
          TextSpan(text: 'طفل', style: TextStyle(fontWeight: FontWeight.w400, color: FinanceTheme.textSec(context))),
        ])),
      ],
    );
  }

  Widget _buildRecordsArea() {
    if (_isLoadingRecords) {
      return Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: FinanceTheme.accent)),
              const SizedBox(height: 14),
              Text('جارٍ التحميل...', style: TextStyle(fontSize: 13, color: FinanceTheme.textSec(context))),
            ],
          ),
        ),
      );
    }

    if (_recordsResponse == null) return const SizedBox.shrink();

    final groups = _recordsResponse!.groups ?? [];
    final records = _recordsResponse!.records ?? [];

    if (_viewMode == 'month' && _searchController.text.trim().isEmpty && groups.isNotEmpty) {
      return Column(children: groups.map<Widget>((g) => _buildMonthGroup(g)).toList());
    }
    
    if (records.isEmpty) return _emptyState();

    return Column(
      children: records.map((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FinanceRecordTile(
            record: record,
            onTap: () => _showChildDetailsSheet(record),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGroup(dynamic group) {
    final recs = group.records ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FinanceTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: FinanceTheme.primary, width: 3.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 18, color: FinanceTheme.primary),
                const SizedBox(width: 8),
                Text(group.monthLabel, style: TextStyle(fontWeight: FontWeight.w700, color: FinanceTheme.primary, fontSize: 14.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: FinanceTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('${group.count} سجل', style: TextStyle(color: FinanceTheme.primary, fontWeight: FontWeight.w700, fontSize: 11.5)),
                ),
              ],
            ),
          ),
          ...recs.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FinanceRecordTile(
              record: r,
              onTap: () => _showChildDetailsSheet(r),
            ),
          )),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final hasSearch = _searchController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(hasSearch ? Icons.search_off_rounded : Icons.inbox_rounded, size: 52, color: FinanceTheme.textHint),
          const SizedBox(height: 16),
          Text(hasSearch ? 'لا توجد نتائج' : 'لا توجد سجلات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: FinanceTheme.text(context))),
          const SizedBox(height: 4),
          Text(hasSearch ? 'جرّب كلمة بحث مختلفة' : 'غيّر الفلاتر للحصول على نتائج', style: TextStyle(fontSize: 13, color: FinanceTheme.textSec(context))),
        ],
      ),
    );
  }

  void _showChildDetailsSheet(FinanceRecordModel record) {
    String _formatNumber(double value) {
      if (value == value.truncateToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(2);
    }
    String _formatDate(DateTime? date) {
      if (date == null) return '—';
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    bool isBus = record.subscriptionKind.contains('الباص');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 24, left: 20, right: 20),
          decoration: BoxDecoration(
            color: FinanceTheme.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FinanceTheme.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isBus ? FinanceTheme.accent.withValues(alpha: 0.1) : FinanceTheme.success.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.child_care_rounded,
                      size: 28,
                      color: isBus ? FinanceTheme.accent : FinanceTheme.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.childName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: FinanceTheme.text(context),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isBus ? FinanceTheme.accent.withValues(alpha: 0.1) : FinanceTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.subscriptionKind,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isBus ? FinanceTheme.accent : FinanceTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatNumber(record.amountSub),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: FinanceTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: FinanceTheme.divider),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSheetDetail(Icons.store_rounded, 'الفرع', record.branchName, FinanceTheme.info),
                  const SizedBox(width: 12),
                  _buildSheetDetail(Icons.calendar_today_rounded, 'تاريخ الالتحاق', _formatDate(record.subDate), FinanceTheme.accent),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FinanceTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                                        _buildSheetAction(Icons.person_outline_rounded, 'ملف الطفل', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              ChildDetailsScreen(
                                childId: record.childId,
                                childName: record.childName,
                              ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                                  .chain(CurveTween(curve: Curves.easeOutCubic))
                                  .animate(animation),
                              child: child,
                            );
                          },
                        ),
                      );
                    }),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1)),
                    _buildSheetAction(Icons.edit_note_rounded, 'تعديل الاشتراك', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              ChildFinanceScreen(
                                childId: record.childId,
                                childName: record.childName,
                              ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                                  .chain(CurveTween(curve: Curves.easeOutCubic))
                                  .animate(animation),
                              child: child,
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetDetail(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: TextStyle(fontSize: 11, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FinanceTheme.text(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetAction(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 20, color: FinanceTheme.primary),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FinanceTheme.text(context),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_back_ios_new, size: 16, color: FinanceTheme.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [Expanded(child: Container(height: 100, decoration: BoxDecoration(color: FinanceTheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)))), const SizedBox(width: 12), Expanded(child: Container(height: 100, decoration: BoxDecoration(color: FinanceTheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16))))]),
        const SizedBox(height: 20),
        Container(height: 50, decoration: BoxDecoration(color: FinanceTheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(14))),
        const SizedBox(height: 20),
        ...List.generate(4, (_) => Container(height: 90, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: FinanceTheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16))))
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: FinanceTheme.error.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.cloud_off_rounded, size: 40, color: FinanceTheme.error)),
            const SizedBox(height: 18),
            Text('حدث خطأ أثناء التحميل', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: FinanceTheme.text(context))),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: FinanceTheme.textSec(context), height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('إعادة المحاولة'), style: ElevatedButton.styleFrom(backgroundColor: FinanceTheme.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))
          ],
        ),
      ),
    );
  }
}

class SortOption { final String label; final String value; final IconData icon; SortOption({required this.label, required this.value, required this.icon}); }