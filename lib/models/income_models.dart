// نموذج الفرع
class BranchModel {
  final int id;
  final String name;

  BranchModel({required this.id, required this.name});

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['IDbranch'] ?? json['id'] ?? 0,
      name: json['branchName'] ?? json['name'] ?? '',
    );
  }
}

// نموذج مجموعة الإيراد
class IncomeGroupModel {
  final String name;

  IncomeGroupModel({required this.name});

  factory IncomeGroupModel.fromJson(String name) {
    return IncomeGroupModel(name: name);
  }
}

// نموذج نوع الإيراد
class IncomeKindModel {
  final int id;
  final String name;
  final String group;

  IncomeKindModel({
    required this.id,
    required this.name,
    required this.group,
  });

  factory IncomeKindModel.fromJson(Map<String, dynamic> json) {
    return IncomeKindModel(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['incomeKind'] ?? json['name'] ?? '',
      group: json['kindGroup'] ?? json['group'] ?? '',
    );
  }
}

// نموذج بند الإيراد
class IncomeItemModel {
  final int detailId;
  final double amount;
  final DateTime incomeDate;
  final String incomeKindName;
  final String incomeGroup;
  final String? childName;
  final String? branchName;
  final String? receiptNumber;

  IncomeItemModel({
    required this.detailId,
    required this.amount,
    required this.incomeDate,
    required this.incomeKindName,
    required this.incomeGroup,
    this.childName,
    this.branchName,
    this.receiptNumber,
  });

  factory IncomeItemModel.fromJson(Map<String, dynamic> json) {
    return IncomeItemModel(
      detailId: json['detailId'] ?? json['ID'] ?? 0,
      amount: (json['incomeAmount'] ?? 0).toDouble(),
      incomeDate: DateTime.parse(json['incomeDate']),
      incomeKindName: json['incomeKindName'] ?? '',
      incomeGroup: json['incomeGroup'] ?? '',
      childName: json['childName'],
      branchName: json['branchName'],
      receiptNumber: json['ReceiptNumber'],
    );
  }
}

// نموذج ملخص التقرير
class ReportSummaryModel {
  final double totalAmount;
  final int totalTransactions;
  final int totalChildren;
  final double averageDaily;

  ReportSummaryModel({
    required this.totalAmount,
    required this.totalTransactions,
    required this.totalChildren,
    required this.averageDaily,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      totalChildren: json['totalChildren'] ?? 0,
      averageDaily: (json['averageDaily'] ?? 0).toDouble(),
    );
  }
}

// نموذج الطفل
class ChildModel {
  final int id;
  final String name;
  final String? branchName;
  final String? className;

  ChildModel({
    required this.id,
    required this.name,
    this.branchName,
    this.className,
  });

  String get fullName => name;

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['ID_Child'] ?? json['id'] ?? 0,
      name: json['FullNameArabic'] ?? json['name'] ?? '',
      branchName: json['branchName'],
      className: json['ClassName'],
    );
  }
}

// نموذج إيرادات الطفل
class ChildIncomeModel {
  final int detailId;
  final double amount;
  final DateTime incomeDate;
  final String incomeKindName;
  final String? receiptNumber;
  final String? notes;

  ChildIncomeModel({
    required this.detailId,
    required this.amount,
    required this.incomeDate,
    required this.incomeKindName,
    this.receiptNumber,
    this.notes,
  });

  factory ChildIncomeModel.fromJson(Map<String, dynamic> json) {
    return ChildIncomeModel(
      detailId: json['detailId'] ?? json['ID'] ?? 0,
      amount: (json['incomeAmount'] ?? 0).toDouble(),
      incomeDate: DateTime.parse(json['incomeDate']),
      incomeKindName: json['incomeKindName'] ?? '',
      receiptNumber: json['ReceiptNumber'],
      notes: json['Notes'],
    );
  }

}
  // نموذج ملخص إيرادات الطفل
class ChildIncomeSummary {
  final double totalAmount;
  final int totalTransactions;

  ChildIncomeSummary({
    required this.totalAmount,
    required this.totalTransactions,
  });

  factory ChildIncomeSummary.fromJson(Map<String, dynamic> json) {
    return ChildIncomeSummary(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
    );
  }
}