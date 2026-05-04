import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/kpi_service.dart';

class KpiHeader extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final String selectedPeriod;
  final int? selectedBranch;
  final int? selectedKind;
  final String compareWith;
  final Function({
    DateTime? from,
    DateTime? to,
    int? branch,
    int? kind,
    String? compare,
    String? period,
  }) onFilterChanged;

  const KpiHeader({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.selectedPeriod,
    this.selectedBranch,
    this.selectedKind,
    required this.compareWith,
    required this.onFilterChanged,
  });

  @override
  State<KpiHeader> createState() => _KpiHeaderState();
}

class _KpiHeaderState extends State<KpiHeader> {
  List<FilterItem> _branches = [];
  List<FilterItem> _kinds = [];
  bool _isLoadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final filters = await KpiService.getFilters();
      setState(() {
        _branches = filters.branches;
        _kinds = filters.kinds;
        _isLoadingFilters = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      setState(() => _isLoadingFilters = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDark),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─────────────────────────────────────────────────
          // العنوان والأزرار
          // ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر الرجوع
              _buildIconButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: () => Navigator.pop(context),
                isDark: isDark,
              ),

              // العنوان
              Text(
                'مؤشرات أداء الإيرادات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(isDark),
                ),
              ),

              // زر تبديل الثيم فقط
              _buildIconButton(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                onPressed: () => themeProvider.toggleTheme(),
                isDark: isDark,
                isHighlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─────────────────────────────────────────────────
          // تبويبات الفترة
          // ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab('اليوم', 'today', Icons.today, isDark),
                _buildTab('الأسبوع', 'week', Icons.view_week, isDark),
                _buildTab('الشهر', 'month', Icons.calendar_month, isDark),
                _buildTab('السنة', 'year', Icons.calendar_today, isDark),
                _buildTab('مخصص', 'custom', Icons.date_range, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─────────────────────────────────────────────────
          // فلاتر الفروع والمقارنة
          // ─────────────────────────────────────────────────
          if (_isLoadingFilters)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(child: _buildBranchDropdown(isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildCompareDropdown(isDark)),
              ],
            ),

          // ─────────────────────────────────────────────────
          // فلتر الأنواع
          // ─────────────────────────────────────────────────
          if (!_isLoadingFilters && _kinds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildKindDropdown(isDark),
          ],

          // ─────────────────────────────────────────────────
          // اختيار التاريخ المخصص
          // ─────────────────────────────────────────────────
          if (widget.selectedPeriod == 'custom') ...[
            const SizedBox(height: 12),
            _buildDateRangePicker(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.getBorder(isDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isHighlighted ? AppColors.primary : AppColors.getText(isDark),
          size: 22,
        ),
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }

  Widget _buildTab(String title, String id, IconData icon, bool isDark) {
    final isSelected = widget.selectedPeriod == id;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () {
          final now = DateTime.now();
          DateTime from = now;
          DateTime to = now;

          switch (id) {
            case 'today':
              from = DateTime(now.year, now.month, now.day);
              to = DateTime(now.year, now.month, now.day, 23, 59, 59);
              break;
            case 'week':
              from = now.subtract(Duration(days: now.weekday - 1));
              to = now;
              break;
            case 'month':
              from = DateTime(now.year, now.month, 1);
              to = DateTime(now.year, now.month + 1, 0); // آخر يوم في الشهر
              break;
            case 'year':
              from = DateTime(now.year, 1, 1);
              to = DateTime(now.year, 12, 31, 23, 59, 59);
              break;
          }

          widget.onFilterChanged(period: id, from: from, to: to);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.getBorder(isDark).withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.getText(isDark),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getBorder(isDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: widget.selectedBranch,
          hint: Row(
            children: [
              Icon(
                Icons.business,
                size: 16,
                color: AppColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'كل الفروع',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.getTextSecondary(isDark),
          ),
          dropdownColor: AppColors.getCard(isDark),
          borderRadius: BorderRadius.circular(14),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text(
                'كل الفروع',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getText(isDark),
                ),
              ),
            ),
            ..._branches.map((branch) {
              return DropdownMenuItem<int>(
                value: branch.id,
                child: Text(
                  branch.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getText(isDark),
                  ),
                ),
              );
            }),
          ],
          onChanged: (val) => widget.onFilterChanged(branch: val ?? -1),
        ),
      ),
    );
  }

  Widget _buildKindDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getBorder(isDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: widget.selectedKind,
          hint: Row(
            children: [
              Icon(
                Icons.category,
                size: 16,
                color: AppColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'كل الأنواع',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.getTextSecondary(isDark),
          ),
          dropdownColor: AppColors.getCard(isDark),
          borderRadius: BorderRadius.circular(14),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text(
                'كل الأنواع',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getText(isDark),
                ),
              ),
            ),
            ..._kinds.map((kind) {
              return DropdownMenuItem<int>(
                value: kind.id,
                child: Text(
                  kind.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getText(isDark),
                  ),
                ),
              );
            }),
          ],
          onChanged: (val) => widget.onFilterChanged(kind: val ?? -1),
        ),
      ),
    );
  }

  Widget _buildCompareDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getBorder(isDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.compareWith,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.getTextSecondary(isDark),
          ),
          dropdownColor: AppColors.getCard(isDark),
          borderRadius: BorderRadius.circular(14),
          items: [
            DropdownMenuItem(
              value: 'previousPeriod',
              child: Row(
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 16,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الفترة السابقة',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'lastYear',
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'السنة الماضية',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              widget.onFilterChanged(compare: val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: DateTimeRange(
            start: widget.fromDate,
            end: widget.toDate,
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.getCard(isDark),
                  onSurface: AppColors.getText(isDark),
                ), dialogTheme: DialogThemeData(backgroundColor: AppColors.getCard(isDark)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          widget.onFilterChanged(from: picked.start, to: picked.end);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              '${DateFormat('yyyy/MM/dd').format(widget.fromDate)} - ${DateFormat('yyyy/MM/dd').format(widget.toDate)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}