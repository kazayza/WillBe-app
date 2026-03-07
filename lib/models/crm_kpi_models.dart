// ═══════════════════════════════════════════════════════════════════════════
// 📊 CRM KPI Dashboard Models
// ═══════════════════════════════════════════════════════════════════════════

// ==================== DASHBOARD SUMMARY ====================
class CRMDashboardData {
  final LeadsSummary leads;
  final CustomersSummary customers;
  final FollowUpsSummary followUps;
  final InteractionsSummary interactions;

  CRMDashboardData({
    required this.leads,
    required this.customers,
    required this.followUps,
    required this.interactions,
  });

  factory CRMDashboardData.fromJson(Map<String, dynamic> json) {
    return CRMDashboardData(
      leads: LeadsSummary.fromJson(json['leads'] ?? {}),
      customers: CustomersSummary.fromJson(json['customers'] ?? {}),
      followUps: FollowUpsSummary.fromJson(json['followUps'] ?? {}),
      interactions: InteractionsSummary.fromJson(json['interactions'] ?? {}),
    );
  }

  factory CRMDashboardData.empty() {
    return CRMDashboardData(
      leads: LeadsSummary.empty(),
      customers: CustomersSummary.empty(),
      followUps: FollowUpsSummary.empty(),
      interactions: InteractionsSummary.empty(),
    );
  }
}

// ==================== LEADS SUMMARY ====================
class LeadsSummary {
  final int total;
  final int newLeads;
  final int contacted;
  final int interested;
  final int converted;
  final int lost;
  final int followUp;
  final double conversionRate;

  LeadsSummary({
    required this.total,
    required this.newLeads,
    required this.contacted,
    required this.interested,
    required this.converted,
    required this.lost,
    required this.followUp,
    required this.conversionRate,
  });

  factory LeadsSummary.fromJson(Map<String, dynamic> json) {
    return LeadsSummary(
      total: json['total'] ?? 0,
      newLeads: json['new'] ?? 0,
      contacted: json['contacted'] ?? 0,
      interested: json['interested'] ?? 0,
      converted: json['converted'] ?? 0,
      lost: json['lost'] ?? 0,
      followUp: json['followUp'] ?? 0,
      conversionRate: _parseDouble(json['conversionRate']),
    );
  }

  factory LeadsSummary.empty() {
    return LeadsSummary(
      total: 0,
      newLeads: 0,
      contacted: 0,
      interested: 0,
      converted: 0,
      lost: 0,
      followUp: 0,
      conversionRate: 0.0,
    );
  }
}

// ==================== CUSTOMERS SUMMARY ====================
class CustomersSummary {
  final int total;
  final int active;
  final int inactive;

  CustomersSummary({
    required this.total,
    required this.active,
    required this.inactive,
  });

  factory CustomersSummary.fromJson(Map<String, dynamic> json) {
    return CustomersSummary(
      total: json['TotalCustomers'] ?? 0,
      active: json['ActiveCustomers'] ?? 0,
      inactive: json['InactiveCustomers'] ?? 0,
    );
  }

  factory CustomersSummary.empty() {
    return CustomersSummary(total: 0, active: 0, inactive: 0);
  }
}

// ==================== FOLLOW UPS SUMMARY ====================
class FollowUpsSummary {
  final int overdue;
  final int today;

  FollowUpsSummary({
    required this.overdue,
    required this.today,
  });

  factory FollowUpsSummary.fromJson(Map<String, dynamic> json) {
    return FollowUpsSummary(
      overdue: json['overdue'] ?? 0,
      today: json['today'] ?? 0,
    );
  }

  factory FollowUpsSummary.empty() {
    return FollowUpsSummary(overdue: 0, today: 0);
  }

  // هل فيه متابعات متأخرة؟
  bool get hasOverdue => overdue > 0;
  
  // إجمالي المتابعات المطلوبة
  int get totalPending => overdue + today;
}

// ==================== INTERACTIONS SUMMARY ====================
class InteractionsSummary {
  final int total;
  final int calls;
  final int whatsApp;
  final int visits;
  final int emails;

  InteractionsSummary({
    required this.total,
    required this.calls,
    required this.whatsApp,
    required this.visits,
    required this.emails,
  });

  factory InteractionsSummary.fromJson(Map<String, dynamic> json) {
    return InteractionsSummary(
      total: json['TotalInteractions'] ?? 0,
      calls: json['Calls'] ?? 0,
      whatsApp: json['WhatsApp'] ?? 0,
      visits: json['Visits'] ?? 0,
      emails: json['Emails'] ?? 0,
    );
  }

  factory InteractionsSummary.empty() {
    return InteractionsSummary(
      total: 0,
      calls: 0,
      whatsApp: 0,
      visits: 0,
      emails: 0,
    );
  }
}

// ==================== SOURCE PERFORMANCE ====================
class SourcePerformance {
  final String name;
  final String? color;
  final int totalLeads;
  final int convertedLeads;
  final int lostLeads;
  final double conversionRate;

  SourcePerformance({
    required this.name,
    this.color,
    required this.totalLeads,
    required this.convertedLeads,
    required this.lostLeads,
    required this.conversionRate,
  });

  factory SourcePerformance.fromJson(Map<String, dynamic> json) {
    return SourcePerformance(
      name: json['SourceName'] ?? 'Unknown',
      color: json['SourceColor'],
      totalLeads: json['TotalLeads'] ?? 0,
      convertedLeads: json['ConvertedLeads'] ?? 0,
      lostLeads: json['LostLeads'] ?? 0,
      conversionRate: _parseDouble(json['ConversionRate']),
    );
  }

  // هل المصدر فعال؟ (معدل تحويل > 20%)
  bool get isEffective => conversionRate >= 20;
}

// ==================== EMPLOYEE PERFORMANCE ====================
class EmployeePerformance {
  final int id;
  final String name;
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int convertedLeads;
  final int lostLeads;
  final double conversionRate;
  final int totalInteractions;

  EmployeePerformance({
    required this.id,
    required this.name,
    required this.totalLeads,
    required this.newLeads,
    required this.contactedLeads,
    required this.convertedLeads,
    required this.lostLeads,
    required this.conversionRate,
    required this.totalInteractions,
  });

  factory EmployeePerformance.fromJson(Map<String, dynamic> json) {
    return EmployeePerformance(
      id: json['EmployeeId'] ?? 0,
      name: json['EmployeeName'] ?? 'Unknown',
      totalLeads: json['TotalLeads'] ?? 0,
      newLeads: json['NewLeads'] ?? 0,
      contactedLeads: json['ContactedLeads'] ?? 0,
      convertedLeads: json['ConvertedLeads'] ?? 0,
      lostLeads: json['LostLeads'] ?? 0,
      conversionRate: _parseDouble(json['ConversionRate']),
      totalInteractions: json['TotalInteractions'] ?? 0,
    );
  }

  // أول حرف من الاسم للـ Avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // تقييم الأداء
  String get performanceLevel {
    if (conversionRate >= 50) return 'Excellent';
    if (conversionRate >= 30) return 'Good';
    if (conversionRate >= 15) return 'Average';
    return 'Needs Improvement';
  }
}

// ==================== PERIOD STATS ====================
class PeriodStats {
  final String period;
  final int totalLeads;
  final int convertedLeads;

  PeriodStats({
    required this.period,
    required this.totalLeads,
    required this.convertedLeads,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      period: json['Period'] ?? '',
      totalLeads: json['TotalLeads'] ?? 0,
      convertedLeads: json['ConvertedLeads'] ?? 0,
    );
  }

  // معدل التحويل لهذه الفترة
  double get conversionRate {
    if (totalLeads == 0) return 0;
    return (convertedLeads / totalLeads) * 100;
  }
}

// ==================== BRANCH ====================
class Branch {
  final int id;
  final String name;

  Branch({
    required this.id,
    required this.name,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['IDbranch'] ?? json['id'] ?? 0,
      name: json['branchName'] ?? json['name'] ?? '',
    );
  }
}

// ==================== ENUMS ====================
enum DashboardStatus { initial, loading, loaded, error }
enum PeriodType { daily, weekly, monthly }

// ==================== HELPER ====================
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}