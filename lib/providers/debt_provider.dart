import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DebtProvider with ChangeNotifier {
  List<dynamic> _debts = [];
  List<dynamic> _filteredDebts = [];
  List<dynamic> _childDebtDetails = [];
  bool _isLoading = false;

  // الفلاتر
  bool _showOnlyDebtors = false;
  String _searchQuery = '';
  String _selectedType = 'الكل'; // الكل - دراسة - باص
  int? _selectedBranchId;
  
  // متغيرات الـ KPI
  Map<String, dynamic>? _kpiData;
  bool _isKpiLoading = false;

  // Getters
  Map<String, dynamic>? get kpiData => _kpiData;
  bool get isKpiLoading => _isKpiLoading;
  List<dynamic> get debts => _filteredDebts;
  List<dynamic> get allDebts => _debts;
  List<dynamic> get childDebtDetails => _childDebtDetails;
  bool get isLoading => _isLoading;
  bool get showOnlyDebtors => _showOnlyDebtors;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  int? get selectedBranchId => _selectedBranchId;
    // ==================== تحليل KPI متقدم ====================

  // 1. مصفوفة المخاطر (Risk Matrix)
  Map<String, List<dynamic>> get riskMatrix {
    if (_kpiData == null || _kpiData!['topDebtors'] == null) return {};
    
    final debtors = _kpiData!['topDebtors'] as List;
    return {
      'high': debtors.where((d) => (d['daysLate'] ?? 0) > 60).toList(),
      'medium': debtors.where((d) => (d['daysLate'] ?? 0) > 30 && (d['daysLate'] ?? 0) <= 60).toList(),
      'low': debtors.where((d) => (d['daysLate'] ?? 0) <= 30).toList(),
    };
  }

  // 2. التوصيات المالية الذكية (Smart Insights)
  List<Map<String, dynamic>> get smartInsights {
    if (_kpiData == null) return [];
    List<Map<String, dynamic>> insights = [];
    final general = _kpiData!['general'];
    final branches = _kpiData!['branches'] as List;

    // توصية 1: معدل التحصيل
    double rate = double.tryParse(general['collectionRate']?.toString() ?? '0') ?? 0;
    if (rate < 50) {
      insights.add({
        'type': 'danger',
        'text': '⚠️ معدل التحصيل منخفض جداً ($rate%)، يجب اتخاذ إجراءات فورية.',
      });
    } else if (rate > 85) {
      insights.add({
        'type': 'success',
        'text': '✅ أداء مالي ممتاز! معدل التحصيل وصل $rate%.',
      });
    }

    // توصية 2: الفروع المتعثرة
    if (branches.isNotEmpty) {
      var worstBranch = branches.reduce((a, b) {
        double rateA = (a['totalPaid'] / (a['totalRequired'] == 0 ? 1 : a['totalRequired']));
        double rateB = (b['totalPaid'] / (b['totalRequired'] == 0 ? 1 : b['totalRequired']));
        return rateA < rateB ? a : b;
      });
      
      double worstRate = (worstBranch['totalPaid'] / (worstBranch['totalRequired'] == 0 ? 1 : worstBranch['totalRequired'])) * 100;
      if (worstRate < 60) {
        insights.add({
          'type': 'warning',
          'text': '📉 فرع "${worstBranch['branchName']}" يعاني من تعثر في التحصيل (${worstRate.toStringAsFixed(1)}%).',
        });
      }
    }

    // توصية 3: المتأخرات الخطرة
    final highRisk = riskMatrix['high']?.length ?? 0;
    if (highRisk > 0) {
      insights.add({
        'type': 'danger',
        'text': '🚨 يوجد $highRisk طلاب متأخرين أكثر من 60 يوماً، يرجى التواصل معهم.',
      });
    }

    return insights;
  }
  
  // ==================== إحصائيات ديناميكية ====================

// عدد اشتراكات الدراسة
  int get studyCount => _filteredDebts.where((d) =>
      (d['Kind_subscrip'] ?? '').toString().contains('الدراسة')).length;

  // عدد اشتراكات الباص
  int get busCount => _filteredDebts.where((d) =>
      (d['Kind_subscrip'] ?? '').toString().contains('الباص')).length;

  // عدد المديونين - دراسة
  int get studyDebtorCount => _filteredDebts.where((d) {
    bool isStudy = (d['Kind_subscrip'] ?? '').toString().contains('الدراسة');
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    return isStudy && totalPaid < totalAmount;
  }).length;

  // عدد المسددين - دراسة
  int get studyPaidCount => _filteredDebts.where((d) {
    bool isStudy = (d['Kind_subscrip'] ?? '').toString().contains('الدراسة');
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    return isStudy && totalPaid >= totalAmount;
  }).length;

  // عدد المديونين - باص
  int get busDebtorCount => _filteredDebts.where((d) {
    bool isBus = (d['Kind_subscrip'] ?? '').toString().contains('الباص');
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    return isBus && totalPaid < totalAmount;
  }).length;

  // عدد المسددين - باص
  int get busPaidCount => _filteredDebts.where((d) {
    bool isBus = (d['Kind_subscrip'] ?? '').toString().contains('الباص');
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    return isBus && totalPaid >= totalAmount;
  }).length;

  // إجمالي المطلوب (حسب الفلتر)
  double get totalAmounts => _filteredDebts.fold(0.0, (sum, d) {
    return sum + (double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0);
  });

  // إجمالي المدفوع (حسب الفلتر)
  double get totalPaidAll => _filteredDebts.fold(0.0, (sum, d) {
    return sum + (double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0);
  });

  // إجمالي المتبقي
  double get totalRemaining => totalAmounts - totalPaidAll;

  // نسبة السداد
  double get paymentPercentage =>
      totalAmounts > 0 ? (totalPaidAll / totalAmounts) * 100 : 0;

  // عدد المتأخرين
  int get overdueCount => _filteredDebts.where((d) {
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    bool hasDebt = totalPaid < totalAmount;
    bool isOverdue = d['nextInstallmentDate'] != null &&
        DateTime.tryParse(d['nextInstallmentDate'].toString())
            ?.isBefore(DateTime.now()) == true;
    return hasDebt && isOverdue;
  }).length;

  // عدد الجاري سدادهم
  int get ongoingCount => _filteredDebts.where((d) {
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    bool hasDebt = totalPaid < totalAmount;
    bool isOverdue = d['nextInstallmentDate'] != null &&
        DateTime.tryParse(d['nextInstallmentDate'].toString())
            ?.isBefore(DateTime.now()) == true;
    return hasDebt && !isOverdue;
  }).length;

  // عدد المسددين بالكامل
  int get paidFullCount => _filteredDebts.where((d) {
    double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
    return totalPaid >= totalAmount;
  }).length;

  // إجمالي الطلاب (بدون تكرار)
  int get totalChildren {
    final ids = _filteredDebts.map((d) => d['Child_Id']).toSet();
    return ids.length;
  }

  // قائمة الفروع الموجودة
  List<Map<String, dynamic>> get availableBranches {
    final branches = <int, String>{};
    for (var d in _debts) {
      if (d['Branch'] != null && d['branchName'] != null) {
        branches[d['Branch']] = d['branchName'].toString();
      }
    }
    return branches.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  // ==================== جلب البيانات ====================

  // 1️⃣ جلب المديونيات
  Future<void> fetchDebts(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getAllDebts(sessionId);
      _debts = data;
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching debts: $e');
      _debts = [];
      _filteredDebts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2️⃣ جلب تفاصيل مديونية طفل
  Future<void> fetchChildDebtDetails({
    required int childId,
    required int sessionId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getChildDebtDetails(
        childId: childId,
        sessionId: sessionId,
      );

      if (response['success'] == true && response['data'] != null) {
        _childDebtDetails = response['data'] is List
            ? response['data']
            : [response['data']];
      } else {
        _childDebtDetails = [];
      }
    } catch (e) {
      debugPrint('Error fetching child debt details: $e');
      _childDebtDetails = [];
    }

    _isLoading = false;
    notifyListeners();
  }
  
    // 3️⃣ جلب مؤشرات الأداء
  Future<void> fetchFinancialKPIs(int sessionId) async {
    _isKpiLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getFinancialKPIs(sessionId);
      
      if (response['success'] == true) {
        _kpiData = response['data'];
      } else {
        _kpiData = null;
        debugPrint("API Error: ${response['message']}");
      }
    } catch (e) {
      debugPrint('Provider Error fetching KPIs: $e');
      _kpiData = null;
    }

    _isKpiLoading = false;
    notifyListeners();
  }
  
  // ==================== الفلاتر ====================

  // 3️⃣ فلتر نوع الاشتراك
  void setTypeFilter(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  // 4️⃣ فلتر الفرع
  void setBranchFilter(int? branchId) {
    _selectedBranchId = branchId;
    _applyFilters();
    notifyListeners();
  }

  // 5️⃣ فلتر المديونين فقط
  void toggleShowOnlyDebtors() {
    _showOnlyDebtors = !_showOnlyDebtors;
    _applyFilters();
    notifyListeners();
  }

  // 6️⃣ البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // 7️⃣ تطبيق كل الفلاتر
  void _applyFilters() {
    _filteredDebts = List.from(_debts);

    // فلتر نوع الاشتراك
    if (_selectedType == 'دراسة') {
      _filteredDebts = _filteredDebts.where((d) =>
          (d['Kind_subscrip'] ?? '').toString().contains('الدراسة')).toList();
    } else if (_selectedType == 'باص') {
      _filteredDebts = _filteredDebts.where((d) =>
          (d['Kind_subscrip'] ?? '').toString().contains('الباص')).toList();
    }

    // فلتر الفرع
    if (_selectedBranchId != null) {
      _filteredDebts = _filteredDebts.where((d) =>
          d['Branch'] == _selectedBranchId).toList();
    }

    // فلتر المديونين فقط
    if (_showOnlyDebtors) {
      _filteredDebts = _filteredDebts.where((d) {
        double totalAmount = double.tryParse(d['amount_Sub']?.toString() ?? '0') ?? 0;
        double totalPaid = double.tryParse(d['totalPaid']?.toString() ?? '0') ?? 0;
        return totalPaid < totalAmount;
      }).toList();
    }

    // فلتر البحث
    if (_searchQuery.isNotEmpty) {
      _filteredDebts = _filteredDebts.where((d) {
        String name = d['FullNameArabic']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }


  
  // 8️⃣ مسح كل الفلاتر
  void clearFilters() {
    _showOnlyDebtors = false;
    _searchQuery = '';
    _selectedType = 'الكل';
    _selectedBranchId = null;
    _applyFilters();
    notifyListeners();
  }

  // ==================== KPI متقدم ====================

Map<String, dynamic>? _advancedKpiData;
bool _isAdvancedKpiLoading = false;
int? _kpiSelectedBranchId;
String _kpiSelectedType = 'الكل';
String _kpiSearchQuery = '';

// Getters
Map<String, dynamic>? get advancedKpiData => _advancedKpiData;
bool get isAdvancedKpiLoading => _isAdvancedKpiLoading;
int? get kpiSelectedBranchId => _kpiSelectedBranchId;
String get kpiSelectedType => _kpiSelectedType;
String get kpiSearchQuery => _kpiSearchQuery;

// جلب البيانات المتقدمة
Future<void> fetchAdvancedKPIs(int sessionId) async {
  _isAdvancedKpiLoading = true;
  notifyListeners();

  try {
    String? typeParam;
    if (_kpiSelectedType == 'دراسة') typeParam = 'study';
    if (_kpiSelectedType == 'باص') typeParam = 'bus';

    final response = await ApiService.getAdvancedKPIs(
      sessionId: sessionId,
      branchId: _kpiSelectedBranchId,
      type: typeParam,
    );

    if (response['success'] == true) {
      _advancedKpiData = response['data'];
    } else {
      _advancedKpiData = null;
    }
  } catch (e) {
    debugPrint('Error fetching advanced KPIs: $e');
    _advancedKpiData = null;
  }

  _isAdvancedKpiLoading = false;
  notifyListeners();
}

// فلاتر KPI
void setKpiBranchFilter(int? branchId, int sessionId) {
  _kpiSelectedBranchId = branchId;
  notifyListeners();
  fetchAdvancedKPIs(sessionId);
}

void setKpiTypeFilter(String type, int sessionId) {
  _kpiSelectedType = type;
  notifyListeners();
  fetchAdvancedKPIs(sessionId);
}

void setKpiSearchQuery(String query) {
  _kpiSearchQuery = query;
  notifyListeners();
}

// ==================== التحليلات الذكية ====================

List<Map<String, dynamic>> get advancedInsights {
  if (_advancedKpiData == null) return [];
  List<Map<String, dynamic>> insights = [];
  final general = _advancedKpiData!['general'];
  final branches = _advancedKpiData!['branches'] as List? ?? [];
  final topDebtors = _advancedKpiData!['topDebtors'] as List? ?? [];

  double rate = _safeDouble(general['collectionRate']);
  double totalPaid = _safeDouble(general['totalPaid']);
  double totalRequired = _safeDouble(general['totalRequired']);
  double remaining = _safeDouble(general['remaining']);
  int totalChildren = general['totalChildren'] ?? 0;
  int paidFull = general['paidFullCount'] ?? 0;
  int overdueCount = general['overdueInstallments'] ?? 0;
  int upcomingCount = general['upcomingInstallments'] ?? 0;
  double upcomingAmount = _safeDouble(general['upcomingAmount']);
  int avgDays = general['avgDaysLate'] ?? 0;

  // 1. ملخص عام
  insights.add({
    'icon': '💰',
    'type': rate > 80 ? 'success' : rate > 50 ? 'warning' : 'danger',
    'title': 'الملخص المالي',
    'text': 'تم تحصيل ${rate.toStringAsFixed(1)}% من إجمالي المستحقات بقيمة ${_formatMoney(totalPaid)} من أصل ${_formatMoney(totalRequired)}. متبقي ${_formatMoney(remaining)} موزعة على ${totalChildren - paidFull} طالب.',
  });

  // 2. المتأخرون
  if (overdueCount > 0) {
    insights.add({
      'icon': '🚨',
      'type': 'danger',
      'title': 'أقساط متأخرة',
      'text': 'يوجد $overdueCount قسط متأخر بمتوسط تأخير $avgDays يوم. يرجى التواصل مع أولياء الأمور لتسوية المتأخرات.',
    });
  }

  // 3. الأقساط القادمة
  if (upcomingCount > 0) {
    insights.add({
      'icon': '📅',
      'type': 'info',
      'title': 'أقساط مستحقة قريباً',
      'text': '$upcomingCount قسط مستحق خلال الـ 7 أيام القادمة بإجمالي ${_formatMoney(upcomingAmount)}.',
    });
  }

  // 4. أفضل وأسوأ فرع
  if (branches.length > 1) {
    var bestBranch = branches.reduce((a, b) {
      double rA = _safeDouble(a['collectionRate']);
      double rB = _safeDouble(b['collectionRate']);
      return rA > rB ? a : b;
    });
    var worstBranch = branches.reduce((a, b) {
      double rA = _safeDouble(a['collectionRate']);
      double rB = _safeDouble(b['collectionRate']);
      return rA < rB ? a : b;
    });

    insights.add({
      'icon': '🏢',
      'type': 'info',
      'title': 'مقارنة الفروع',
      'text': 'فرع "${bestBranch['branchName']}" الأفضل أداءً بنسبة ${_safeDouble(bestBranch['collectionRate']).toStringAsFixed(1)}%. فرع "${worstBranch['branchName']}" يحتاج متابعة بنسبة ${_safeDouble(worstBranch['collectionRate']).toStringAsFixed(1)}%.',
    });
  }

  // 5. المتأخرون الخطرين
  final highRisk = topDebtors.where((d) => (d['daysLate'] ?? 0) > 60).length;
  if (highRisk > 0) {
    insights.add({
      'icon': '⚠️',
      'type': 'danger',
      'title': 'حالات حرجة',
      'text': 'يوجد $highRisk طالب متأخرين أكثر من 60 يوماً. يُنصح بالتواصل الفوري مع أولياء أمورهم.',
    });
  }

  // 6. المسددين
  if (paidFull > 0) {
    double paidPercent = (paidFull / totalChildren) * 100;
    insights.add({
      'icon': '✅',
      'type': 'success',
      'title': 'المسددين بالكامل',
      'text': '$paidFull طالب أتموا السداد بالكامل (${paidPercent.toStringAsFixed(1)}% من إجمالي الطلاب).',
    });
  }

  return insights;
}

// دوال مساعدة
double _safeDouble(dynamic val) =>
    double.tryParse(val?.toString() ?? '0') ?? 0.0;

String _formatMoney(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)} مليون ج.م';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)} ألف ج.م';
  return '${amount.toStringAsFixed(0)} ج.م';
}

// ==================== كليندر الأقساط ====================

List<dynamic> _calendarMonths = [];
List<dynamic> _monthDetails = [];
Map<String, dynamic>? _monthSummary;
bool _isCalendarLoading = false;
bool _isMonthDetailsLoading = false;

int? _calendarSelectedBranchId;
String _calendarSelectedType = 'الكل';
int? _selectedMonth;
int? _selectedYear;

// Getters
List<dynamic> get calendarMonths => _calendarMonths;
List<dynamic> get monthDetails => _monthDetails;
Map<String, dynamic>? get monthSummary => _monthSummary;
bool get isCalendarLoading => _isCalendarLoading;
bool get isMonthDetailsLoading => _isMonthDetailsLoading;
int? get calendarSelectedBranchId => _calendarSelectedBranchId;
String get calendarSelectedType => _calendarSelectedType;
int? get selectedMonth => _selectedMonth;
int? get selectedYear => _selectedYear;

// جلب ملخص الشهور
Future<void> fetchMonthlyCalendar(int sessionId) async {
  _isCalendarLoading = true;
  notifyListeners();

  try {
    String? typeParam;
    if (_calendarSelectedType == 'دراسة') typeParam = 'study';
    if (_calendarSelectedType == 'باص') typeParam = 'bus';

    final response = await ApiService.getMonthlyCalendar(
      sessionId: sessionId,
      branchId: _calendarSelectedBranchId,
      type: typeParam,
    );

    if (response['success'] == true) {
      _calendarMonths = response['data'] ?? [];
    } else {
      _calendarMonths = [];
    }
  } catch (e) {
    debugPrint('Error fetching calendar: $e');
    _calendarMonths = [];
  }

  _isCalendarLoading = false;
  notifyListeners();

  fetchCurrentMonthBranches(sessionId);
}

// جلب تفاصيل شهر معين
Future<void> fetchMonthDetails({
  required int sessionId,
  required int month,
  required int year,
}) async {
  _isMonthDetailsLoading = true;
  _selectedMonth = month;
  _selectedYear = year;
  notifyListeners();

  try {
    String? typeParam;
    if (_calendarSelectedType == 'دراسة') typeParam = 'study';
    if (_calendarSelectedType == 'باص') typeParam = 'bus';

    final response = await ApiService.getMonthDetails(
      sessionId: sessionId,
      month: month,
      year: year,
      branchId: _calendarSelectedBranchId,
      type: typeParam,
    );

    if (response['success'] == true) {
      _monthDetails = response['data'] ?? [];
      _monthSummary = response['summary'];
    } else {
      _monthDetails = [];
      _monthSummary = null;
    }
  } catch (e) {
    debugPrint('Error fetching month details: $e');
    _monthDetails = [];
    _monthSummary = null;
  }

  _isMonthDetailsLoading = false;
  notifyListeners();
}

// فلاتر الكليندر
void setCalendarBranchFilter(int? branchId, int sessionId) {
  _calendarSelectedBranchId = branchId;
  notifyListeners();
  fetchMonthlyCalendar(sessionId);
}

void setCalendarTypeFilter(String type, int sessionId) {
  _calendarSelectedType = type;
  notifyListeners();
  fetchMonthlyCalendar(sessionId);
}

// ==================== الشهر الحالي حسب الفروع ====================

List<dynamic> _currentMonthBranches = [];
bool _isCurrentMonthLoading = false;
int? _currentMonthNum;
int? _currentYearNum;

// Getters
List<dynamic> get currentMonthBranches => _currentMonthBranches;
bool get isCurrentMonthLoading => _isCurrentMonthLoading;
int? get currentMonthNum => _currentMonthNum;
int? get currentYearNum => _currentYearNum;

// جلب بيانات الشهر الحالي
Future<void> fetchCurrentMonthBranches(int sessionId) async {
  _isCurrentMonthLoading = true;
  notifyListeners();

  try {
    String? typeParam;
    if (_calendarSelectedType == 'دراسة') typeParam = 'study';
    if (_calendarSelectedType == 'باص') typeParam = 'bus';

    final response = await ApiService.getCurrentMonthBranches(
      sessionId: sessionId,
      type: typeParam,
    );

    if (response['success'] == true) {
      _currentMonthBranches = response['data'] ?? [];
      _currentMonthNum = response['currentMonth'];
      _currentYearNum = response['currentYear'];
    } else {
      _currentMonthBranches = [];
    }
  } catch (e) {
    debugPrint('Error fetching current month branches: $e');
    _currentMonthBranches = [];
  }

  _isCurrentMonthLoading = false;
  notifyListeners();
}

}