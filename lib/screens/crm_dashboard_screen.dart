import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'leads_list_screen.dart';
import 'add_lead_screen.dart';
import 'customers_list_screen.dart';
import 'tasks_list_screen.dart';
import 'manage_sources_screen.dart';
import 'unified_interactions_screen.dart';
import 'lead_source_analytics_screen.dart';

class CRMDashboardScreen extends StatefulWidget {
  const CRMDashboardScreen({super.key});

  @override
  State<CRMDashboardScreen> createState() => _CRMDashboardScreenState();
}

class _CRMDashboardScreenState extends State<CRMDashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  // الإحصائيات الأساسية
  int _totalLeads = 0;
  int _newLeads = 0;
  int _contactedLeads = 0;
  int _interestedLeads = 0;
  int _notInterestedLeads = 0;
  int _followUpLeads = 0;
  int _convertedLeads = 0;
  int _lostLeads = 0;
  int _totalCustomers = 0;
  int _pendingTasks = 0;

  // إحصائيات المتابعات
  int _overdueFollowUps = 0;
  int _todayFollowUps = 0;
  int _tomorrowFollowUps = 0;

  // أفضل المصادر
  List<Map<String, dynamic>> _topSources = [];

  // آخر الـ Leads
  List<dynamic> _recentLeads = [];

  late AnimationController _animationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadDashboardData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // جلب الـ Leads
      final leads = await ApiService.get('leads');

      if (leads is List) {
        _totalLeads = leads.length;
        _newLeads = leads.where((l) => l['Status'] == 'New').length;
        _contactedLeads = leads.where((l) => l['Status'] == 'Contacted').length;
        _interestedLeads = leads.where((l) => l['Status'] == 'Interested').length;
        _notInterestedLeads = leads.where((l) => l['Status'] == 'Not Interested').length;
        _followUpLeads = leads.where((l) => l['Status'] == 'Follow Up').length;
        _convertedLeads = leads.where((l) => l['Status'] == 'Converted').length;
        _lostLeads = leads.where((l) => l['Status'] == 'Lost').length;

        // حساب المتابعات
        _calculateFollowUps(leads);

        // حساب أفضل المصادر
        _calculateTopSources(leads);

        // آخر 5 Leads
        _recentLeads = leads.take(5).toList();
      }

      // جلب العملاء
      try {
        final customers = await ApiService.get('customers');
        if (customers is List) {
          _totalCustomers = customers.length;
        }
      } catch (e) {
        debugPrint('Error loading customers: $e');
      }

      // جلب المهام المعلقة
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final empId = auth.empId;
        if (empId != null) {
          final tasks = await ApiService.get('tasks/$empId?status=Pending');
          if (tasks is List) {
            _pendingTasks = tasks.length;
          }
        }
      } catch (e) {
        debugPrint('Error loading tasks: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
        _statsAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('فشل تحميل البيانات: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // حساب المتابعات (متأخرة - اليوم - غداً)
  void _calculateFollowUps(List<dynamic> leads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    _overdueFollowUps = 0;
    _todayFollowUps = 0;
    _tomorrowFollowUps = 0;

    for (var lead in leads) {
      // تجاهل المحولين والمفقودين
      final status = lead['Status'];
      if (status == 'Converted' || status == 'Lost' || status == 'Not Interested') {
        continue;
      }

      final nextFollowUp = lead['NextFollowUp'];
      if (nextFollowUp != null) {
        try {
          final followUpDate = DateTime.parse(nextFollowUp);
          final followUpDay = DateTime(followUpDate.year, followUpDate.month, followUpDate.day);

          if (followUpDay.isBefore(today)) {
            _overdueFollowUps++;
          } else if (followUpDay.isAtSameMomentAs(today)) {
            _todayFollowUps++;
          } else if (followUpDay.isAtSameMomentAs(tomorrow)) {
            _tomorrowFollowUps++;
          }
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }
  }

  // حساب أفضل المصادر
  void _calculateTopSources(List<dynamic> leads) {
    final Map<String, int> sourceCounts = {};

    for (var lead in leads) {
      final source = lead['SourceName'] ?? lead['LeadSource'] ?? 'غير محدد';
      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }

    // ترتيب حسب العدد
    final sortedSources = sourceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // أخذ أفضل 3
    _topSources = sortedSources.take(3).map((e) {
      final percentage = _totalLeads > 0 ? (e.value / _totalLeads * 100) : 0.0;
      return {
        'name': e.key,
        'count': e.value,
        'percentage': percentage,
      };
    }).toList();
  }

  // حساب العملاء النشطين (بدون المحولين والمفقودين)
  int get _activeLeads {
    return _newLeads + _contactedLeads + _interestedLeads + _followUpLeads;
  }

  // حساب المفقودين (Not Interested + Lost)
  int get _totalLost {
    return _notInterestedLeads + _lostLeads;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? _buildLoadingWidget(isDark)
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF6366F1),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 🎨 App Bar
                  _buildSliverAppBar(isDark),

                  // ⚠️ قسم التنبيهات (جديد)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildAlertsSection(isDark),
                    ),
                  ),

                  // 📊 Overview Cards (محسّن)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildOverviewSection(isDark),
                    ),
                  ),

                  // 📈 Stats Grid (محسّن - 7 حالات)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStatsGrid(isDark),
                    ),
                  ),

                  // 🏆 أفضل المصادر (جديد)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTopSourcesSection(isDark),
                    ),
                  ),

                  // 📊 Conversion Funnel
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildFunnelCard(isDark),
                    ),
                  ),

                  // 🚀 Quick Actions
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildQuickActions(isDark),
                    ),
                  ),

                  // 📋 Recent Leads
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRecentLeads(isDark),
                    ),
                  ),

                  // Bottom Padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 30),
                  ),
                ],
              ),
            ),

      // FAB لإضافة Lead جديد
      floatingActionButton: _buildFAB(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚠️ قسم التنبيهات (جديد)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsSection(bool isDark) {
    // لو مفيش تنبيهات، مش هنعرض القسم
    if (_overdueFollowUps == 0 && _todayFollowUps == 0 && _tomorrowFollowUps == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _overdueFollowUps > 0
                ? [const Color(0xFFEF4444).withOpacity(0.1), const Color(0xFFF97316).withOpacity(0.05)]
                : [const Color(0xFFF59E0B).withOpacity(0.1), const Color(0xFF10B981).withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _overdueFollowUps > 0
                ? const Color(0xFFEF4444).withOpacity(0.3)
                : const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _overdueFollowUps > 0
                        ? const Color(0xFFEF4444).withOpacity(0.2)
                        : const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _overdueFollowUps > 0
                        ? Icons.warning_rounded
                        : Icons.notifications_active_rounded,
                    color: _overdueFollowUps > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _overdueFollowUps > 0 ? "تنبيهات تحتاج انتباهك!" : "متابعات قادمة",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "لا تفوت فرص التواصل مع العملاء",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alert Cards Row
            Row(
              children: [
                // متأخرة
                if (_overdueFollowUps > 0)
                  Expanded(
                    child: _buildAlertCard(
                      icon: Icons.error_rounded,
                      label: "متأخرة",
                      count: _overdueFollowUps,
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                      onTap: () => _navigateToLeadsWithFilter('overdue'),
                    ),
                  ),
                if (_overdueFollowUps > 0 && _todayFollowUps > 0)
                  const SizedBox(width: 10),

                // اليوم
                if (_todayFollowUps > 0)
                  Expanded(
                    child: _buildAlertCard(
                      icon: Icons.today_rounded,
                      label: "اليوم",
                      count: _todayFollowUps,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      onTap: () => _navigateToLeadsWithFilter('today'),
                    ),
                  ),
                if ((_overdueFollowUps > 0 || _todayFollowUps > 0) && _tomorrowFollowUps > 0)
                  const SizedBox(width: 10),

                // غداً
                if (_tomorrowFollowUps > 0)
                  Expanded(
                    child: _buildAlertCard(
                      icon: Icons.upcoming_rounded,
                      label: "غداً",
                      count: _tomorrowFollowUps,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: () => _navigateToLeadsWithFilter('tomorrow'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLeadsWithFilter(String filter) {
    // TODO: Navigate to leads with filter
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeadsListScreen()),
    ).then((_) => _loadDashboardData());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⏳ Loading Widget
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingWidget(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "جاري تحميل لوحة التحكم...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 Sliver App Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
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
        // Refresh Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _loadDashboardData,
        ),
        // Tasks Badge
        Stack(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksListScreen()),
                ).then((_) => _loadDashboardData());
              },
            ),
            if (_pendingTasks > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _pendingTasks > 9 ? '9+' : _pendingTasks.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Elements
              Positioned(
                right: -80,
                top: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: 60,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "إدارة العملاء",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "CRM - متابعة أولياء الأمور",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 Overview Section (محسّن)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverviewSection(bool isDark) {
    final conversionRate = _totalLeads > 0
        ? ((_convertedLeads / _totalLeads) * 100).toStringAsFixed(1)
        : "0";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // الكارت الأول: نشطين + محولين + مفقودين
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "العملاء المحتملين",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _totalLeads.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // نسبة التحويل
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            "$conversionRate%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "تحويل",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // تفاصيل: نشطين - محولين - مفقودين
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewMiniCard(
                        icon: Icons.person_search_rounded,
                        label: "نشطين",
                        value: _activeLeads.toString(),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOverviewMiniCard(
                        icon: Icons.check_circle_rounded,
                        label: "محولين",
                        value: _convertedLeads.toString(),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildOverviewMiniCard(
                        icon: Icons.cancel_rounded,
                        label: "مفقودين",
                        value: _totalLost.toString(),
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // الكارت الثاني: العملاء الفعليين
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
                  child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "العملاء الفعليين (أولياء الأمور)",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _totalCustomers.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📈 Stats Grid (محسّن - كل الحالات)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "تفاصيل الحالات",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الصف الأول: جدد - تم التواصل - مهتم - متابعة
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.fiber_new_rounded,
                    label: "جدد",
                    value: _newLeads.toString(),
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                    index: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.phone_in_talk_rounded,
                    label: "تم التواصل",
                    value: _contactedLeads.toString(),
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    index: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.star_rounded,
                    label: "مهتم",
                    value: _interestedLeads.toString(),
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    index: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.update_rounded,
                    label: "متابعة",
                    value: _followUpLeads.toString(),
                    color: const Color(0xFF06B6D4),
                    isDark: isDark,
                    index: 3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الصف الثاني: محول - غير مهتم - مفقود
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.check_circle_rounded,
                    label: "محول",
                    value: _convertedLeads.toString(),
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    index: 4,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.thumb_down_rounded,
                    label: "غير مهتم",
                    value: _notInterestedLeads.toString(),
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                    index: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.cancel_rounded,
                    label: "مفقود",
                    value: _lostLeads.toString(),
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                    index: 6,
                  ),
                ),
                const SizedBox(width: 8),
                // Empty space for alignment
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏆 أفضل المصادر (جديد)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopSourcesSection(bool isDark) {
    if (_topSources.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Color> sourceColors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];

    final List<IconData> sourceIcons = [
      Icons.emoji_events_rounded,
      Icons.military_tech_rounded,
      Icons.workspace_premium_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.leaderboard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "أفضل المصادر",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "من أين يأتي العملاء المحتملين؟",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeadSourceAnalyticsScreen()),
                    );
                  },
                  child: const Text(
                    "المزيد",
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sources List
            ...List.generate(_topSources.length, (index) {
              final source = _topSources[index];
              final color = sourceColors[index % sourceColors.length];
              final icon = sourceIcons[index % sourceIcons.length];

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 600 + (index * 150)),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Opacity(
                    opacity: animValue,
                    child: Transform.translate(
                      offset: Offset(30 * (1 - animValue), 0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: index < _topSources.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // الترتيب
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: index == 0
                              ? Icon(icon, color: Colors.white, size: 16)
                              : Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // اسم المصدر
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: source['percentage'] / 100),
                                duration: Duration(milliseconds: 1000 + (index * 200)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: color.withOpacity(0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 6,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // العدد والنسبة
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${source['count']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(source['percentage'] as double).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📈 Funnel Card (زي ما هو مع تحسين بسيط)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFunnelCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Side Accent
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "قمع التحويل",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "رحلة العميل من الاهتمام للتسجيل",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Funnel Steps
                  _buildFunnelStep(
                    label: "عملاء محتملين جدد",
                    count: _newLeads,
                    total: _totalLeads,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.fiber_new_rounded,
                    isDark: isDark,
                    index: 0,
                  ),
                  const SizedBox(height: 14),
                  _buildFunnelStep(
                    label: "تم التواصل معهم",
                    count: _contactedLeads,
                    total: _totalLeads,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.phone_in_talk_rounded,
                    isDark: isDark,
                    index: 1,
                  ),
                  const SizedBox(height: 14),
                  _buildFunnelStep(
                    label: "مهتمين",
                    count: _interestedLeads,
                    total: _totalLeads,
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.star_rounded,
                    isDark: isDark,
                    index: 2,
                  ),
                  const SizedBox(height: 14),
                  _buildFunnelStep(
                    label: "تم التحويل (تسجيل)",
                    count: _convertedLeads,
                    total: _totalLeads,
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                    isDark: isDark,
                    index: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    required bool isDark,
    required int index,
  }) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage),
                duration: Duration(milliseconds: 1000 + (index * 200)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${(percentage * 100).toStringAsFixed(1)}% من الإجمالي",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 Quick Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "إجراءات سريعة",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildActionCard(
                icon: Icons.person_add_alt_1_rounded,
                label: "إضافة عميل محتمل",
                color: const Color(0xFF6366F1),
                isDark: isDark,
                index: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLeadScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
              _buildActionCard(
                icon: Icons.settings_input_component_rounded,
                label: "إدارة المصادر",
                color: const Color(0xFFEC4899),
                isDark: isDark,
                index: 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageSourcesScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.analytics_rounded,
                label: "تحليل المصادر",
                color: const Color(0xFF06B6D4),
                isDark: isDark,
                index: 2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeadSourceAnalyticsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.people_alt_rounded,
                label: "العملاء المحتملين",
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                index: 3,
                badge: _activeLeads > 0 ? _activeLeads.toString() : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeadsListScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
              _buildActionCard(
                icon: Icons.family_restroom_rounded,
                label: "العملاء الفعليين",
                color: const Color(0xFF10B981),
                isDark: isDark,
                index: 4,
                badge: _totalCustomers > 0 ? _totalCustomers.toString() : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersListScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
              _buildActionCard(
                icon: Icons.history_edu_rounded,
                label: "سجل التواصل",
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                index: 5,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UnifiedInteractionsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.task_alt_rounded,
                label: "متابعات اليوم",
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                index: 6,
                badge: _pendingTasks > 0 ? _pendingTasks.toString() : null,
                badgeColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksListScreen()),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required int index,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Badge
              if (badge != null)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 Recent Leads
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentLeads(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Side Accent
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF59E0B),
                        const Color(0xFFF59E0B).withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "آخر العملاء المحتملين",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LeadsListScreen()),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text("عرض الكل"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Leads List
                    if (_recentLeads.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_search_rounded,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "لا يوجد عملاء محتملين بعد",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddLeadScreen(),
                                    ),
                                  ).then((_) => _loadDashboardData());
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("أضف الآن"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        _recentLeads.length,
                        (index) => _buildLeadItem(_recentLeads[index], isDark, index),
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

  Widget _buildLeadItem(dynamic lead, bool isDark, int index) {
    final name = (lead['FullName'] ?? '---').toString();
    final phone = (lead['Phone'] ?? '---').toString();
    final status = lead['Status'] ?? 'New';

    final statusConfig = _getStatusConfig(status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusConfig['color'].withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusConfig['color'].withOpacity(0.2),
                    statusConfig['color'].withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusConfig['color'],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusConfig['color'], statusConfig['color'].withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: statusConfig['color'].withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusConfig['icon'], color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusConfig['text'],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'New':
        return {
          'color': const Color(0xFFF59E0B),
          'text': 'جديد',
          'icon': Icons.fiber_new_rounded,
        };
      case 'Contacted':
        return {
          'color': const Color(0xFF3B82F6),
          'text': 'تم التواصل',
          'icon': Icons.phone_in_talk_rounded,
        };
      case 'Interested':
        return {
          'color': const Color(0xFF8B5CF6),
          'text': 'مهتم',
          'icon': Icons.star_rounded,
        };
      case 'Not Interested':
        return {
          'color': const Color(0xFFEC4899),
          'text': 'غير مهتم',
          'icon': Icons.thumb_down_rounded,
        };
      case 'Follow Up':
        return {
          'color': const Color(0xFF06B6D4),
          'text': 'متابعة',
          'icon': Icons.update_rounded,
        };
            case 'Converted':
        return {
          'color': const Color(0xFF10B981),
          'text': 'تم التحويل',
          'icon': Icons.check_circle_rounded,
        };
      case 'Lost':
        return {
          'color': const Color(0xFFEF4444),
          'text': 'مفقود',
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'color': const Color(0xFF6B7280),
          'text': status,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ➕ FAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLeadScreen()),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.person_add_rounded, size: 26, color: Colors.white),
      ),
    );
  }
}