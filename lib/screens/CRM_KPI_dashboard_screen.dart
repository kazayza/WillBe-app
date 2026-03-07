import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/crm_kpi_provider.dart';
import '../models/crm_kpi_models.dart';
import '../widgets/crm_kpi/shimmer_loading.dart';
import '../widgets/crm_kpi/kpi_card.dart';
import '../widgets/crm_kpi/date_filter_bar.dart';
import '../widgets/crm_kpi/growth_chart.dart';
import '../widgets/crm_kpi/source_donut_chart.dart';
import '../widgets/crm_kpi/employee_leaderboard.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📊 CRM KPI Dashboard Screen
// ═══════════════════════════════════════════════════════════════════════════

class CRMKPIDashboardScreen extends StatefulWidget {
  const CRMKPIDashboardScreen({super.key});

  @override
  State<CRMKPIDashboardScreen> createState() => _CRMKPIDashboardScreenState();
}

class _CRMKPIDashboardScreenState extends State<CRMKPIDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CRMKPIProvider>().loadAllData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return ChangeNotifierProvider(
      create: (_) => CRMKPIProvider()..loadAllData(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        body: Consumer<CRMKPIProvider>(
          builder: (context, provider, child) {
            // Start animation when data is loaded
            if (provider.hasData && !_animationController.isCompleted) {
              _animationController.forward();
            }

            return RefreshIndicator(
              onRefresh: provider.refresh,
              color: Colors.indigoAccent,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // App Bar
                  _buildSliverAppBar(isDark, provider),

                  // Content
                  SliverToBoxAdapter(
                    child: _buildContent(isDark, provider),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(bool isDark, CRMKPIProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مؤشرات أداء إدارة العملاء',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'CRM KPI DASHBOARD',
              style: TextStyle(
                color: Colors.indigoAccent.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
          ),
        ),
      ),
      actions: [
        // Refresh Button
        IconButton(
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.indigoAccent,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.indigoAccent),
          onPressed: provider.isLoading ? null : provider.refresh,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 CONTENT BUILDER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent(bool isDark, CRMKPIProvider provider) {
    // Loading State
    if (provider.isLoading && !provider.hasData) {
      return CRMKPIShimmerLoading(isDark: isDark);
    }

    // Error State
    if (provider.hasError && !provider.hasData) {
      return _buildErrorState(isDark, provider);
    }

    // Empty State
    if (provider.isEmpty) {
      return _buildEmptyState(isDark, provider);
    }

    // Data State
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date & Branch Filter
            DateFilterBar(
              provider: provider,
              isDark: isDark,
              onDateRangeTap: () => _showDateRangePicker(context, provider, isDark),
              onBranchTap: () => _showBranchPicker(context, provider, isDark),
            ),

            const SizedBox(height: 20),

            // KPI Cards Grid
            _buildKPICards(isDark, provider),

            const SizedBox(height: 24),

            // Growth Chart
            GrowthChart(
              data: provider.periodStats,
              selectedPeriod: provider.selectedPeriod,
              onPeriodChanged: provider.setPeriod,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Source Distribution
            SourceDonutChart(
              sources: provider.sources,
              isDark: isDark,
              onSourceTap: (source) => _showSourceDetails(context, source, isDark),
            ),

            const SizedBox(height: 24),

            // Employee Leaderboard
            EmployeeLeaderboard(
              employees: provider.employees,
              isDark: isDark,
              onEmployeeTap: (emp) => _showEmployeeDetails(context, emp, isDark),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
// 📊 KPI CARDS
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildKPICards(bool isDark, CRMKPIProvider provider) {
  final leads = provider.dashboardData.leads;
  final followUps = provider.dashboardData.followUps;

  return Column(
    children: [
      // Row 1
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: KPICard(
                title: 'إجمالي العملاء المحتملين',
                value: leads.total,
                subtitle: '+${leads.newLeads} جديد',
                icon: Icons.people_rounded,
                color: Colors.indigoAccent,
                isDark: isDark,
                onTap: () => _navigateToLeads(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PercentageKPICard(
                title: 'معدل التحويل',
                value: leads.conversionRate,
                icon: Icons.auto_graph_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => _navigateToConversions(context),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 12),

      // Row 2
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: KPICard(
                title: 'متابعات اليوم',
                value: followUps.today,
                subtitle: 'مجدولة',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => _navigateToFollowUps(context, 'today'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KPICard(
                title: 'متابعات متأخرة',
                value: followUps.overdue,
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                isDark: isDark,
                showWarning: followUps.overdue > 0,
                onTap: () => _navigateToFollowUps(context, 'overdue'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  // ═══════════════════════════════════════════════════════════════════════════
  // ❌ ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(bool isDark, CRMKPIProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Unable to load dashboard data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📭 EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool isDark, CRMKPIProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.indigoAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding leads to see your\nCRM performance metrics here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigoAccent,
                    side: const BorderSide(color: Colors.indigoAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddLead(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Lead'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎛️ DIALOGS & PICKERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showDateRangePicker(
    BuildContext context,
    CRMKPIProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickDatePresetsSheet(
        provider: provider,
        isDark: isDark,
      ),
    );
  }

  void _showBranchPicker(
    BuildContext context,
    CRMKPIProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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

            Text(
              '🏢 Select Branch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 16),

            // All Branches Option
            _buildBranchOption(
              name: 'كل الفروع',
              icon: Icons.business_rounded,
              isSelected: provider.selectedBranchId == null,
              isDark: isDark,
              onTap: () {
                provider.setBranch(null);
                Navigator.pop(context);
              },
            ),

            const Divider(height: 24),

            // Branch List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.branches.length,
                itemBuilder: (context, index) {
                  final branch = provider.branches[index];
                  return _buildBranchOption(
                    name: branch.name,
                    icon: Icons.location_city_rounded,
                    isSelected: provider.selectedBranchId == branch.id,
                    isDark: isDark,
                    onTap: () {
                      provider.setBranch(branch.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchOption({
    required String name,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? Colors.indigoAccent : Colors.grey,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.indigoAccent
              : (isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Colors.indigoAccent)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: isSelected
          ? Colors.indigoAccent.withOpacity(0.1)
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📄 DETAIL SHEETS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSourceDetails(
    BuildContext context,
    SourcePerformance source,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Source Name
            Text(
              source.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                _buildStatItem('Total Leads', source.totalLeads.toString(), Colors.indigoAccent),
                _buildStatItem('Converted', source.convertedLeads.toString(), const Color(0xFF10B981)),
                _buildStatItem('Lost', source.lostLeads.toString(), const Color(0xFFEF4444)),
              ],
            ),

            const SizedBox(height: 16),

            // Conversion Rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up_rounded, color: Colors.indigoAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Conversion Rate: ${source.conversionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigoAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // View Leads Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to leads filtered by source
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Leads from this Source'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetails(
    BuildContext context,
    EmployeePerformance employee,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Avatar & Name
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.indigoAccent.withOpacity(0.1),
              child: Text(
                employee.initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigoAccent,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              employee.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPerformanceColor(employee.performanceLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                employee.performanceLevel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _getPerformanceColor(employee.performanceLevel),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                _buildStatItem('Total', employee.totalLeads.toString(), Colors.indigoAccent),
                _buildStatItem('Converted', employee.convertedLeads.toString(), const Color(0xFF10B981)),
                _buildStatItem('Interactions', employee.totalInteractions.toString(), const Color(0xFFF59E0B)),
              ],
            ),

            const SizedBox(height: 16),

            // Conversion Rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_graph_rounded, color: Colors.indigoAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Conversion Rate: ${employee.conversionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigoAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // View Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to employee profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Employee Details'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(String level) {
    switch (level) {
      case 'Excellent':
        return const Color(0xFF10B981);
      case 'Good':
        return const Color(0xFF3B82F6);
      case 'Average':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧭 NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _navigateToLeads(BuildContext context) {
    Navigator.pushNamed(context, '/leads');
  }

  void _navigateToConversions(BuildContext context) {
    // TODO: Navigate to conversions report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversions Report - Coming Soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToFollowUps(BuildContext context, String type) {
    // TODO: Navigate to follow-ups with filter
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type == 'today' ? 'Today\'s' : 'Overdue'} Follow-ups'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToAddLead(BuildContext context) {
    Navigator.pushNamed(context, '/add-lead');
  }
}