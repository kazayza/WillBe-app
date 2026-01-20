import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_sections.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// Import your screens
import 'children_list_screen.dart';
import 'employees_list_screen.dart';
import 'employee_attendance_screen.dart';
import 'expenses_list_screen.dart';
import 'add_expense_screen.dart';
import 'add_lead_screen.dart';
import 'add_task_screen.dart';
import 'crm_dashboard_screen.dart';
import 'customers_list_screen.dart';
import 'customer_interactions_screen.dart';
import 'tasks_list_screen.dart';
import 'child_form_screen.dart';
import 'leads_list_screen.dart';

// أضف باقي الـ imports حسب الشاشات الموجودة عندك

class SectionScreensPage extends StatefulWidget {
  final AppSection section;

  const SectionScreensPage({
    super.key,
    required this.section,
  });

  @override
  State<SectionScreensPage> createState() => _SectionScreensPageState();
}

class _SectionScreensPageState extends State<SectionScreensPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    // فلترة الشاشات المتاحة حسب الصلاحيات
    final availableScreens = widget.section.screens
        .where((screen) => auth.canView(screen.formName))
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════════
          // App Bar
          // ═══════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.section.gradient,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative Elements
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      bottom: 25,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              widget.section.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            widget.section.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle + Count
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.section.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
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
                                      Icons.apps_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${availableScreens.length} شاشة",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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

          // ═══════════════════════════════════════════════════════
          // Screens Grid
          // ═══════════════════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final screen = availableScreens[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildScreenCard(
                      screen: screen,
                      auth: auth,
                      isDark: isDark,
                      index: index,
                    ),
                  );
                },
                childCount: availableScreens.length,
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════
          // Bottom Padding
          // ═══════════════════════════════════════════════════════
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenCard({
    required SubScreen screen,
    required AuthProvider auth,
    required bool isDark,
    required int index,
  }) {
    // التحقق من صلاحيات الإضافة والتعديل والحذف
    final canAdd = auth.canAdd(screen.formName);
    final canEdit = auth.canEdit(screen.formName);
    final canDelete = auth.canDelete(screen.formName);

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
          _navigateToScreen(screen.formName);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.section.gradient[0].withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.section.gradient[0].withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.section.gradient[0],
                      widget.section.gradient[1].withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.section.gradient[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  screen.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const Spacer(),

              // Title
              Text(
                screen.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Permission Badges
              Row(
                children: [
                  if (canAdd)
                    _buildPermissionBadge(
                      icon: Icons.add,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  if (canEdit)
                    _buildPermissionBadge(
                      icon: Icons.edit,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  if (canDelete)
                    _buildPermissionBadge(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.section.gradient[0].withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBadge({
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: color,
        size: 12,
      ),
    );
  }

  void _navigateToScreen(String formName) {
    Widget? targetScreen;

    // ربط أسماء الشاشات بالـ Screens
    switch (formName) {
      // ═══════════════════════════════════════════════════════
      // شئون الأطفال
      // ═══════════════════════════════════════════════════════
      case 'frm_Child':
      case 'frm_FullSearch':
              targetScreen = const ChildrenListScreen();
        break;

      case 'frm_ChildNew':
        targetScreen = const ChildFormScreen();
        break;
      // ═══════════════════════════════════════════════════════
      // الموارد البشرية
      // ═══════════════════════════════════════════════════════
      case 'Employee List':
      case 'frm_EmployeeDetails':
        targetScreen = const EmployeesListScreen();
        break;

      case 'frm_absenseEmp':
        targetScreen = const EmployeeAttendanceScreen();
        break;

      // ═══════════════════════════════════════════════════════
      // إدارة العملاء CRM
      // ═══════════════════════════════════════════════════════
      case 'frmCRMDashboard':
        targetScreen = const CRMDashboardScreen();
        break;

      case 'frmAddLeads':
        targetScreen = const AddLeadScreen();
        break;
      
      case 'frmLeads':
        targetScreen = const LeadsListScreen();
        break;

      case 'frmAddTask':
       targetScreen = const AddTaskScreen();
       break;

      case 'frmTasksList':
       targetScreen = const TasksListScreen();
       break; 



      // ═══════════════════════════════════════════════════════
      // المصروفات
      // ═══════════════════════════════════════════════════════
      case 'frm_expenses':
      case 'frm_tbl_expenses':
        targetScreen = const ExpensesListScreen();
        break;
      
      case 'frm_expSingle':
       targetScreen = const AddExpenseScreen();
       break;
      // ═══════════════════════════════════════════════════════
      // أضف المزيد من الشاشات هنا حسب ما عندك
      // ═══════════════════════════════════════════════════════

      default:
        targetScreen = null;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen!),
      );
    } else {
      _showComingSoonSnackbar(formName);
    }
  }

  void _showComingSoonSnackbar(String formName) {
    // البحث عن اسم الشاشة بالعربي
    String arabicName = formName;
    for (var screen in widget.section.screens) {
      if (screen.formName == formName) {
        arabicName = screen.title;
        break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "قيد التطوير",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    arabicName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: widget.section.gradient[0],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}