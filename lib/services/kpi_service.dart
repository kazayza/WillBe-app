import 'api_service.dart';

class KpiService {
  static const String _baseUrl = 'income-kpi';

  /// ══════════════════════════════════════════════════════════
  /// 🆕 الدالة الجديدة - تجلب كل البيانات مرة واحدة
  /// ══════════════════════════════════════════════════════════
  static Future<DashboardData> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
    int? branchId,
    int? kindId,
    String? compareWith,
    String groupBy = 'daily',
  }) async {
    String query = '?fromDate=${_formatDate(fromDate)}&toDate=${_formatDate(toDate)}';
    
    if (branchId != null) query += '&branchId=$branchId';
    if (kindId != null) query += '&kindId=$kindId';
    if (compareWith != null) query += '&compareWith=$compareWith';
    query += '&groupBy=$groupBy';

    final response = await ApiService.get('$_baseUrl/dashboard$query');
    
    if (response['success'] == true && response['data'] != null) {
      return DashboardData.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'فشل في جلب البيانات');
    }
  }

  /// تنسيق التاريخ
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// ══════════════════════════════════════════════════════════
/// 📋 جلب الفلاتر (الفروع والأنواع)
/// ══════════════════════════════════════════════════════════
static Future<FiltersData> getFilters() async {
  final response = await ApiService.get('$_baseUrl/filters');
  
  if (response['success'] == true && response['data'] != null) {
    return FiltersData.fromJson(response['data']);
  } else {
    throw Exception(response['message'] ?? 'فشل في جلب الفلاتر');
  }
}
}

/// ══════════════════════════════════════════════════════════════
/// 📦 Models - بنية البيانات
/// ══════════════════════════════════════════════════════════════

class DashboardData {
  final MainKPIs mainKPIs;
  final List<ChartPoint> chartData;
  final Distributions distributions;
  final Summary summary;
  final Period period;

  DashboardData({
    required this.mainKPIs,
    required this.chartData,
    required this.distributions,
    required this.summary,
    required this.period,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      mainKPIs: MainKPIs.fromJson(json['mainKPIs'] ?? {}),
      chartData: (json['chartData'] as List<dynamic>?)
          ?.map((e) => ChartPoint.fromJson(e))
          .toList() ?? [],
      distributions: Distributions.fromJson(json['distributions'] ?? {}),
      summary: Summary.fromJson(json['summary'] ?? {}),
      period: Period.fromJson(json['period'] ?? {}),
    );
  }
}

class MainKPIs {
  final double totalAmount;
  final int totalTransactions;
  final double avgTransaction;
  final double dailyAverage;
  final double maxTransaction;
  final double minTransaction;
  final int uniqueChildren;
  final int activeDays;
  final Changes? changes;

  MainKPIs({
    required this.totalAmount,
    required this.totalTransactions,
    required this.avgTransaction,
    required this.dailyAverage,
    required this.maxTransaction,
    required this.minTransaction,
    required this.uniqueChildren,
    required this.activeDays,
    this.changes,
  });

  factory MainKPIs.fromJson(Map<String, dynamic> json) {
    return MainKPIs(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      avgTransaction: (json['avgTransaction'] ?? 0).toDouble(),
      dailyAverage: (json['dailyAverage'] ?? 0).toDouble(),
      maxTransaction: (json['maxTransaction'] ?? 0).toDouble(),
      minTransaction: (json['minTransaction'] ?? 0).toDouble(),
      uniqueChildren: json['uniqueChildren'] ?? 0,
      activeDays: json['activeDays'] ?? 0,
      changes: json['changes'] != null ? Changes.fromJson(json['changes']) : null,
    );
  }
}

class Changes {
  final double? totalAmount;
  final double? totalTransactions;
  final double? avgTransaction;
  final double? dailyAverage;

  Changes({
    this.totalAmount,
    this.totalTransactions,
    this.avgTransaction,
    this.dailyAverage,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      totalAmount: json['totalAmount']?.toDouble(),
      totalTransactions: json['totalTransactions']?.toDouble(),
      avgTransaction: json['avgTransaction']?.toDouble(),
      dailyAverage: json['dailyAverage']?.toDouble(),
    );
  }
}

class ChartPoint {
  final dynamic period;
  final int? year;
  final int transactions;
  final double amount;

  ChartPoint({
    required this.period,
    this.year,
    required this.transactions,
    required this.amount,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      period: json['period'],
      year: json['year'],
      transactions: json['transactions'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

/// ══════════════════════════════════════════════════════════
/// 📋 Model الفلاتر
/// ══════════════════════════════════════════════════════════

class FiltersData {
  final List<FilterItem> branches;
  final List<FilterItem> kinds;

  FiltersData({
    required this.branches,
    required this.kinds,
  });

  factory FiltersData.fromJson(Map<String, dynamic> json) {
    return FiltersData(
      branches: (json['branches'] as List<dynamic>?)
          ?.map((e) => FilterItem.fromJson(e))
          .toList() ?? [],
      kinds: (json['kinds'] as List<dynamic>?)
          ?.map((e) => FilterItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class FilterItem {
  final int id;
  final String name;

  FilterItem({
    required this.id,
    required this.name,
  });

  factory FilterItem.fromJson(Map<String, dynamic> json) {
    return FilterItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'غير محدد',
    );
  }
}

class Distributions {
  final List<DistributionItem> byKind;
  final List<DistributionItem> byBranch;

  Distributions({
    required this.byKind,
    required this.byBranch,
  });

  factory Distributions.fromJson(Map<String, dynamic> json) {
    return Distributions(
      byKind: (json['byKind'] as List<dynamic>?)
          ?.map((e) => DistributionItem.fromJson(e, 'kindName'))
          .toList() ?? [],
      byBranch: (json['byBranch'] as List<dynamic>?)
          ?.map((e) => DistributionItem.fromJson(e, 'branchName'))
          .toList() ?? [],
    );
  }
}

class DistributionItem {
  final int? id;
  final String name;
  final int transactions;
  final double amount;
  final double percentage;

  DistributionItem({
    this.id,
    required this.name,
    required this.transactions,
    required this.amount,
    required this.percentage,
  });

  factory DistributionItem.fromJson(Map<String, dynamic> json, String nameKey) {
    return DistributionItem(
      id: json['kindId'] ?? json['branchId'],
      name: json[nameKey] ?? 'غير محدد',
      transactions: json['transactions'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class Summary {
  final String? bestDay;
  final double bestDayAmount;
  final String? worstDay;
  final double worstDayAmount;

  Summary({
    this.bestDay,
    required this.bestDayAmount,
    this.worstDay,
    required this.worstDayAmount,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      bestDay: json['bestDay'],
      bestDayAmount: (json['bestDayAmount'] ?? 0).toDouble(),
      worstDay: json['worstDay'],
      worstDayAmount: (json['worstDayAmount'] ?? 0).toDouble(),
    );
  }
}

class Period {
  final String? from;
  final String? to;
  final String? previousFrom;
  final String? previousTo;

  Period({
    this.from,
    this.to,
    this.previousFrom,
    this.previousTo,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      previousFrom: json['previousFrom']?.toString(),
      previousTo: json['previousTo']?.toString(),
    );
  }

}