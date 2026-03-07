import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_sections.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// Import your screens
import 'children_list_screen.dart';
import 'employees_list_screen.dart';
import 'employee_form_screen.dart';
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
import 'add_eshraf_screen.dart';
import 'eshraf_history_screen.dart';
import 'add_eshraf_only_screen.dart';
import 'add_customer_screen.dart';
import 'CRM_KPI_dashboard_screen.dart';
import 'unified_interactions_screen.dart';
import 'subscription_payment_screen.dart';
import 'general_income_screen.dart';
import 'all_incomes_screen.dart';
import 'income_kpi_screen.dart';
import 'classes_dashboard_screen.dart';
import 'attendance_children_screen.dart';
import 'children_attendance_report_screen.dart';
import 'generic_kinds_screen.dart';
import 'expenses_kpi_screen.dart';
import 'debts_screen.dart';
import 'debt_kpi_screen.dart';
import 'installment_calendar_screen.dart';
import 'bus_line_children_screen.dart';
import 'bus_lines_management_screen.dart';


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

  // ═══════════════════════════════════════════════════════
  // Screen Routes Map - بدل الـ Switch الطويل
  // ═══════════════════════════════════════════════════════
  late final Map<String, Widget Function()> _screenRoutes = {
    // شئون الأطفال
    'frm_Child': () => const ChildrenListScreen(),
    //'frm_FullSearch': () => const ChildrenListScreen(),
    'frm_ChildNew': () => const ChildFormScreen(),
    'frmClassesDashboard':()=>const ClassesDashboardScreen(),
    'frm_absenseChild':()=>const AttendanceChildrenScreen(),

    // الموارد البشرية
    'Employee List': () => const EmployeesListScreen(),
    'frm_EmployeeDetails': () => const EmployeeFormScreen(),
    'frm_absenseEmp': () => const EmployeeAttendanceScreen(),
    'frm_eshraf': () => AddEshrafScreen(),
    'frm_eshrafOnly' : () => AddEshrafOnlyScreen(),
    'frm_AllEshraf' : () => EshrafHistoryScreen(),
    'frmInteractions' : () => const UnifiedInteractionsScreen(),

    // إدارة العملاء CRM
    'frmCRMDashboard': () => const CRMDashboardScreen(),
    'frmAddLeads': () => const AddLeadScreen(),
    'frmLeads': () => const LeadsListScreen(),
    'frmAddTask': () => const AddTaskScreen(),
    'frmTasksList': () => const TasksListScreen(),
    'frmAddCustomer': () =>  AddCustomerScreen(),
    'CRM KPI':() => CRMKPIDashboardScreen(),
    'frmCustomer' : ()=> CustomersListScreen(),

    // المصروفات
    'frm_expenses': () => const ExpensesListScreen(),
    'frm_tbl_expenses': () => const ExpensesListScreen(),
    'frm_expSingle': () => const AddExpenseScreen(),
    'ExpensesKPI':()=>const ExpensesKPIScreen(),
    'frm_expenseKindEdite':()=> const GenericKindsScreen(isIncome: false),

    //الايرادات

    'frm_MonthlySubscrip': () => const SubscriptionPaymentScreen(type: SubscriptionType.study),
    'frm_IncomBus': () => const SubscriptionPaymentScreen(type: SubscriptionType.bus),
    'frm_income':()=>const GeneralIncomeScreen(),
    'frmListIncome':()=>const AllIncomesScreen(),
    'IncomeKPI':()=>const IncomeKpiScreen(),
    'frm_incomeKindEdite':()=> const GenericKindsScreen(isIncome: true),
    'frm_PaymentCHildAll':()=>const DebtsScreen(),
    'DebetsKPI':()=>const  AdvancedKPIScreen(),
    'frm_payment':()=> const InstallmentCalendarScreen (),

    // التقارير
    'rpt_absenseChild':()=>const ChildrenAttendanceReportScreen(),
    
    //الباص
    'frm_Qbuslines': () => const BusLineChildrenScreen(),
    'frm_BusLines': () => const BusLinesManagementScreen(),
  };

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
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════════
          // App Bar - محسّن
          // ═══════════════════════════════════════════════════════
          _buildSliverAppBar(isDark),

          // ═══════════════════════════════════════════════════════
          // Screens Grid - محسّن
          // ═══════════════════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final screen = availableScreens[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildScreenCard(
                      screen: screen,
                      isDark: isDark,
                      index: index,
                    ),
                  );
                },
                childCount: availableScreens.length,
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Sliver App Bar - نظيف بدون عدد الشاشات
  // ═══════════════════════════════════════════════════════
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
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

              // Content - بدون عدد الشاشات
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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle فقط - بدون العدد
                    Text(
                      widget.section.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
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

  // ═══════════════════════════════════════════════════════
  // Screen Card - Modern Gradient Design
  // ═══════════════════════════════════════════════════════
  Widget _buildScreenCard({
    required SubScreen screen,
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
          _navigateToScreen(screen.formName);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            border: Border.all(
              color: widget.section.gradient[0].withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.section.gradient[0].withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background decoration circle
                Positioned(
                  right: -25,
                  top: -25,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.section.gradient[0].withOpacity(0.12),
                          widget.section.gradient[1].withOpacity(0.04),
                        ],
                      ),
                    ),
                  ),
                ),

                // Small accent circle
                Positioned(
                  left: -15,
                  bottom: 30,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.section.gradient[1].withOpacity(0.08),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with gradient and glow
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.section.gradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.section.gradient[0].withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          screen.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        screen.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 14),

                      // Bottom row
                      Row(
                        children: [
                          // "فتح" badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.section.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "فتح",
                              style: TextStyle(
                                color: widget.section.gradient[0],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Arrow icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.section.gradient[0].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: widget.section.gradient[0],
                              size: 14,
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

  // ═══════════════════════════════════════════════════════
  // Navigation - باستخدام Map بدل Switch
  // ═══════════════════════════════════════════════════════
  void _navigateToScreen(String formName) {
    final screenBuilder = _screenRoutes[formName];

    if (screenBuilder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenBuilder()),
      );
    } else {
      _showComingSoonSnackbar(formName);
    }
  }

  // ═══════════════════════════════════════════════════════
  // Coming Soon Snackbar - محسّن
  // ═══════════════════════════════════════════════════════
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 2),
                  Text(
                    arabicName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
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
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}