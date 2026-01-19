class DashboardStats {
  final int childrenCount;
  final int employeesCount;
  final num monthlyIncome;
  final num monthlyExpense;
  final num netProfit;

  DashboardStats({
    required this.childrenCount,
    required this.employeesCount,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netProfit,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      childrenCount: json['childrenCount'] ?? 0,
      employeesCount: json['employeesCount'] ?? 0,
      monthlyIncome: json['monthlyIncome'] ?? 0,
      monthlyExpense: json['monthlyExpense'] ?? 0,
      netProfit: json['netProfit'] ?? 0,
    );
  }
}