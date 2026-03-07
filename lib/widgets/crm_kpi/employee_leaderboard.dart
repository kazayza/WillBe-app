import 'package:flutter/material.dart';
import '../../models/crm_kpi_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🏆 Employee Leaderboard Widget
// ═══════════════════════════════════════════════════════════════════════════

class EmployeeLeaderboard extends StatelessWidget {
  final List<EmployeePerformance> employees;
  final bool isDark;
  final Function(EmployeePerformance)? onEmployeeTap;

  const EmployeeLeaderboard({
    super.key,
    required this.employees,
    required this.isDark,
    this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: 20),

          // Content
          employees.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: employees.length > 5 ? 5 : employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _EmployeeCard(
                      employee: employees[index],
                      rank: index + 1,
                      isDark: isDark,
                      onTap: () => onEmployeeTap?.call(employees[index]),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆 ', style: TextStyle(fontSize: 20)),
                Text(
                  "أفضل الموظفين",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "ترتيب الموظفين",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        if (employees.length > 5)
          TextButton(
            onPressed: () => _showAllEmployees(context),
            child: const Text(
              'عرض الكل',
              style: TextStyle(
                color: Colors.indigoAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر أداء الموظفين هنا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==================== SHOW ALL ====================
  void _showAllEmployees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('🏆 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'All Team Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _EmployeeCard(
                        employee: employees[index],
                        rank: index + 1,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          onEmployeeTap?.call(employees[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 👤 Employee Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _EmployeeCard extends StatelessWidget {
  final EmployeePerformance employee;
  final int rank;
  final bool isDark;
  final VoidCallback? onTap;

  const _EmployeeCard({
    required this.employee,
    required this.rank,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: rank <= 3
              ? Border.all(color: _getRankColor().withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Rank Badge
            _buildRankBadge(),

            const SizedBox(width: 12),

            // Avatar
            _buildAvatar(),

            const SizedBox(width: 12),

            // Name & Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMiniStat(Icons.people_alt_outlined, '${employee.totalLeads}'),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.check_circle_outline, '${employee.convertedLeads}'),
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.chat_bubble_outline, '${employee.totalInteractions}'),
                    ],
                  ),
                ],
              ),
            ),

            // Conversion Rate
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getConversionColor().withOpacity(0.2),
                    _getConversionColor().withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${employee.conversionRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _getConversionColor(),
                    ),
                  ),
                  Text(
                    'Rate',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _getRankColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: rank <= 3
          ? Text(_getRankEmoji(), style: const TextStyle(fontSize: 14))
          : Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _getRankColor(),
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.indigoAccent.withOpacity(0.1),
          child: Text(
            employee.initials,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.indigoAccent,
              fontSize: 14,
            ),
          ),
        ),
        if (rank == 1)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  String _getRankEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  Color _getConversionColor() {
    if (employee.conversionRate >= 50) return const Color(0xFF10B981);
    if (employee.conversionRate >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}