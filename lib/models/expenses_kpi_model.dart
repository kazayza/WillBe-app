// ════════════════════════════════════════════════════════════
// 📊 نموذج مؤشرات أداء المصروفات الكامل
// ════════════════════════════════════════════════════════════

class ExpensesKPIModel {
  final DateRanges dates;
  final Summary summary;
  final Forecast forecast;
  final AdvancedMetrics advanced;
  final List<GroupData> groupsData;
  final List<GroupDistribution> groupDistribution;
  final List<BranchData> branchesData;
  final List<Top5Expense> top5Expenses;
  final List<TopIncrease> topIncreases;
  final List<TopSaving> topSavings;
  final Charts charts;
  final List<Insight> insights;
  final FinancialAnalysis financialAnalysis;

  ExpensesKPIModel({
    required this.dates,
    required this.summary,
    required this.forecast,
    required this.advanced,
    required this.groupsData,
    required this.groupDistribution,
    required this.branchesData,
    required this.top5Expenses,
    required this.topIncreases,
    required this.topSavings,
    required this.charts,
    required this.insights,
    required this.financialAnalysis,
  });

  factory ExpensesKPIModel.fromJson(Map<String, dynamic> json) {
    return ExpensesKPIModel(
      dates: DateRanges.fromJson(json['dates'] ?? {}),
      summary: Summary.fromJson(json['summary'] ?? {}),
      forecast: Forecast.fromJson(json['forecast'] ?? {}),
      advanced: AdvancedMetrics.fromJson(json['advanced'] ?? {}),
      groupsData: (json['groupsData'] as List? ?? [])
          .map((e) => GroupData.fromJson(e))
          .toList(),
      groupDistribution: (json['groupDistribution'] as List? ?? [])
          .map((e) => GroupDistribution.fromJson(e))
          .toList(),
      branchesData: (json['branchesData'] as List? ?? [])
          .map((e) => BranchData.fromJson(e))
          .toList(),
      top5Expenses: (json['top5Expenses'] as List? ?? [])
          .map((e) => Top5Expense.fromJson(e))
          .toList(),
      topIncreases: (json['topIncreases'] as List? ?? [])
          .map((e) => TopIncrease.fromJson(e))
          .toList(),
      topSavings: (json['topSavings'] as List? ?? [])
          .map((e) => TopSaving.fromJson(e))
          .toList(),
      charts: Charts.fromJson(json['charts'] ?? {}),
      insights: (json['insights'] as List? ?? [])
          .map((e) => Insight.fromJson(e))
          .toList(),
      financialAnalysis:
          FinancialAnalysis.fromJson(json['financialAnalysis'] ?? {}),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 📅 الفترات الزمنية
// ════════════════════════════════════════════════════════════

class DateRanges {
  final PeriodRange current;
  final PeriodRange previous;
  final PeriodRange lastYear;
  final PeriodMeta meta;

  DateRanges({
    required this.current,
    required this.previous,
    required this.lastYear,
    required this.meta,
  });

  factory DateRanges.fromJson(Map<String, dynamic> json) {
    return DateRanges(
      current: PeriodRange.fromJson(json['current'] ?? {}),
      previous: PeriodRange.fromJson(json['previous'] ?? {}),
      lastYear: PeriodRange.fromJson(json['lastYear'] ?? {}),
      meta: PeriodMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class PeriodRange {
  final DateTime? start;
  final DateTime? end;
  final int days;

  PeriodRange({
    this.start,
    this.end,
    required this.days,
  });

  factory PeriodRange.fromJson(Map<String, dynamic> json) {
    return PeriodRange(
      start: json['start'] != null ? DateTime.tryParse(json['start'].toString()) : null,
      end: json['end'] != null ? DateTime.tryParse(json['end'].toString()) : null,
      days: json['days'] ?? 0,
    );
  }
}

class PeriodMeta {
  final String periodType;
  final bool fairComparison;

  PeriodMeta({
    required this.periodType,
    required this.fairComparison,
  });

  factory PeriodMeta.fromJson(Map<String, dynamic> json) {
    return PeriodMeta(
      periodType: json['periodType'] ?? 'month',
      fairComparison: json['fairComparison'] ?? true,
    );
  }
}

// ════════════════════════════════════════════════════════════
// 📊 الملخص العام
// ════════════════════════════════════════════════════════════

class Summary {
  final double totalCurrent;
  final ComparisonData vsPrevious;
  final ComparisonData vsLastYear;

  Summary({
    required this.totalCurrent,
    required this.vsPrevious,
    required this.vsLastYear,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalCurrent: (json['totalCurrent'] ?? 0).toDouble(),
      vsPrevious: ComparisonData.fromJson(json['vsPrevious'] ?? {}),
      vsLastYear: ComparisonData.fromJson(json['vsLastYear'] ?? {}),
    );
  }
}

class ComparisonData {
  final double total;
  final double diff;
  final double percent;
  final String trend;

  ComparisonData({
    required this.total,
    required this.diff,
    required this.percent,
    required this.trend,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      total: (json['total'] ?? 0).toDouble(),
      diff: (json['diff'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'up',
    );
  }

  bool get isUp => trend == 'up';
  bool get isDown => trend == 'down';
}

// ════════════════════════════════════════════════════════════
// 🔮 التوقعات
// ════════════════════════════════════════════════════════════

class Forecast {
  final double totalSoFar;
  final double dailyAverage;
  final double projectedTotal;
  final int daysElapsed;
  final int daysRemaining;
  final int daysInMonth;

  Forecast({
    required this.totalSoFar,
    required this.dailyAverage,
    required this.projectedTotal,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.daysInMonth,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      totalSoFar: (json['totalSoFar'] ?? 0).toDouble(),
      dailyAverage: (json['dailyAverage'] ?? 0).toDouble(),
      projectedTotal: (json['projectedTotal'] ?? 0).toDouble(),
      daysElapsed: json['daysElapsed'] ?? 0,
      daysRemaining: json['daysRemaining'] ?? 0,
      daysInMonth: json['daysInMonth'] ?? 30,
    );
  }

  double get progressPercent =>
      daysInMonth > 0 ? (daysElapsed / daysInMonth) * 100 : 0;
}

// ════════════════════════════════════════════════════════════
// 📈 المؤشرات المتقدمة
// ════════════════════════════════════════════════════════════

class AdvancedMetrics {
  final double avgPerTransaction;
  final double maxSingleExpense;
  final double minSingleExpense;
  final int totalTransactions;
  final int activeDays;
  final double stdDeviation;
  final MostFrequentKind? mostFrequentKind;

  AdvancedMetrics({
    required this.avgPerTransaction,
    required this.maxSingleExpense,
    required this.minSingleExpense,
    required this.totalTransactions,
    required this.activeDays,
    required this.stdDeviation,
    this.mostFrequentKind,
  });

  factory AdvancedMetrics.fromJson(Map<String, dynamic> json) {
    return AdvancedMetrics(
      avgPerTransaction: (json['avgPerTransaction'] ?? 0).toDouble(),
      maxSingleExpense: (json['maxSingleExpense'] ?? 0).toDouble(),
      minSingleExpense: (json['minSingleExpense'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      activeDays: json['activeDays'] ?? 0,
      stdDeviation: (json['stdDeviation'] ?? 0).toDouble(),
      mostFrequentKind: json['mostFrequentKind'] != null
          ? MostFrequentKind.fromJson(json['mostFrequentKind'])
          : null,
    );
  }
}

class MostFrequentKind {
  final String name;
  final int count;
  final double total;

  MostFrequentKind({
    required this.name,
    required this.count,
    required this.total,
  });

  factory MostFrequentKind.fromJson(Map<String, dynamic> json) {
    return MostFrequentKind(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 📊 بيانات المجموعات
// ════════════════════════════════════════════════════════════

class GroupData {
  final String group;
  final double current;
  final ChangeData vsPrevious;
  final ChangeData vsLastYear;

  GroupData({
    required this.group,
    required this.current,
    required this.vsPrevious,
    required this.vsLastYear,
  });

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      group: json['group'] ?? 'أخرى',
      current: (json['current'] ?? 0).toDouble(),
      vsPrevious: ChangeData.fromJson(json['vsPrevious'] ?? {}),
      vsLastYear: ChangeData.fromJson(json['vsLastYear'] ?? {}),
    );
  }
}

class ChangeData {
  final double amount;
  final double change;

  ChangeData({
    required this.amount,
    required this.change,
  });

  factory ChangeData.fromJson(Map<String, dynamic> json) {
    return ChangeData(
      amount: (json['amount'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
    );
  }

  bool get isIncrease => change > 0;
  bool get isDecrease => change < 0;
}

// ════════════════════════════════════════════════════════════
// 🍩 توزيع المجموعات (Pie Chart)
// ════════════════════════════════════════════════════════════

class GroupDistribution {
  final String group;
  final double amount;
  final double percent;

  GroupDistribution({
    required this.group,
    required this.amount,
    required this.percent,
  });

  factory GroupDistribution.fromJson(Map<String, dynamic> json) {
    return GroupDistribution(
      group: json['group'] ?? 'أخرى',
      amount: (json['amount'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 🏢 بيانات الفروع
// ════════════════════════════════════════════════════════════

class BranchData {
  final String name;
  final double current;
  final double percentOfTotal;
  final ChangeData vsPrevious;
  final ChangeData vsLastYear;

  BranchData({
    required this.name,
    required this.current,
    required this.percentOfTotal,
    required this.vsPrevious,
    required this.vsLastYear,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      name: json['name'] ?? 'غير محدد',
      current: (json['current'] ?? 0).toDouble(),
      percentOfTotal: (json['percentOfTotal'] ?? 0).toDouble(),
      vsPrevious: ChangeData.fromJson(json['vsPrevious'] ?? {}),
      vsLastYear: ChangeData.fromJson(json['vsLastYear'] ?? {}),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 🏆 أعلى 5 بنود
// ════════════════════════════════════════════════════════════

class Top5Expense {
  final String name;
  final String group;
  final double amount;
  final int transactions;
  final double percent;

  Top5Expense({
    required this.name,
    required this.group,
    required this.amount,
    required this.transactions,
    required this.percent,
  });

  factory Top5Expense.fromJson(Map<String, dynamic> json) {
    return Top5Expense(
      name: json['name'] ?? '',
      group: json['group'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
      percent: (json['percent'] ?? 0).toDouble(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 📈 أعلى 5 ارتفاعاً
// ════════════════════════════════════════════════════════════

class TopIncrease {
  final String name;
  final double current;
  final double previous;
  final double change;

  TopIncrease({
    required this.name,
    required this.current,
    required this.previous,
    required this.change,
  });

  factory TopIncrease.fromJson(Map<String, dynamic> json) {
    return TopIncrease(
      name: json['name'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      previous: (json['previous'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 💰 أعلى 5 توفيراً
// ════════════════════════════════════════════════════════════

class TopSaving {
  final String name;
  final double current;
  final double previous;
  final double saved;
  final double savingPercent;

  TopSaving({
    required this.name,
    required this.current,
    required this.previous,
    required this.saved,
    required this.savingPercent,
  });

  factory TopSaving.fromJson(Map<String, dynamic> json) {
    return TopSaving(
      name: json['name'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      previous: (json['previous'] ?? 0).toDouble(),
      saved: (json['saved'] ?? 0).toDouble(),
      savingPercent: (json['savingPercent'] ?? 0).toDouble(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 📉 الرسوم البيانية
// ════════════════════════════════════════════════════════════

class Charts {
  final DailyTrend dailyTrend;
  final List<WeekdayData> weekdayAnalysis;
  final List<SeasonalData> seasonalTrend;

  Charts({
    required this.dailyTrend,
    required this.weekdayAnalysis,
    required this.seasonalTrend,
  });

  factory Charts.fromJson(Map<String, dynamic> json) {
    return Charts(
      dailyTrend: DailyTrend.fromJson(json['dailyTrend'] ?? {}),
      weekdayAnalysis: (json['weekdayAnalysis'] as List? ?? [])
          .map((e) => WeekdayData.fromJson(e))
          .toList(),
      seasonalTrend: (json['seasonalTrend'] as List? ?? [])
          .map((e) => SeasonalData.fromJson(e))
          .toList(),
    );
  }
}

class DailyTrend {
  final List<DailyPoint> current;
  final List<DailyPoint> previous;

  DailyTrend({
    required this.current,
    required this.previous,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      current: (json['current'] as List? ?? [])
          .map((e) => DailyPoint.fromJson(e))
          .toList(),
      previous: (json['previous'] as List? ?? [])
          .map((e) => DailyPoint.fromJson(e))
          .toList(),
    );
  }
}

class DailyPoint {
  final String day;
  final double amount;

  DailyPoint({
    required this.day,
    required this.amount,
  });

  factory DailyPoint.fromJson(Map<String, dynamic> json) {
    return DailyPoint(
      day: json['day'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  DateTime? get date => DateTime.tryParse(day);
}

class WeekdayData {
  final int dayNumber;
  final String dayName;
  final double total;
  final double average;
  final int transactions;

  WeekdayData({
    required this.dayNumber,
    required this.dayName,
    required this.total,
    required this.average,
    required this.transactions,
  });

  factory WeekdayData.fromJson(Map<String, dynamic> json) {
    return WeekdayData(
      dayNumber: json['dayNumber'] ?? 0,
      dayName: json['dayName'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      average: (json['average'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
    );
  }
}

class SeasonalData {
  final String month;
  final String monthName;
  final int year;
  final double total;
  final int transactions;

  SeasonalData({
    required this.month,
    required this.monthName,
    required this.year,
    required this.total,
    required this.transactions,
  });

  factory SeasonalData.fromJson(Map<String, dynamic> json) {
    return SeasonalData(
      month: json['month'] ?? '',
      monthName: json['monthName'] ?? '',
      year: json['year'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
    );
  }
}

// ════════════════════════════════════════════════════════════
// 🚨 التنبيهات الذكية
// ════════════════════════════════════════════════════════════

class Insight {
  final String type;
  final String icon;
  final String title;
  final String message;
  final String priority;

  Insight({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.priority,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'] ?? 'info',
      icon: json['icon'] ?? 'ℹ️',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'low',
    );
  }

  bool get isDanger => type == 'danger';
  bool get isWarning => type == 'warning';
  bool get isSuccess => type == 'success';
  bool get isInfo => type == 'info';
  bool get isHighPriority => priority == 'high';
}

// ════════════════════════════════════════════════════════════
// 📋 التحليل المالي الاحترافي
// ════════════════════════════════════════════════════════════

class FinancialAnalysis {
  final String executiveSummary;
  final List<String> deviationAnalysis;
  final List<String> riskAnalysis;
  final List<String> positivePoints;
  final String forecast;
  final String yearComparison;
  final List<String> recommendations;

  FinancialAnalysis({
    required this.executiveSummary,
    required this.deviationAnalysis,
    required this.riskAnalysis,
    required this.positivePoints,
    required this.forecast,
    required this.yearComparison,
    required this.recommendations,
  });

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysis(
      executiveSummary: json['executiveSummary'] ?? '',
      deviationAnalysis: List<String>.from(json['deviationAnalysis'] ?? []),
      riskAnalysis: List<String>.from(json['riskAnalysis'] ?? []),
      positivePoints: List<String>.from(json['positivePoints'] ?? []),
      forecast: json['forecast'] ?? '',
      yearComparison: json['yearComparison'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 🔽 نموذج الفلاتر المتاحة
// ════════════════════════════════════════════════════════════

class ExpenseFiltersModel {
  final List<FilterBranch> branches;
  final List<FilterGroup> groups;
  final List<FilterKind> kinds;

  ExpenseFiltersModel({
    required this.branches,
    required this.groups,
    required this.kinds,
  });

  factory ExpenseFiltersModel.fromJson(Map<String, dynamic> json) {
    return ExpenseFiltersModel(
      branches: (json['branches'] as List? ?? [])
          .map((e) => FilterBranch.fromJson(e))
          .toList(),
      groups: (json['groups'] as List? ?? [])
          .map((e) => FilterGroup.fromJson(e))
          .toList(),
      kinds: (json['kinds'] as List? ?? [])
          .map((e) => FilterKind.fromJson(e))
          .toList(),
    );
  }
}

class FilterBranch {
  final int id;
  final String name;

  FilterBranch({required this.id, required this.name});

  factory FilterBranch.fromJson(Map<String, dynamic> json) {
    return FilterBranch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class FilterGroup {
  final String name;

  FilterGroup({required this.name});

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      name: json['name'] ?? '',
    );
  }
}

class FilterKind {
  final int id;
  final String name;
  final String groupName;

  FilterKind({
    required this.id,
    required this.name,
    required this.groupName,
  });

  factory FilterKind.fromJson(Map<String, dynamic> json) {
    return FilterKind(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      groupName: json['groupName'] ?? '',
    );
  }
}