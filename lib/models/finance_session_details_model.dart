class FinanceSessionDashboardModel {
  final FinanceSessionInfo session;
  final FinanceSessionSummary summary;
  final List<FinanceBranchFilter> branches;
  final List<FinanceStatusFilter> statuses;
  final List<FinanceKindFilter> subscriptionKinds;

  FinanceSessionDashboardModel({
    required this.session,
    required this.summary,
    required this.branches,
    required this.statuses,
    required this.subscriptionKinds,
  });

  factory FinanceSessionDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceSessionDashboardModel(
      session: FinanceSessionInfo.fromJson(json['session'] ?? {}),
      summary: FinanceSessionSummary.fromJson(json['summary'] ?? {}),
      branches: (json['branches'] as List? ?? [])
          .map((e) => FinanceBranchFilter.fromJson(e))
          .toList(),
      statuses: (json['statuses'] as List? ?? [])
          .map((e) => FinanceStatusFilter.fromJson(e))
          .toList(),
      subscriptionKinds: (json['subscriptionKinds'] as List? ?? [])
          .map((e) => FinanceKindFilter.fromJson(e))
          .toList(),
    );
  }
}

class FinanceSessionInfo {
  final int sessionId;
  final String sessionName;

  FinanceSessionInfo({
    required this.sessionId,
    required this.sessionName,
  });

  factory FinanceSessionInfo.fromJson(Map<String, dynamic> json) {
    return FinanceSessionInfo(
      sessionId: json['sessionId'] ?? 0,
      sessionName: json['sessionName'] ?? '',
    );
  }
}

class FinanceSessionSummary {
  final int uniqueChildrenCount;
  final double totalAmount;
  final double averageAmount;
  final double minAmount;
  final double maxAmount;
  final DateTime? firstSubDate;
  final DateTime? lastSubDate;

  FinanceSessionSummary({
    required this.uniqueChildrenCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.firstSubDate,
    required this.lastSubDate,
  });

  factory FinanceSessionSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSessionSummary(
      uniqueChildrenCount: json['uniqueChildrenCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      averageAmount: (json['averageAmount'] ?? 0).toDouble(),
      minAmount: (json['minAmount'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? 0).toDouble(),
      firstSubDate: json['firstSubDate'] != null
          ? DateTime.tryParse(json['firstSubDate'])
          : null,
      lastSubDate: json['lastSubDate'] != null
          ? DateTime.tryParse(json['lastSubDate'])
          : null,
    );
  }
}

class FinanceBranchFilter {
  final dynamic branchId;
  final String branchName;
  final int count;

  FinanceBranchFilter({
    required this.branchId,
    required this.branchName,
    required this.count,
  });

  factory FinanceBranchFilter.fromJson(Map<String, dynamic> json) {
    return FinanceBranchFilter(
      branchId: json['branchId'],
      branchName: json['branchName'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class FinanceStatusFilter {
  final String key;
  final String label;
  final int count;

  FinanceStatusFilter({
    required this.key,
    required this.label,
    required this.count,
  });

  factory FinanceStatusFilter.fromJson(Map<String, dynamic> json) {
    return FinanceStatusFilter(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class FinanceKindFilter {
  final String key;
  final String label;
  final int count;

  FinanceKindFilter({
    required this.key,
    required this.label,
    required this.count,
  });

  factory FinanceKindFilter.fromJson(Map<String, dynamic> json) {
    return FinanceKindFilter(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

// ===========================================================
// Records Model
// ===========================================================
class FinanceSessionRecordsResponse {
  final FinanceSessionInfo session;
  final FinanceAppliedFiltersLabels appliedFiltersLabels;
  final FinanceRecordsSummary summary;
  final List<FinanceRecordModel> records;
  final List<FinanceMonthGroup> groups;
  final FinancePagination? pagination;

  FinanceSessionRecordsResponse({
    required this.session,
    required this.appliedFiltersLabels,
    required this.summary,
    required this.records,
    required this.groups,
    required this.pagination,
  });

  factory FinanceSessionRecordsResponse.fromJson(Map<String, dynamic> json) {
    return FinanceSessionRecordsResponse(
      session: FinanceSessionInfo.fromJson(json['session'] ?? {}),
      appliedFiltersLabels: FinanceAppliedFiltersLabels.fromJson(
        json['appliedFiltersLabels'] ?? {},
      ),
      summary: FinanceRecordsSummary.fromJson(json['summary'] ?? {}),
      records: (json['records'] as List? ?? [])
          .map((e) => FinanceRecordModel.fromJson(e))
          .toList(),
      groups: (json['groups'] as List? ?? [])
          .map((e) => FinanceMonthGroup.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? FinancePagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class FinanceAppliedFiltersLabels {
  final String branchLabel;
  final String statusLabel;
  final String kindLabel;

  FinanceAppliedFiltersLabels({
    required this.branchLabel,
    required this.statusLabel,
    required this.kindLabel,
  });

  factory FinanceAppliedFiltersLabels.fromJson(Map<String, dynamic> json) {
    return FinanceAppliedFiltersLabels(
      branchLabel: json['branchLabel'] ?? 'الكل',
      statusLabel: json['statusLabel'] ?? '',
      kindLabel: json['kindLabel'] ?? '',
    );
  }
}

class FinanceRecordsSummary {
  final int recordsCount;
  final int uniqueChildrenCount;
  final double totalAmount;
  final double averageAmount;
  final double minAmount;
  final double maxAmount;
  final DateTime? firstSubDate;
  final DateTime? lastSubDate;

  FinanceRecordsSummary({
    required this.recordsCount,
    required this.uniqueChildrenCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.firstSubDate,
    required this.lastSubDate,
  });

  factory FinanceRecordsSummary.fromJson(Map<String, dynamic> json) {
    return FinanceRecordsSummary(
      recordsCount: json['recordsCount'] ?? 0,
      uniqueChildrenCount: json['uniqueChildrenCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      averageAmount: (json['averageAmount'] ?? 0).toDouble(),
      minAmount: (json['minAmount'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? 0).toDouble(),
      firstSubDate: json['firstSubDate'] != null
          ? DateTime.tryParse(json['firstSubDate'])
          : null,
      lastSubDate: json['lastSubDate'] != null
          ? DateTime.tryParse(json['lastSubDate'])
          : null,
    );
  }
}

class FinanceRecordModel {
  final int financeId;
  final int childId;
  final String childName;
  final int? branchId;
  final String branchName;
  final String subscriptionKind;
  final double amountSub;
  final double amountBase;
  final double discount;
  final bool withdraw;
  final double withdrawAmount;
  final int? busLineId;
  final String? busLineName;
  final DateTime? subDate;

  FinanceRecordModel({
    required this.financeId,
    required this.childId,
    required this.childName,
    required this.branchId,
    required this.branchName,
    required this.subscriptionKind,
    required this.amountSub,
    required this.amountBase,
    required this.discount,
    required this.withdraw,
    required this.withdrawAmount,
    required this.busLineId,
    required this.busLineName,
    required this.subDate,
  });

  factory FinanceRecordModel.fromJson(Map<String, dynamic> json) {
    return FinanceRecordModel(
      financeId: json['financeId'] ?? 0,
      childId: json['childId'] ?? 0,
      childName: json['childName'] ?? '',
      branchId: json['branchId'],
      branchName: json['branchName'] ?? '',
      subscriptionKind: json['subscriptionKind'] ?? '',
      amountSub: (json['amountSub'] ?? 0).toDouble(),
      amountBase: (json['amountBase'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      withdraw: json['withdraw'] == true || json['withdraw'] == 1,
      withdrawAmount: (json['withdrawAmount'] ?? 0).toDouble(),
      busLineId: json['busLineId'],
      busLineName: json['busLineName'],
      subDate: json['subDate'] != null
          ? DateTime.tryParse(json['subDate'])
          : null,
    );
  }
}

class FinanceMonthGroup {
  final String monthKey;
  final String monthLabel;
  final int count;
  final double totalAmount;
  final List<FinanceRecordModel> records;

  FinanceMonthGroup({
    required this.monthKey,
    required this.monthLabel,
    required this.count,
    required this.totalAmount,
    required this.records,
  });

  factory FinanceMonthGroup.fromJson(Map<String, dynamic> json) {
    return FinanceMonthGroup(
      monthKey: json['monthKey'] ?? '',
      monthLabel: json['monthLabel'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      records: (json['records'] as List? ?? [])
          .map((e) => FinanceRecordModel.fromJson(e))
          .toList(),
    );
  }
}

class FinancePagination {
  final int page;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  FinancePagination({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  factory FinancePagination.fromJson(Map<String, dynamic> json) {
    return FinancePagination(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}