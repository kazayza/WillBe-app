import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/crm_kpi_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📅 Date Filter Bar Widget
// ═══════════════════════════════════════════════════════════════════════════

class DateFilterBar extends StatelessWidget {
  final CRMKPIProvider provider;
  final bool isDark;
  final VoidCallback onDateRangeTap;
  final VoidCallback onBranchTap;

  const DateFilterBar({
    super.key,
    required this.provider,
    required this.isDark,
    required this.onDateRangeTap,
    required this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Range Button
          Expanded(
            child: _FilterButton(
              icon: Icons.calendar_today_rounded,
              label: _formatDateRange(),
              isActive: !provider.isDefaultDateRange,
              isDark: isDark,
              onTap: onDateRangeTap,
            ),
          ),

          const SizedBox(width: 10),

          // Branch Button
          Expanded(
            child: _FilterButton(
              icon: Icons.business_rounded,
              label: provider.selectedBranchName,
              isActive: provider.selectedBranchId != null,
              isDark: isDark,
              onTap: onBranchTap,
            ),
          ),

          // Clear Filters Button
          if (provider.selectedBranchId != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: provider.clearFilters,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red[400],
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (provider.dateFrom == null || provider.dateTo == null) {
      return 'Select Date';
    }

    final formatter = DateFormat('dd MMM');
    final from = formatter.format(provider.dateFrom!);
    final to = formatter.format(provider.dateTo!);

    return '$from - $to';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔘 Filter Button Widget
// ═══════════════════════════════════════════════════════════════════════════

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.indigoAccent.withOpacity(0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.indigoAccent.withOpacity(0.5))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.indigoAccent
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.indigoAccent
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ⚡ Quick Date Presets Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class QuickDatePresetsSheet extends StatelessWidget {
  final CRMKPIProvider provider;
  final bool isDark;

  const QuickDatePresetsSheet({
    super.key,
    required this.provider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('Today', Icons.today_rounded, provider.setToday),
      ('This Week', Icons.view_week_rounded, provider.setThisWeek),
      ('This Month', Icons.calendar_month_rounded, provider.setThisMonth),
      ('Last 30 Days', Icons.date_range_rounded, provider.setLast30Days),
      ('Last 90 Days', Icons.calendar_today_rounded, provider.setLast90Days),
      ('This Year', Icons.event_note_rounded, provider.setThisYear),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            '📅 Quick Select',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 16),

          // Presets Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: presets.map((preset) {
              return _PresetButton(
                label: preset.$1,
                icon: preset.$2,
                isDark: isDark,
                onTap: () {
                  preset.$3();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom Range Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: provider.dateFrom != null && provider.dateTo != null
                      ? DateTimeRange(start: provider.dateFrom!, end: provider.dateTo!)
                      : null,
                );
                if (picked != null) {
                  provider.setDateRange(picked.start, picked.end);
                }
              },
              icon: const Icon(Icons.edit_calendar_rounded),
              label: const Text('Custom Range'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigoAccent,
                side: const BorderSide(color: Colors.indigoAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.indigoAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}