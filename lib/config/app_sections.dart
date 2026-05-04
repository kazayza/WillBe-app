import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// تكوين الأقسام والشاشات
/// ═══════════════════════════════════════════════════════════════════════════

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎨 الألوان
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppColors {
  // Primary Gradients
  static const primaryGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const successGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const warningGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const dangerGradient = [Color(0xFFEF4444), Color(0xFFDC2626)];

  // Section Colors
  static const childrenColor = Color(0xFFFF6B6B);
  static const hrColor = Color(0xFF4FACFE);
  static const accountsColor = Color(0xFF10B981);
  static const reportsColor = Color(0xFF8B5CF6);
  static const busColor = Color(0xFFF59E0B);
  static const settingsColor = Color(0xFF6B7280);

  // Gradients for sections
  static const childrenGradient = [Color(0xFFFF6B6B), Color(0xFFFF8E53)];
  static const hrGradient = [Color(0xFF4FACFE), Color(0xFF00F2FE)];
  static const incomeGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const expenseGradient = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const reportsGradient = [Color(0xFF8B5CF6), Color(0xFFA855F7)];
  static const busGradient = [Color(0xFFF59E0B), Color(0xFFFBBF24)];
  static const settingsGradient = [Color(0xFF6B7280), Color(0xFF9CA3AF)];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📱 الشاشات الفرعية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SubScreen {
  final String formName; // اسم الشاشة في قاعدة البيانات
  final String title; // العنوان بالعربي
  final IconData icon;
  final String? routeName; // اسم الـ Route لو موجود

  const SubScreen({
    required this.formName,
    required this.title,
    required this.icon,
    this.routeName,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📂 الأقسام الرئيسية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppSection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<SubScreen> screens;
  final List<String> permissionKeys; // أسماء الشاشات للتحقق من الصلاحية

  const AppSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.screens,
    required this.permissionKeys,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📋 تعريف الأقسام
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppSections {
  // ═══════════════════════════════════════════════════════════════
  // 👶 شئون الأطفال
  // ═══════════════════════════════════════════════════════════════
  static const children = AppSection(
    id: 'children',
    title: 'شئون الأطفال',
    subtitle: 'إدارة بيانات الأطفال والاشتراكات',
    icon: Icons.child_care_rounded,
    gradient: AppColors.childrenGradient,
    permissionKeys: [
      'frm_Child',
      'frm_ChildNew',
      //'frm_FullSearch',
      'frm_absenseChild',
      'frmClassesDashboard',
      'frm_ChildIncome',
    ],
    screens: [
      //SubScreen(
        //formName: 'frm_FullSearch',
        //title: 'بحث عن الأطفال',
        //icon: Icons.search_rounded,
      //),
      SubScreen(
        formName: 'frm_ChildNew',
        title: 'تسجيل طفل جديد',
        icon: Icons.person_add_rounded,
      ),
      SubScreen(
        formName: 'frm_Child',
        title: 'قائمة الأطفال',
        icon: Icons.people_rounded,
      ),
      SubScreen(
        formName: 'frmClassesDashboard',
        title: 'إدارة الفصول',
        icon: Icons.class_rounded,
      ),
      SubScreen(
        formName: 'frm_absenseChild',
        title: 'غياب الأطفال',
        icon: Icons.event_busy_rounded,
      ),
      SubScreen(
        formName: 'frm_ChildIncome',
        title: 'اشتراكات الاطفال',
       icon: Icons.receipt_long_rounded,
      ),
      //SubScreen(
        //formName: 'frm_QChildExport',
        //title: 'استعلام الأطفال',
        //icon: Icons.file_download_rounded,
      //),
      //SubScreen(
        //formName: 'frm_import',
        //title: 'استيراد البيانات',
        //icon: Icons.upload_file_rounded,
      //),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 👥 الموارد البشرية
  // ═══════════════════════════════════════════════════════════════
  static const hr = AppSection(
    id: 'hr',
    title: 'الموارد البشرية',
    subtitle: 'إدارة الموظفين والحضور والمرتبات',
    icon: Icons.groups_rounded,
    gradient: AppColors.hrGradient,
    permissionKeys: [
      'Employee List',
      'frm_absenseEmp',
      'frm_eshraf',
      'frm_AllEshraf',
      'frm_eshrafOnly',
    ],
    screens: [
      SubScreen(
        formName: 'Employee List',
        title: 'قائمة الموظفين',
        icon: Icons.people_rounded,
      ),
      
      SubScreen(
        formName: 'frm_absenseEmp',
        title: 'الحضور والانصراف',
        icon: Icons.fingerprint_rounded,
      ),
        SubScreen(
      formName: 'frm_eshraf',
      title: 'الجزاءات والمكافآت',
      icon: Icons.account_balance_wallet_outlined,
      ),
        SubScreen(
        formName: 'frm_eshrafOnly',
        title: 'الإشراف',
        icon: Icons.supervisor_account_rounded,
      ),
      SubScreen(
        formName: 'frm_AllEshraf',
        title: 'إشراف الموارد البشرية',
        icon: Icons.admin_panel_settings_rounded,
      ),

    ],
  );

    // ═══════════════════════════════════════════════════════════════════════════
  // 🤝 إدارة العملاء (CRM)
  // ═══════════════════════════════════════════════════════════════════════════
  static const customers = AppSection(
    id: 'customers',
    title: 'إدارة العملاء (CRM)',
    subtitle: 'متابعة العملاء، المهام، والتواصلات',
    icon: Icons.handshake_rounded,
    // لون مميز للـ CRM (بنفسجي متدرج)
    gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 
    
    // مفاتيح الصلاحيات (لو الموظف عنده أي واحدة منهم يشوف القسم)
    permissionKeys: [
      'frmCRMDashboard',
      'frmLeads',
      'frmCustomer',
      'frmTasksList',
    ],
    
    screens: [
      SubScreen(
        formName: 'frmCRMDashboard',
        title: 'لوحة تحكم العملاء',
        icon: Icons.dashboard_customize_rounded,
      ),
      SubScreen(
        formName: 'CRM KPI',
        title: 'مؤشرات أداء إدارة العملاء',
        icon: Icons.person_pin,
      ),
      SubScreen(
        formName: 'frmLeads',
        title: 'العملاء المحتملين',
        icon: Icons.person_search_rounded,
      ),
      //SubScreen(
        //formName: 'frmAddLeads',
        //title: 'إضافة عميل محتمل',
        //icon: Icons.person_add_alt_1_rounded,
      //),
      SubScreen(
        formName: 'frmCustomer',
        title: 'العملاء الفعليين',
        icon: Icons.verified_user_rounded,
      ),
      //SubScreen(
        //formName: 'frmAddCustomer',
        //title: 'إضافة عميل فعلي',
        //icon: Icons.how_to_reg_rounded,
      //),
      SubScreen(
        formName: 'frmTasksList',
        title: 'قائمة المهام',
        icon: Icons.checklist_rtl_rounded,
      ),
      SubScreen(
        formName: 'frmAddTask',
        title: 'إضافة مهمة جديدة',
        icon: Icons.add_task_rounded,
      ),
      SubScreen(
        formName: 'frmInteractions',
        title: 'سجل التواصلات',
        icon: Icons.phone_in_talk_rounded,
      ),
    ],
  );


  // ═══════════════════════════════════════════════════════════════
  // 💰 الحسابات - الإيرادات
  // ═══════════════════════════════════════════════════════════════
  static const income = AppSection(
    id: 'income',
    title: 'الإيرادات',
    subtitle: 'إدارة الإيرادات والاشتراكات',
    icon: Icons.trending_up_rounded,
    gradient: AppColors.incomeGradient,
    permissionKeys: [
      'frm_income',
      'frm_MonthlySubscrip',
      'IncomeKPI',
      'frmListIncome',
      'frm_incomeKindEdite',
      'frm_PaymentCHildAll',
      'DebetsKPI',
      'frm_payment',
      'frm_IncomBus',
    ],
    screens: [
      
      SubScreen(
        formName: 'IncomeKPI',
        title: 'مؤشرات أداء الإيرادات',
        icon: Icons.analytics,
      ),
      SubScreen(
        formName: 'DebetsKPI',
        title: 'مؤشرات أداء المديونيات',
        icon: Icons.analytics,
      ),
      SubScreen(
        formName: 'frmListIncome',
        title: 'كافة الإيرادات',
        icon: Icons.attach_money_rounded,
      ),
      SubScreen(
        formName: 'frm_income',
        title: 'إضافة إيراد',
        icon: Icons.attach_money_rounded,
      ),
      SubScreen(
        formName: 'frm_MonthlySubscrip',
        title: 'اشتراك العام الدراسي',
        icon: Icons.school_rounded,
      ),
      SubScreen(
        formName: 'frm_IncomBus',
        title: 'اشتراك الباص',
        icon: Icons.directions_bus_rounded,
      ),
      //SubScreen(
        //formName: 'frm_reportincomeDetalis',
        //title: 'استعلام الإيرادات',
        //icon: Icons.search_rounded,
      //),
      SubScreen(
        formName: 'frm_incomMoragaa',
        title: 'مراجعة الإيرادات',
        icon: Icons.fact_check_rounded,
      ),
      SubScreen(
        formName: 'frm_incomeKindEdite',
        title: 'بنود الإيرادات',
        icon: Icons.edit_rounded,
      ),
      SubScreen(
        formName: 'frm_payment',
        title: 'الأقساط الشهرية',
        icon: Icons.calendar_month_rounded,
      ),
      SubScreen(
        formName: 'frm_PaymentCHildAll',
        title: 'المديونيات والاقساط',
        icon: Icons.warning_rounded,
      ),
      //SubScreen(
        //formName: 'frm_NullIncome',
        //title: 'أخطاء الإيرادات',
        //icon: Icons.error_outline_rounded,
      //),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 💸 الحسابات - المصروفات
  // ═══════════════════════════════════════════════════════════════
  static const expenses = AppSection(
    id: 'expenses',
    title: 'المصروفات',
    subtitle: 'إدارة المصروفات والنفقات',
    icon: Icons.trending_down_rounded,
    gradient: AppColors.expenseGradient,
    permissionKeys: [
      'frm_expenses',
      'frm_expSingle',
      'frm_salary',
      'frm_expenseKindEdite',
      'ExpensesKPI',
    ],
    screens: [
      //ExpensesKPI
      SubScreen(
        formName: 'ExpensesKPI',
        title: 'مؤشر أداء المصروفات',
        icon: Icons.analytics,
      ),      
      SubScreen(
        formName: 'frm_expenses',
        title: 'المصروفات',
        icon: Icons.money_off_rounded,
      ),
      SubScreen(
        formName: 'frm_expSingle',
        title: 'إضافة مصروف فردي',
        icon: Icons.add_circle_rounded,
      ),
      SubScreen(
        formName: 'frm_salary',
        title: 'المرتبات',
        icon: Icons.payments_rounded,
      ),
      //SubScreen(
        //formName: 'frm_expenseKindEdite',
        //title: 'استعلام المصروفات',
        //icon: Icons.search_rounded,
      //),
      //SubScreen(
        //formName: 'frm_moragaaExpense',
        //title: 'مراجعة المصروفات',
//        icon: Icons.fact_check_rounded,
      //),
      SubScreen(
        formName: 'frm_expenseKindEdite',
        title: 'بنود المصروفات',
        icon: Icons.edit_rounded,
      ),
      //SubScreen(
        //formName: 'frm_expenseNOUR1',
        //title: 'كافة المصروفات',
        //icon: Icons.list_alt_rounded,
      //),
      //SubScreen(
        //formName: 'frm_ExpenseChart',
        //title: 'مخطط بياني',
//        icon: Icons.pie_chart_rounded,
      //),
      //SubScreen(
        //formName: 'frm_NullExpenses',
        //title: 'أخطاء المصروفات',
      //  icon: Icons.error_outline_rounded,
      //),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 📈 التقارير والإحصائيات
  // ═══════════════════════════════════════════════════════════════
  static const reports = AppSection(
    id: 'reports',
    title: 'التقارير',
    subtitle: 'التقارير والإحصائيات والمقارنات',
    icon: Icons.analytics_rounded,
    gradient: AppColors.reportsGradient,
    permissionKeys: [
      'frm_administrator',
      'frm_QaemaMarkazMaly',
      'rpt_absenseChild',
      'frm_reportincomeDetalis',
      'frm_KindIncomeChild',
      'frm_qrysalary',
    ],
    screens: [
      //SubScreen(
        //formName: 'frm_administrator',
        //title: 'إحصائيات الإدارة',
        //icon: Icons.dashboard_rounded,
      //),
      SubScreen(
        formName: 'frm_QaemaMarkazMaly',
        title: 'المركز المالي',
        icon: Icons.account_balance_rounded,
      ),
      SubScreen(
        formName: 'frm_QryArsedaChild',
        title: 'متابعة الأرصدة',
        icon: Icons.account_balance_wallet_rounded,
      ),
      SubScreen(
        formName: 'rpt_absenseChild',
        title: 'غياب الأطفال',
        icon: Icons.assignment_ind_rounded,
      ),
      SubScreen(
        formName: 'frm_reportincomeDetalis',
        title: 'استعلام الإيرادات',
        icon: Icons.search_rounded,
      ),
      SubScreen(
        formName: 'frm_KindIncomeChild',
        title: 'اشتراك معين لطفل',
        icon: Icons.account_balance_wallet_rounded,
      ),

        SubScreen(
          formName: 'frm_qrysalary',
          title: 'استعلام المرتبات',
          icon: Icons.payments_rounded,
        ),
      //SubScreen(
       // formName: 'frm_QQuery2Plus1',
       // title: 'الطلبة المدينين',
       // icon: Icons.warning_amber_rounded,
      //),
      //SubScreen(
        //formName: 'frm_QFinanceChildBySesson',
        //title: 'أعداد الأطفال بالعام',
       // icon: Icons.people_outline_rounded,
      //),
      //SubScreen(
       // formName: 'ComparExpenseMonthOverMonth',
       // title: 'مقارنة المصروفات شهرياً',
       // icon: Icons.compare_arrows_rounded,
      //),
      //SubScreen(
        //formName: 'ComparExpensesMonthOverYear',
        //title: 'مقارنة المصروفات سنوياً',
       // icon: Icons.compare_rounded,
      //),
      //SubScreen(
       // formName: 'ComparincomeMonthOverYear',
        //title: 'مقارنة الإيرادات سنوياً',
        //icon: Icons.trending_up_rounded,
      //),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 🚌 الباص
  // ═══════════════════════════════════════════════════════════════
  static const bus = AppSection(
    id: 'bus',
    title: 'الباص',
    subtitle: 'إدارة خطوط واشتراكات الباص',
    icon: Icons.directions_bus_rounded,
    gradient: AppColors.busGradient,
    permissionKeys: [
      'frm_BusRegestration',
      'frm_BusLines',
      'frm_Qbuslines'
    ],
    screens: [
      //SubScreen(
        //formName: 'frm_BusRegestration',
        //title: 'تسجيل اشتراكات الباص',
        //icon: Icons.app_registration_rounded,
      //),
      SubScreen(
        formName: 'frm_Qbuslines',
        title: 'خطوط سير الباص',
        icon: Icons.route_rounded,
      ),
      SubScreen(
        formName: 'frm_BusLines',
        title: 'أسماء خطوط السير',
        icon: Icons.edit_road_rounded,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ الإعدادات
  // ═══════════════════════════════════════════════════════════════
  static const settings = AppSection(
    id: 'settings',
    title: 'الإعدادات',
    subtitle: 'إعدادات النظام والمستخدمين',
    icon: Icons.settings_rounded,
    gradient: AppColors.settingsGradient,
    permissionKeys: [
      'frm_users',
      'frm_company',
    ],
    screens: [
      SubScreen(
        formName: 'frm_users',
        title: 'المستخدمين',
        icon: Icons.manage_accounts_rounded,
      ),
      SubScreen(
        formName: 'frm_company',
        title: 'بيانات الحضانة',
        icon: Icons.business_rounded,
      ),
      SubScreen(
        formName: 'frm_Managment',
        title: 'الإدارات',
        icon: Icons.account_tree_rounded,
      ),
      SubScreen(
        formName: 'frm_salesPolo',
        title: 'مبيعات التيشيرتات',
        icon: Icons.checkroom_rounded,
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // 📋 قائمة كل الأقسام
  // ═══════════════════════════════════════════════════════════════
  static const List<AppSection> all = [
    children,
    hr,
    customers,
    income,
    expenses,
    reports,
    bus,
    settings,
  ];

  // ═══════════════════════════════════════════════════════════════
  // ⚡ الوصول السريع (Quick Actions)
  // ═══════════════════════════════════════════════════════════════
  static const List<QuickAction> quickActions = [
    QuickAction(
      id: 'search_child',
      title: 'بحث',
      icon: Icons.search_rounded,
      formName:'frm_Child',
      //formName: 'frm_FullSearch',
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    ),
    QuickAction(
      id: 'add_child',
      title: 'طفل جديد',
      icon: Icons.person_add_rounded,
      formName: 'frm_ChildNew',
      gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    ),
    QuickAction(
      id: 'attendance',
      title: 'الحضور',
      icon: Icons.fingerprint_rounded,
      formName: 'frm_absenseEmp',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    QuickAction(
      id: 'add_expense',
      title: 'مصروف',
      icon: Icons.remove_circle_rounded,
      formName: 'frm_expSingle',
      gradient: [Color(0xFFEF4444), Color(0xFFF87171)],
    ),
    QuickAction(
      id: 'add_income',
      title: 'إيراد',
      icon: Icons.add_circle_rounded,
      formName: 'frm_income',
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    QuickAction(
      id: 'reports',
      title: 'التقارير',
      icon: Icons.analytics_rounded,
      formName: 'frm_administrator',
      gradient: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    ),
    QuickAction(
      id: 'employees',
      title: 'الموظفين',
      icon: Icons.groups_rounded,
      formName: 'Employee List',
      gradient: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    ),
    QuickAction(
      id: 'salary',
      title: 'المرتبات',
      icon: Icons.payments_rounded,
      formName: 'frm_salary',
      gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
  ];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⚡ Quick Action Model
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class QuickAction {
  final String id;
  final String title;
  final IconData icon;
  final String formName;
  final List<Color> gradient;

  const QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.formName,
    required this.gradient,
  });
}