import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee_model.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _fullData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFullData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _loadFullData() async {
    try {
      final data = await ApiService.get('employees/${widget.employee.id}');
      if (mounted) {
        setState(() {
          _fullData = data;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final emp = widget.employee;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 Hero App Bar
          _buildSliverAppBar(isDark, emp),

          // 📊 Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // 🎯 Quick Actions Bar
                            _buildQuickActions(isDark),

                            const SizedBox(height: 20),

                            // 👤 Personal Info Card
                            _buildInfoCard(
                              isDark: isDark,
                              title: "البيانات الشخصية",
                              icon: Icons.person_rounded,
                              color: const Color(0xFF3B82F6),
                              delay: 0,
                              children: [
                                _buildInfoRow(
                                  icon: Icons.badge_rounded,
                                  label: "الاسم الكامل",
                                  value: emp.empName,
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.credit_card_rounded,
                                  label: "الرقم القومي",
                                  value: emp.nationalID?.toString(),
                                  isDark: isDark,
                                  isMonospace: true,
                                ),
                                _buildInfoRow(
                                  icon: Icons.phone_rounded,
                                  label: "الموبايل",
                                  value: emp.mobile1,
                                  isDark: isDark,
                                  isPhone: true,
                                ),
                                if (_fullData?['mobile2'] != null &&
                                    _fullData!['mobile2'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.phone_android_rounded,
                                    label: "موبايل 2",
                                    value: _fullData!['mobile2'],
                                    isDark: isDark,
                                    isPhone: true,
                                  ),
                                if (_fullData?['email'] != null &&
                                    _fullData!['email'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.email_rounded,
                                    label: "البريد الإلكتروني",
                                    value: _fullData!['email'],
                                    isDark: isDark,
                                  ),
                                if (_fullData?['adress'] != null &&
                                    _fullData!['adress'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.home_rounded,
                                    label: "العنوان",
                                    value: _fullData!['adress'],
                                    isDark: isDark,
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 💼 Job Info Card
                            _buildInfoCard(
                              isDark: isDark,
                              title: "البيانات الوظيفية",
                              icon: Icons.work_rounded,
                              color: const Color(0xFFF59E0B),
                              delay: 100,
                              children: [
                                _buildInfoRow(
                                  icon: Icons.work_outline_rounded,
                                  label: "المسمى الوظيفي",
                                  value: emp.job,
                                  isDark: isDark,
                                  valueColor: const Color(0xFFF59E0B),
                                ),
                                _buildInfoRow(
                                  icon: Icons.store_rounded,
                                  label: "الفرع",
                                  value: emp.branchName,
                                  isDark: isDark,
                                  valueColor: const Color(0xFF8B5CF6),
                                ),
                                _buildInfoRow(
                                  icon: Icons.account_tree_rounded,
                                  label: "الإدارة",
                                  value: emp.managementName,
                                  isDark: isDark,
                                ),
                                if (_fullData?['jobdate'] != null)
                                  _buildInfoRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: "تاريخ التعيين",
                                    value: _formatDate(_fullData!['jobdate']),
                                    isDark: isDark,
                                  ),
                                if (_fullData?['Qualification'] != null &&
                                    _fullData!['Qualification'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.school_rounded,
                                    label: "المؤهل",
                                    value: _fullData!['Qualification'],
                                    isDark: isDark,
                                  ),
                                if (_fullData?['Experience'] != null &&
                                    _fullData!['Experience'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.timeline_rounded,
                                    label: "الخبرة",
                                    value: _fullData!['Experience'],
                                    isDark: isDark,
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 📊 Status & Tags Card
                            _buildStatusCard(isDark, emp),

                            const SizedBox(height: 30),

                            // 🔧 Actions Grid
                            _buildActionsGrid(isDark),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 🎨 Sliver App Bar with Hero
  Widget _buildSliverAppBar(bool isDark, Employee emp) {
    final statusColor = emp.status ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF3B82F6),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Edit Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeFormScreen(empId: emp.id),
              ),
            );
            _loadFullData();
          },
        ),
        // More Options
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => _showOptionsSheet(isDark),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Circles
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
                left: -50,
                bottom: 50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Profile Content
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Avatar with Status
                    Stack(
                      children: [
                        Hero(
                          tag: 'emp_avatar_${emp.id}',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                emp.empName.isNotEmpty ? emp.empName[0] : "?",
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Status Indicator
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                emp.status ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Name
                    Text(
                      emp.empName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 5),

                    // Job Title Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.work_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            emp.job ?? "بدون مسمى",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
      ),
    );
  }

  // 🎯 Quick Actions Bar
  Widget _buildQuickActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            icon: Icons.phone_rounded,
            label: "اتصال",
            color: const Color(0xFF10B981),
            onTap: () => _makePhoneCall(),
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.message_rounded,
            label: "رسالة",
            color: const Color(0xFF3B82F6),
            onTap: () {},
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.email_rounded,
            label: "إيميل",
            color: const Color(0xFF8B5CF6),
            onTap: () {},
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.share_rounded,
            label: "مشاركة",
            color: const Color(0xFFF59E0B),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }

  // 🎴 Info Card
  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 Info Row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required bool isDark,
    bool isMonospace = false,
    bool isPhone = false,
    Color? valueColor,
  }) {
    final displayValue = value ?? "---";
    final hasValue = value != null && value.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF3B82F6).withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: valueColor ??
                              (hasValue
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey[400]),
                          fontFamily: isMonospace ? 'monospace' : null,
                        ),
                      ),
                    ),
                    if (isPhone && hasValue)
                      GestureDetector(
                        onTap: () => _makePhoneCall(value),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  // 📊 Status Card
Widget _buildStatusCard(bool isDark, Employee emp) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      borderRadius: BorderRadius.circular(20),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFF6B7280),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "الحالة والتصنيفات",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tags
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Status Tag
            _buildTag(
              label: emp.status ? "نشط" : "غير نشط",
              icon: emp.status ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: emp.status ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),

            // Branch Tag
            if (emp.branchName != null)
              _buildTag(
                label: emp.branchName!,
                icon: Icons.store_rounded,
                color: const Color(0xFF8B5CF6),
              ),

            // Worker Type Tag
            if (_fullData?['WorkerTypeName'] != null)
              _buildTag(
                label: _fullData!['WorkerTypeName'],
                icon: Icons.category_rounded,
                color: const Color(0xFF06B6D4),
              ),

            // ID Tag
            _buildTag(
              label: "ID: ${emp.id}",
              icon: Icons.tag_rounded,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ],
    ),
  );
}

  // 🏷️ Build Tag Widget
Widget _buildTag({
  required String label,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

  // 🔧 Actions Grid
  Widget _buildActionsGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "إجراءات سريعة",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildActionCard(
              icon: Icons.edit_rounded,
              label: "تعديل البيانات",
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeFormScreen(empId: widget.employee.id),
                  ),
                );
                _loadFullData();
              },
            ),
            _buildActionCard(
              icon: Icons.monetization_on_rounded,
              label: "الجزاءات / المكافآت",
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to Eshraf screen
              },
            ),
            _buildActionCard(
              icon: Icons.account_balance_wallet_rounded,
              label: "سجل الرواتب",
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to salary history
              },
            ),
            _buildActionCard(
              icon: Icons.event_busy_rounded,
              label: "سجل الغياب",
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to absence screen
              },
            ),
            _buildActionCard(
              icon: Icons.assessment_rounded,
              label: "تقييم الأداء",
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.history_rounded,
              label: "سجل النشاط",
              color: const Color(0xFF6B7280),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📞 Make Phone Call
  void _makePhoneCall([String? phone]) {
    final phoneNumber = phone ?? widget.employee.mobile1;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.phone, color: Colors.white),
              const SizedBox(width: 10),
              Text("جاري الاتصال بـ $phoneNumber"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ⚙️ Options Bottom Sheet
  void _showOptionsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              _buildOptionItem(
                icon: Icons.edit_rounded,
                label: "تعديل البيانات",
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeFormScreen(empId: widget.employee.id),
                    ),
                  ).then((_) => _loadFullData());
                },
              ),

              _buildOptionItem(
                icon: Icons.refresh_rounded,
                label: "تحديث البيانات",
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  _loadFullData();
                },
              ),

              _buildOptionItem(
                icon: Icons.print_rounded,
                label: "طباعة البيانات",
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              _buildOptionItem(
                icon: Icons.delete_rounded,
                label: "حذف الموظف",
                color: const Color(0xFFEF4444),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(isDark);
                },
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  // 🗑️ Delete Confirmation
  void _showDeleteConfirmation(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "تأكيد الحذف",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          "هل أنت متأكد من حذف بيانات ${widget.employee.empName}؟\nلا يمكن التراجع عن هذا الإجراء.",
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement delete
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 📅 Format Date
  String? _formatDate(dynamic date) {
    if (date == null) return null;
    try {
      final dateStr = date.toString().split('T')[0];
      final parts = dateStr.split('-');
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (e) {
      return date.toString();
    }
  }
}