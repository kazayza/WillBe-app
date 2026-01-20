import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../config/app_sections.dart';

// Screens imports
import 'login_screen.dart';
import 'children_list_screen.dart';
import 'employees_list_screen.dart';
import 'employee_attendance_screen.dart';
import 'AttendanceHistoryScreen.dart';
import 'expenses_list_screen.dart';
import 'section_screens_page.dart'; // هنعمله بعدين

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════
  
  DashboardStats? stats;
  bool isLoading = true;
  bool isRefreshing = false;
  int _pendingTasksCount = 0;
  List<Map<String, dynamic>> _todayBirthdays = [];
  List<Map<String, dynamic>> _alerts = [];

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadAllData();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إعداد الـ Animations
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);

    await Future.wait([
      _loadStats(),
      _loadPendingTasks(),
      _loadTodayBirthdays(),
      _loadAlerts(),
    ]);

    if (mounted) {
      setState(() => isLoading = false);
      _fadeController.forward();
      _slideController.forward();
    }
  }

  Future<void> _refreshData() async {
    if (isRefreshing) return;
    
    setState(() => isRefreshing = true);
    HapticFeedback.mediumImpact();

    await Future.wait([
      _loadStats(),
      _loadPendingTasks(),
      _loadTodayBirthdays(),
    ]);

    if (mounted) {
      setState(() => isRefreshing = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.get('dashboard');
      if (mounted) {
        setState(() => stats = DashboardStats.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadPendingTasks() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final empId = auth.empId;
      if (empId != null) {
        final data = await ApiService.get('tasks/$empId?status=Pending');
        if (mounted && data is List) {
          setState(() => _pendingTasksCount = data.length);
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _loadTodayBirthdays() async {
    try {
      final data = await ApiService.get('children/birthdays/today');
      if (mounted && data is List) {
        setState(() => _todayBirthdays = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error loading birthdays: $e');
    }
  }

  Future<void> _loadAlerts() async {
    // يمكن إضافة API لاحقاً
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════════════════

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "صباح الخير";
    if (hour < 17) return "مساء الخير";
    if (hour < 21) return "مساء النور";
    return "مساء الخير";
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "☀️";
    if (hour < 17) return "🌤️";
    if (hour < 21) return "🌅";
    return "🌙";
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${days[now.weekday % 7]}، ${now.day} ${months[now.month - 1]}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return "م";
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0] : "م";
    return "${parts[0][0]}${parts[1][0]}";
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build Method
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    // تغيير لون الـ Status Bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isScrolled ? (isDark ? Brightness.light : Brightness.dark) : Brightness.light,
    ));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      drawer: _buildDrawer(auth, user, isDark),
      body: isLoading
          ? _buildLoadingWidget(isDark)
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFF6366F1),
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ═══════════════════════════════════════════════════════
                  // الـ Header
                  // ═══════════════════════════════════════════════════════
                  _buildSliverAppBar(user, isDark, themeProvider),

                  // ═══════════════════════════════════════════════════════
                  // المحتوى الرئيسي
                  // ═══════════════════════════════════════════════════════
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),

                              // 1️⃣ Welcome Card
                              _buildWelcomeCard(user, isDark),
                              const SizedBox(height: 24),

                              // 2️⃣ Stats Section
                              _buildStatsSection(isDark, auth),
                              const SizedBox(height: 28),

                              // 3️⃣ Quick Actions
                              _buildQuickActionsSection(isDark, auth),
                              const SizedBox(height: 28),

                              // 4️⃣ Alerts Section (لو فيه)
                              if (_todayBirthdays.isNotEmpty || _pendingTasksCount > 0)
                                _buildAlertsSection(isDark),
                              if (_todayBirthdays.isNotEmpty || _pendingTasksCount > 0)
                                const SizedBox(height: 28),

                              // 5️⃣ Main Sections
                              _buildMainSections(isDark, auth),
                              const SizedBox(height: 28),

                              // 6️⃣ Financial Overview
                              if (auth.canView('frm_income') || auth.canView('frm_expenses'))
                                _buildFinancialOverview(isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(dynamic user, bool isDark, ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _isScrolled
          ? (isDark ? const Color(0xFF1A1A2E) : Colors.white)
          : Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFA855F7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Will Be Kindergarten",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getTodayDate(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),

      // Leading - Menu
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(8),
          child: _buildAppBarButton(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openDrawer(),
            isScrolled: _isScrolled,
            isDark: isDark,
          ),
        ),
      ),

      // Actions
      actions: [
        // Notifications
        _buildAppBarButton(
          icon: Icons.notifications_outlined,
          badge: 3,
          onTap: () => _showNotificationsSheet(isDark),
          isScrolled: _isScrolled,
          isDark: isDark,
        ),
        const SizedBox(width: 4),

        // Theme Toggle
        _buildAppBarButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            themeProvider.toggleTheme();
          },
          isScrolled: _isScrolled,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
    required bool isScrolled,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isScrolled
              ? (isDark ? Colors.grey[800] : Colors.grey[100])
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: isScrolled
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: isScrolled
                  ? (isDark ? Colors.white : Colors.grey[700])
                  : Colors.white,
              size: 22,
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge > 9 ? '9+' : badge.toString(),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 👋 WELCOME CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeCard(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F1E) : Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Center(
                child: Text(
                  _getInitials(user?.fullName ?? "م"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      ).createShader(const Rect.fromLTWH(0, 0, 50, 50)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getGreetingEmoji(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user?.fullName ?? "مستخدم",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user?.role ?? "مستخدم",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tasks Button
          if (_pendingTasksCount > 0)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to tasks
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          color: isDark
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF6366F1),
                          size: 24,
                        ),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _pendingTasksCount > 9
                                  ? '9+'
                                  : _pendingTasksCount.toString(),
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
                    const SizedBox(height: 6),
                    Text(
                      "مهامي",
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 STATS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsSection(bool isDark, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader(
          title: "نظرة سريعة",
          icon: Icons.analytics_rounded,
          color: const Color(0xFF6366F1),
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "مباشر",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats Grid
        Row(
          children: [
            // Children Stats
            if (auth.canView('frm_Child'))
              Expanded(
                child: _buildStatCard(
                  title: "الأطفال",
                  value: stats?.childrenCount ?? 0,
                  icon: Icons.child_care_rounded,
                  gradient: AppColors.childrenGradient,
                  trend: "+12%",
                  trendUp: true,
                  isDark: isDark,
                  index: 0,
                ),
              ),

            if (auth.canView('frm_Child') && auth.canView('Employee List'))
              const SizedBox(width: 12),

            // Employees Stats
            if (auth.canView('Employee List'))
              Expanded(
                child: _buildStatCard(
                  title: "الموظفين",
                  value: stats?.employeesCount ?? 0,
                  icon: Icons.groups_rounded,
                  gradient: AppColors.hrGradient,
                  trend: "+3",
                  trendUp: true,
                  isDark: isDark,
                  index: 1,
                ),
              ),
          ],
        ),

        // Financial Stats
        if (auth.canView('frm_income') || auth.canView('frm_expenses'))
          const SizedBox(height: 12),

        if (auth.canView('frm_income') || auth.canView('frm_expenses'))
          Row(
            children: [
              // Income
              if (auth.canView('frm_income'))
                Expanded(
                  child: _buildStatCard(
                    title: "الإيرادات",
                    value: stats?.monthlyIncome ?? 0,
                    icon: Icons.trending_up_rounded,
                    gradient: AppColors.incomeGradient,
                    isCurrency: true,
                    trend: "+8%",
                    trendUp: true,
                    isDark: isDark,
                    index: 2,
                  ),
                ),

              if (auth.canView('frm_income') && auth.canView('frm_expenses'))
                const SizedBox(width: 12),

              // Expenses
              if (auth.canView('frm_expenses'))
                Expanded(
                  child: _buildStatCard(
                    title: "المصروفات",
                    value: stats?.monthlyExpense ?? 0,
                    icon: Icons.trending_down_rounded,
                    gradient: AppColors.expenseGradient,
                    isCurrency: true,
                    trend: "-5%",
                    trendUp: false,
                    isDark: isDark,
                    index: 3,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required num value,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required int index,
    String? trend,
    bool trendUp = true,
    bool isCurrency = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
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
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                isCurrency
                    ? "${_formatNumber(value)}"
                    : value.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isCurrency)
              const Text(
                "ج.م",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 SECTION HEADER HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "عرض الكل",
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                ],
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildLoadingWidget(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
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
                color: isDark
                    ? const Color(0xFF1E1E2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "جاري تحميل البيانات...",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
  // ⚡ QUICK ACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection(bool isDark, AuthProvider auth) {
    // فلترة الـ Quick Actions حسب الصلاحيات
    final availableActions = AppSections.quickActions
        .where((action) => auth.canView(action.formName))
        .toList();

    if (availableActions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "الوصول السريع",
          icon: Icons.flash_on_rounded,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Quick Actions Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: availableActions.length > 8 ? 8 : availableActions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionItem(
              action: availableActions[index],
              isDark: isDark,
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required QuickAction action,
    required bool isDark,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _navigateToScreen(action.formName);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: action.gradient[0].withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: action.gradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔔 ALERTS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsSection(bool isDark) {
    final List<_AlertItem> alerts = [];

    // إضافة تنبيه أعياد الميلاد
    if (_todayBirthdays.isNotEmpty) {
      alerts.add(_AlertItem(
        icon: Icons.cake_rounded,
        title: "أعياد ميلاد اليوم 🎂",
        subtitle: "${_todayBirthdays.length} ${_todayBirthdays.length == 1 ? 'طفل' : 'أطفال'}",
        gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
        onTap: () => _showBirthdaysSheet(isDark),
      ));
    }

    // إضافة تنبيه المهام المعلقة
    if (_pendingTasksCount > 0) {
      alerts.add(_AlertItem(
        icon: Icons.pending_actions_rounded,
        title: "مهام معلقة",
        subtitle: "$_pendingTasksCount ${_pendingTasksCount == 1 ? 'مهمة' : 'مهام'} تحتاج متابعة",
        gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
        onTap: () {
          // Navigate to tasks
        },
      ));
    }

    // يمكن إضافة المزيد من التنبيهات لاحقاً
    // مثل: الأقساط المتأخرة، الغياب، إلخ

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "تنبيهات اليوم",
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFFEF4444),
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Alerts List
        ...alerts.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < alerts.length - 1 ? 12 : 0),
            child: _buildAlertCard(
              alert: entry.value,
              isDark: isDark,
              index: entry.key,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlertCard({
    required _AlertItem alert,
    required bool isDark,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          alert.onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                alert.gradient[0].withOpacity(isDark ? 0.2 : 0.1),
                alert.gradient[1].withOpacity(isDark ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: alert.gradient[0].withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: alert.gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: alert.gradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  alert.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: alert.gradient[0],
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📂 MAIN SECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMainSections(bool isDark, AuthProvider auth) {
    // فلترة الأقسام حسب الصلاحيات
    final availableSections = AppSections.all.where((section) {
      // يظهر القسم لو المستخدم عنده صلاحية لأي شاشة فيه
      return section.permissionKeys.any((key) => auth.canView(key));
    }).toList();

    if (availableSections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "الأقسام الرئيسية",
          icon: Icons.dashboard_rounded,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Sections Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: availableSections.length,
          itemBuilder: (context, index) {
            final section = availableSections[index];
            // حساب عدد الشاشات المتاحة للمستخدم في هذا القسم
            final availableScreensCount = section.screens
                .where((screen) => auth.canView(screen.formName))
                .length;

            return _buildSectionCard(
              section: section,
              screensCount: availableScreensCount,
              isDark: isDark,
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required AppSection section,
    required int screensCount,
    required bool isDark,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _openSectionPage(section);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: section.gradient[0].withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: section.gradient[0].withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: section.gradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: section.gradient[0].withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      section.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  // Screens Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: section.gradient[0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$screensCount",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: section.gradient[0],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.apps_rounded,
                          color: section.gradient[0],
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Title
              Flexible( // 👈 إضافة Flexible
                child: FittedBox( // 👈 عشان لو الاسم طويل يصغر الخط
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                section.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Arrow indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: section.gradient[0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: section.gradient[0],
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💵 FINANCIAL OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFinancialOverview(bool isDark) {
    final income = stats?.monthlyIncome ?? 0;
    final expense = stats?.monthlyExpense ?? 0;
    final profit = income - expense;
    final profitPercentage = income > 0 ? ((profit / income) * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "الملخص المالي",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "هذا الشهر",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Income & Expense Bars
          _buildFinancialBar(
            title: "الإيرادات",
            value: income,
            maxValue: income > expense ? income : expense,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildFinancialBar(
            title: "المصروفات",
            value: expense,
            maxValue: income > expense ? income : expense,
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Profit Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: profit >= 0
                    ? [
                        const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.1),
                        const Color(0xFF10B981).withOpacity(isDark ? 0.1 : 0.05),
                      ]
                    : [
                        const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.1),
                        const Color(0xFFEF4444).withOpacity(isDark ? 0.1 : 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profit >= 0
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFEF4444).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profit Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          profit >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: profit >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profit >= 0 ? "صافي الربح" : "صافي الخسارة",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_formatNumber(profit.abs())} ج.م",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: profit >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),

                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: profit >= 0
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: profit >= 0
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        profit >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${profitPercentage.abs().toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
    );
  }

  Widget _buildFinancialBar({
    required String title,
    required num value,
    required num maxValue,
    required Color color,
    required bool isDark,
  }) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              "${_formatNumber(value)} ج.م",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Bar
        Stack(
          children: [
            // Background
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Progress
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage.toDouble()),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, child) {
                return FractionallySizedBox(
                  widthFactor: animValue.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎂 BIRTHDAYS SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showBirthdaysSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🎂 أعياد ميلاد اليوم",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            "${_todayBirthdays.length} ${_todayBirthdays.length == 1 ? 'طفل' : 'أطفال'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),

              // List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _todayBirthdays.length,
                  itemBuilder: (context, index) {
                    final child = _todayBirthdays[index];
                    return _buildBirthdayListItem(
                      name: child['childName'] ?? 'طفل',
                      age: child['age']?.toString() ?? '?',
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBirthdayListItem({
    required String name,
    required String age,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252836)
            : const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : "؟",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "أصبح عمره $age سنة 🎉",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎂", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  "$age",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧭 NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _navigateToScreen(String formName) {
    // هنا ربط أسماء الشاشات بالـ Routes
    // يمكنك تعديل هذا حسب الشاشات الموجودة عندك

    switch (formName) {
      case 'frm_FullSearch':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChildrenListScreen()),
        );
        break;

      case 'frm_ChildNew':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChildrenListScreen()),
        );
        break;

      case 'Employee List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeesListScreen()),
        );
        break;

      case 'frm_absenseEmp':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeAttendanceScreen()),
        );
        break;

      case 'frm_expenses':
      case 'frm_expSingle':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpensesListScreen()),
        );
        break;

      // أضف باقي الشاشات هنا...

      default:
        _showComingSoonDialog(formName);
    }
  }

  void _openSectionPage(AppSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionScreensPage(section: section),
      ),
    );
  }

  void _showComingSoonDialog(String formName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "شاشة '$formName' قيد التطوير",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
    // ═══════════════════════════════════════════════════════════════════════════
  // 📱 DRAWER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDrawer(AuthProvider auth, dynamic user, bool isDark) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 30,
                24,
                30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(user?.fullName ?? "م"),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?.fullName ?? "مستخدم",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          user?.role ?? "مستخدم",
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: "لوحة التحكم",
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  
                  // Dynamic Sections
                  ...AppSections.all.where((section) {
                    return section.permissionKeys.any((key) => auth.canView(key));
                  }).map((section) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildDrawerItem(
                        icon: section.icon,
                        title: section.title,
                        color: section.gradient[0],
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          _openSectionPage(section);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showLogoutDialog(auth, isDark),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "تسجيل الخروج",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "تسجيل الخروج",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          "هل أنت متأكد؟",
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("خروج", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.notifications_outlined,
              size: 50,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "لا توجد إشعارات جديدة",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔔 NOTIFICATIONS SHEET
  // ═══════════════════════════════════════════════════════════════════════════



  Widget _buildNotificationListItem({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isNew = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew
            ? color.withOpacity(isDark ? 0.1 : 0.05)
            : (isDark ? const Color(0xFF252836) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(16),
        border: isNew ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 ALERT ITEM MODEL
// ═══════════════════════════════════════════════════════════════════════════

class _AlertItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  _AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}