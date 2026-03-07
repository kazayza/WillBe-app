import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/employees_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/employee_model.dart';
import 'employee_form_screen.dart';
import 'employee_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();

  // Filter Values
  bool? _filterActive;
  int? _filterBranch;
  String? _filterBranchName;
  String? _filterJob;
  int? _filterWorkerType;
  String? _filterWorkerTypeName;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSearching = false;
  int _activeFiltersCount = 0;

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
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _loadData() {
    Future.microtask(() {
      final provider = Provider.of<EmployeesProvider>(context, listen: false);
      provider.fetchEmployees();
      provider.fetchLookups();
      _animationController.forward();
    });
  }

  void _applyFilter() {
    Provider.of<EmployeesProvider>(context, listen: false).fetchEmployees(
      query: _searchController.text,
      isActive: _filterActive,
      branchId: _filterBranch,
      jobTitle: _filterJob,
      workerTypeId: _filterWorkerType,
    );
    _updateActiveFiltersCount();
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    if (_filterActive != null) count++;
    if (_filterBranch != null) count++;
    if (_filterJob != null) count++;
    if (_filterWorkerType != null) count++;
    setState(() => _activeFiltersCount = count);
  }

  void _clearAllFilters() {
    setState(() {
      _filterActive = null;
      _filterBranch = null;
      _filterBranchName = null;
      _filterJob = null;
      _filterWorkerType = null;
      _filterWorkerTypeName = null;
      _activeFiltersCount = 0;
    });
    _applyFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // ═══════════════════════════════════════════════════════
// ✅ أضف الدوال هنا 👇
// ═══════════════════════════════════════════════════════

// ✅ دالة الاتصال
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  }
}

// ✅ دالة الواتساب
Future<void> _openWhatsApp(String phoneNumber) async {
  String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  
  if (cleanNumber.startsWith('0')) {
    cleanNumber = '+2$cleanNumber';
  } else if (!cleanNumber.startsWith('+')) {
    cleanNumber = '+2$cleanNumber';
  }
  
  final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
  
  if (await canLaunchUrl(whatsappUri)) {
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }
}

// ✅ Bottom Sheet للاتصال/واتساب
void _showContactOptions(String phoneNumber, String empName, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
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
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التواصل مع',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      empName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              // Call Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _makePhoneCall(phoneNumber);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'اتصال',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // WhatsApp Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openWhatsApp(phoneNumber);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'واتساب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
          
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 10),
        ],
      ),
    ),
  );
}

// ✅ Widget مساعد لعرض معلومة واحدة (الفرع - الوظيفة)
Widget _buildInfoRow({
  required IconData icon,
  required String text,
  required Color color,
  required bool isDark,
}) {
  return Row(
    children: [
      Icon(
        icon,
        size: 12,
        color: color,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final canAdd = Provider.of<AuthProvider>(context, listen: false)
        .canAdd('Employee List');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 App Bar
          _buildSliverAppBar(isDark, provider),

          // 📊 Stats Bar
          SliverToBoxAdapter(
            child: _buildStatsBar(provider, isDark),
          ),

          // 🏷️ Active Filters
          if (_activeFiltersCount > 0)
            SliverToBoxAdapter(
              child: _buildActiveFilters(isDark),
            ),

          // 👥 Employees List
          provider.isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                )
              : provider.employees.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(isDark),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final emp = provider.employees[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildEmployeeCard(emp, isDark, index),
                            );
                          },
                          childCount: provider.employees.length,
                        ),
                      ),
                    ),
        ],
      ),

      // ➕ FAB
      floatingActionButton: canAdd ? _buildFAB() : null,
    );
  }

  // 🎨 Sliver App Bar
  Widget _buildSliverAppBar(bool isDark, EmployeesProvider provider) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
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
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // 🔍 Search Toggle
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _applyFilter();
              }
            });
          },
        ),

        // 🔽 Filter
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _activeFiltersCount > 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _activeFiltersCount > 0
                      ? const Color(0xFF3B82F6)
                      : Colors.white,
                  size: 20,
                ),
                if (_activeFiltersCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "$_activeFiltersCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onPressed: () => _showFilterBottomSheet(provider, isDark),
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
                bottom: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "إدارة الموظفين",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "عرض وإدارة بيانات الموظفين",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "ابحث بالاسم أو الوظيفة...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // 📊 Stats Bar
  Widget _buildStatsBar(EmployeesProvider provider, bool isDark) {
    final totalEmployees = provider.employees.length;
    final activeEmployees = provider.employees.where((e) => e.status).length;
    final inactiveEmployees = totalEmployees - activeEmployees;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.groups_rounded,
              label: "الإجمالي",
              value: totalEmployees.toString(),
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              label: "موجود",
              value: activeEmployees.toString(),
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cancel_rounded,
              label: "غير موجود",
              value: inactiveEmployees.toString(),
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Active Filters
  Widget _buildActiveFilters(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              "الفلاتر:",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),

            // Status Filter
            if (_filterActive != null)
              _buildFilterChip(
                label: _filterActive! ? "موجود" : "غير موجود",
                icon: _filterActive! ? Icons.check_circle : Icons.cancel,
                color: _filterActive! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                onRemove: () {
                  setState(() => _filterActive = null);
                  _applyFilter();
                },
              ),

            // Branch Filter
            if (_filterBranch != null)
              _buildFilterChip(
                label: _filterBranchName ?? "فرع",
                icon: Icons.store_rounded,
                color: const Color(0xFF8B5CF6),
                onRemove: () {
                  setState(() {
                    _filterBranch = null;
                    _filterBranchName = null;
                  });
                  _applyFilter();
                },
              ),

            // Job Filter
            if (_filterJob != null)
              _buildFilterChip(
                label: _filterJob!,
                icon: Icons.work_rounded,
                color: const Color(0xFFF59E0B),
                onRemove: () {
                  setState(() => _filterJob = null);
                  _applyFilter();
                },
              ),

            // Worker Type Filter
            if (_filterWorkerType != null)
              _buildFilterChip(
                label: _filterWorkerTypeName ?? "نوع",
                icon: Icons.category_rounded,
                color: const Color(0xFF06B6D4),
                onRemove: () {
                  setState(() {
                    _filterWorkerType = null;
                    _filterWorkerTypeName = null;
                  });
                  _applyFilter();
                },
              ),

            const SizedBox(width: 8),

            // Clear All
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "مسح الكل",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 Employee Card
Widget _buildEmployeeCard(Employee emp, bool isDark, int index) {
  final statusColor = emp.status ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  final cardColor = emp.status ? const Color(0xFF3B82F6) : const Color(0xFF6B7280);

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 400 + (index * 50)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      );
    },
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeDetailsScreen(employee: emp),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                      colors: [cardColor, cardColor.withOpacity(0.5)],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Status
                    Stack(
                      children: [
                        Hero(
                          tag: 'emp_avatar_${emp.id}',
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cardColor.withOpacity(0.2),
                                  cardColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                emp.empName.isNotEmpty ? emp.empName[0] : "?",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Status Indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF252836) : Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                emp.status ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // ✅ Info - التخطيط الجديد (عمودي)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Employee Name
                          Text(
                            emp.empName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),

                          // Branch
                          if (emp.branchName != null && emp.branchName!.isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.store_rounded,
                              text: emp.branchName!,
                              color: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),

                          if (emp.branchName != null && emp.branchName!.isNotEmpty)
                            const SizedBox(height: 4),

                          // Job
                          if (emp.job != null && emp.job!.isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.work_outline_rounded,
                              text: emp.job!,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),

                          // ✅ Mobile with Direct Actions
if (emp.mobile1 != null && emp.mobile1!.isNotEmpty) ...[
  const SizedBox(height: 6),
  Row(
    children: [
      // Phone Number Display
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_rounded,
                size: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  emp.mobile1!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(width: 8),
      
      // ✅ Call Button
      GestureDetector(
        onTap: () => _makePhoneCall(emp.mobile1!),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.call_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
      
      const SizedBox(width: 6),
      
      // ✅ WhatsApp Button
      GestureDetector(
        onTap: () => _openWhatsApp(emp.mobile1!),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25D366), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Actions Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Edit Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeFormScreen(empId: emp.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF3B82F6),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // View Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: cardColor,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا يوجد موظفين",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "جرب تغيير الفلاتر أو اضغط + للإضافة",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("إضافة موظف"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ➕ FAB
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.person_add_rounded, size: 26, color: Colors.white),
      ),
    );
  }

  // 🔽 Filter Bottom Sheet
  void _showFilterBottomSheet(EmployeesProvider provider, bool isDark) {
    if (provider.branches.isEmpty) provider.fetchLookups();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "تصفية الموظفين",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "اختر معايير البحث",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_activeFiltersCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$_activeFiltersCount فلتر",
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  // Filters Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Filter
                          _buildFilterSection(
                            title: "الحالة",
                            icon: Icons.toggle_on_rounded,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                            child: Wrap(
                              spacing: 10,
                              children: [
                                _buildStatusChip(
                                  label: "الكل",
                                  isSelected: _filterActive == null,
                                  color: const Color(0xFF6B7280),
                                  onTap: () => setSheetState(() => _filterActive = null),
                                ),
                                _buildStatusChip(
                                  label: "موجود",
                                  icon: Icons.check_circle_rounded,
                                  isSelected: _filterActive == true,
                                  color: const Color(0xFF10B981),
                                  onTap: () => setSheetState(() => _filterActive = true),
                                ),
                                _buildStatusChip(
                                  label: "غير موجود",
                                  icon: Icons.cancel_rounded,
                                  isSelected: _filterActive == false,
                                  color: const Color(0xFFEF4444),
                                  onTap: () => setSheetState(() => _filterActive = false),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Branch Filter
                          _buildFilterSection(
                            title: "الفرع",
                            icon: Icons.store_rounded,
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                            child: provider.branches.isNotEmpty
                                ? _buildModernDropdown(
                                    value: _filterBranch,
                                    hint: "اختر الفرع",
                                    isDark: isDark,
                                    items: provider.branches
                                        .map((b) => DropdownMenuItem<int>(
                                              value: b['IDbranch'],
                                              child: Text(b['branchName'] ?? '---'),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setSheetState(() {
                                        _filterBranch = val;
                                        _filterBranchName = provider.branches
                                            .firstWhere(
                                              (b) => b['IDbranch'] == val,
                                              orElse: () => {'branchName': ''},
                                            )['branchName'];
                                      });
                                    },
                                  )
                                : _buildEmptyFilterMessage("لا توجد فروع متاحة"),
                          ),

                          const SizedBox(height: 24),

                          // Job Filter
                          _buildFilterSection(
                            title: "الوظيفة",
                            icon: Icons.work_rounded,
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                            child: provider.jobs.isNotEmpty
                                ? _buildModernDropdown(
                                    value: _filterJob,
                                    hint: "اختر الوظيفة",
                                    isDark: isDark,
                                    items: provider.jobs
                                        .map((j) => DropdownMenuItem<String>(
                                              value: j['job'],
                                              child: Text(j['job'] ?? '---'),
                                            ))
                                        .toList(),
                                    onChanged: (val) => setSheetState(() => _filterJob = val),
                                  )
                                : _buildEmptyFilterMessage("لا توجد وظائف متاحة"),
                          ),

                          const SizedBox(height: 24),

                          // Worker Type Filter
                          _buildFilterSection(
                            title: "نوع العمالة",
                            icon: Icons.category_rounded,
                            color: const Color(0xFF06B6D4),
                            isDark: isDark,
                            child: provider.workerTypes.isNotEmpty
                                ? _buildModernDropdown(
                                    value: _filterWorkerType,
                                    hint: "اختر نوع العمالة",
                                    isDark: isDark,
                                    items: provider.workerTypes
                                        .map((w) => DropdownMenuItem<int>(
                                              value: w['ID'],
                                              child: Text(w['workdescription'] ?? '---'),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setSheetState(() {
                                        _filterWorkerType = val;
                                        _filterWorkerTypeName = provider.workerTypes
                                            .firstWhere(
                                              (w) => w['ID'] == val,
                                              orElse: () => {'workdescription': ''},
                                            )['workdescription'];
                                      });
                                    },
                                  )
                                : _buildEmptyFilterMessage("لا توجد أنواع عمالة"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                _filterActive = null;
                                _filterBranch = null;
                                _filterBranchName = null;
                                _filterJob = null;
                                _filterWorkerType = null;
                                _filterWorkerTypeName = null;
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text("مسح الكل"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _applyFilter();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text(
                                "تطبيق الفلاتر",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String hint,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[500]),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[500],
          ),
          dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}