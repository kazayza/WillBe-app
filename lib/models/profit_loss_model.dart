class ProfitLossReport {
  final PeriodInfo period;
  final IncomeData income;
  final ExpenseData expenses;
  final SummaryData summary;

  ProfitLossReport({
    required this.period,
    required this.income,
    required this.expenses,
    required this.summary,
  });

  factory ProfitLossReport.fromJson(Map<String, dynamic> json) {
    return ProfitLossReport(
      period: PeriodInfo.fromJson(json['period'] ?? {}),
      income: IncomeData.fromJson(json['income'] ?? {}),
      expenses: ExpenseData.fromJson(json['expenses'] ?? {}),
      summary: SummaryData.fromJson(json['summary'] ?? {}),
    );
  }
}

class PeriodInfo {
  final String startDate;
  final String endDate;
  final String branchId;

  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.branchId,
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      branchId: json['branchId']?.toString() ?? 'all',
    );
  }
}

class GroupItem {
  final String name;
  final double amount;

  GroupItem({required this.name, required this.amount});

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class GroupData {
  final List<GroupItem> items;
  final double total;

  GroupData({required this.items, required this.total});

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      items: (json['items'] as List? ?? [])
          .map((e) => GroupItem.fromJson(e))
          .toList(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class IncomeData {
  final GroupData operational;
  final GroupData other;
  final double grandTotal;

  IncomeData({
    required this.operational,
    required this.other,
    required this.grandTotal,
  });

  factory IncomeData.fromJson(Map<String, dynamic> json) {
    return IncomeData(
      operational: GroupData.fromJson(json['operational'] ?? {}),
      other: GroupData.fromJson(json['other'] ?? {}),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
    );
  }
}

class ExpenseData {
  final GroupData salaries;
  final GroupData operational;
  final GroupData nonOperational;
  final double grandTotal;

  ExpenseData({
    required this.salaries,
    required this.operational,
    required this.nonOperational,
    required this.grandTotal,
  });

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    return ExpenseData(
      salaries: GroupData.fromJson(json['salaries'] ?? {}),
      operational: GroupData.fromJson(json['operational'] ?? {}),
      nonOperational: GroupData.fromJson(json['nonOperational'] ?? {}),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
    );
  }
}

class SummaryData {
  final double totalIncome;
  final double totalExpenses;
  final double operatingProfit;
  final double netProfit;
  final double profitMargin;

  SummaryData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.operatingProfit,
    required this.netProfit,
    required this.profitMargin,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      operatingProfit: (json['operatingProfit'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0).toDouble(),
    );
  }
}

// ============================================
// 📅 Monthly Trend Model
// ============================================
class MonthlyTrendResponse {
  final int year;
  final List<MonthlyData> months;
  final MonthlyTotals totals;

  MonthlyTrendResponse({
    required this.year,
    required this.months,
    required this.totals,
  });

  factory MonthlyTrendResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendResponse(
      year: json['year'] ?? DateTime.now().year,
      months: (json['months'] as List? ?? [])
          .map((e) => MonthlyData.fromJson(e))
          .toList(),
      totals: MonthlyTotals.fromJson(json['totals'] ?? {}),
    );
  }
}

class MonthlyData {
  final int month;
  final String monthName;
  final double income;
  final double expense;
  final double netProfit;

  MonthlyData({
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
    required this.netProfit,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] ?? 0,
      monthName: json['monthName'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
    );
  }
}

class MonthlyTotals {
  final double income;
  final double expense;
  final double netProfit;

  MonthlyTotals({
    required this.income,
    required this.expense,
    required this.netProfit,
  });

  factory MonthlyTotals.fromJson(Map<String, dynamic> json) {
    return MonthlyTotals(
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
    );
  }
}

// ============================================
// 🏢 Branch Report Model
// ============================================
class BranchReportResponse {
  final List<BranchData> branches;
  final BranchTotals totals;

  BranchReportResponse({
    required this.branches,
    required this.totals,
  });

  factory BranchReportResponse.fromJson(Map<String, dynamic> json) {
    return BranchReportResponse(
      branches: (json['branches'] as List? ?? [])
          .map((e) => BranchData.fromJson(e))
          .toList(),
      totals: BranchTotals.fromJson(json['totals'] ?? {}),
    );
  }
}

class BranchData {
  final int branchId;
  final String branchName;
  final double totalIncome;
  final double totalExpense;
  final double netProfit;

  BranchData({
    required this.branchId,
    required this.branchName,
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      branchId: json['IDbranch'] ?? 0,
      branchName: json['branchName'] ?? '',
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
    );
  }
}

class BranchTotals {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;

  BranchTotals({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
  });

  factory BranchTotals.fromJson(Map<String, dynamic> json) {
    return BranchTotals(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
    );
  }
}