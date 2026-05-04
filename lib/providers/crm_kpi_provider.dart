import 'package:flutter/material.dart';
import '../models/crm_kpi_models.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📊 CRM KPI Dashboard Provider
// ═══════════════════════════════════════════════════════════════════════════

class CRMKPIProvider extends ChangeNotifier {
  // ==================== STATE ====================
  DashboardStatus _status = DashboardStatus.initial;
  String? _errorMessage;

  // ==================== DATA ====================
  CRMDashboardData _dashboardData = CRMDashboardData.empty();
  List<SourcePerformance> _sources = [];
  List<EmployeePerformance> _employees = [];
  List<PeriodStats> _periodStats = [];
  List<Branch> _branches = [];

  // ==================== FILTERS ====================
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _selectedBranchId;
  PeriodType _selectedPeriod = PeriodType.daily;

  // ==================== GETTERS ====================
  DashboardStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CRMDashboardData get dashboardData => _dashboardData;
  List<SourcePerformance> get sources => _sources;
  List<EmployeePerformance> get employees => _employees;
  List<PeriodStats> get periodStats => _periodStats;
  List<Branch> get branches => _branches;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  int? get selectedBranchId => _selectedBranchId;
  PeriodType get selectedPeriod => _selectedPeriod;

  // Computed Getters
  bool get isLoading => _status == DashboardStatus.loading;
  bool get hasError => _status == DashboardStatus.error;
  bool get hasData => _status == DashboardStatus.loaded;
  bool get isEmpty => hasData && _dashboardData.leads.total == 0;

  // Selected Branch Name
  String get selectedBranchName {
    if (_selectedBranchId == null) return 'All Branches';
    final branch = _branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => Branch(id: 0, name: 'Unknown'),
    );
    return branch.name;
  }

  // ==================== CONSTRUCTOR ====================
  CRMKPIProvider() {
    // Default: Last 30 days
    _dateTo = DateTime.now();
    _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  }

  // ==================== LOAD ALL DATA ====================
Future<void> loadAllData() async {
  _status = DashboardStatus.loading;
  _errorMessage = null;
  notifyListeners();

  try {
    // Build query parameters
    final queryParams = _buildQueryParams();

    // Load branches first (separately)
    await _loadBranches();

    // Fetch all data in parallel
    final summaryResult = await ApiService.get('dashboard-crm/summary$queryParams');
    final sourcesResult = await ApiService.get('dashboard-crm/sources-performance$queryParams');
    final employeesResult = await ApiService.get('dashboard-crm/employees-performance$queryParams');
    final periodResult = await ApiService.get('dashboard-crm/leads-by-period?period=${_selectedPeriod.name}$queryParams');

    // Parse Dashboard Summary
    if (summaryResult != null && summaryResult is Map<String, dynamic>) {
      _dashboardData = CRMDashboardData.fromJson(summaryResult);
    }

    // Parse Sources
    if (sourcesResult != null && sourcesResult is List) {
      _sources = sourcesResult
          .map((e) => SourcePerformance.fromJson(e))
          .toList();
    }

    // Parse Employees
    if (employeesResult != null && employeesResult is List) {
      debugPrint('📊 Employees Raw Data: $employeesResult');
      _employees = employeesResult
          .map((e) => EmployeePerformance.fromJson(e))
          .toList();
      debugPrint('📊 Employees Parsed: ${_employees.length}');
    }

    // Parse Period Stats
    if (periodResult != null && periodResult is List) {
      _periodStats = periodResult
          .map((e) => PeriodStats.fromJson(e))
          .toList();
    }

    _status = DashboardStatus.loaded;
  } catch (e) {
    _status = DashboardStatus.error;
    _errorMessage = e.toString().replaceAll('Exception: ', '');
    debugPrint('CRMKPIProvider Error: $e');
  }

  notifyListeners();
}

  // ==================== LOAD BRANCHES ====================
  Future<void> _loadBranches() async {
    if (_branches.isNotEmpty) return;

    try {
      final result = await ApiService.getBranches();
      _branches = result.map((e) => Branch.fromJson(e)).toList();
        } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  // ==================== BUILD QUERY PARAMS ====================
  String _buildQueryParams() {
    final params = <String>[];

    if (_dateFrom != null) {
      params.add('dateFrom=${_dateFrom!.toIso8601String()}');
    }
    if (_dateTo != null) {
      params.add('dateTo=${_dateTo!.toIso8601String()}');
    }
    if (_selectedBranchId != null) {
      params.add('branchId=$_selectedBranchId');
    }

    if (params.isEmpty) return '';
    return '?${params.join('&')}';
  }

  // ==================== FILTER METHODS ====================

  /// Set custom date range
  void setDateRange(DateTime from, DateTime to) {
    _dateFrom = from;
    _dateTo = to;
    loadAllData();
  }

  /// Set branch filter
  void setBranch(int? branchId) {
    _selectedBranchId = branchId;
    loadAllData();
  }

  /// Set period type (daily/weekly/monthly)
  void setPeriod(PeriodType period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    _loadPeriodStats();
  }

  /// Load only period stats (for tab change)
  Future<void> _loadPeriodStats() async {
    try {
      final queryParams = _buildQueryParams();
      final result = await ApiService.get(
        'dashboard-crm/leads-by-period?period=${_selectedPeriod.name}$queryParams',
      );

      if (result is List) {
        _periodStats = result.map((e) => PeriodStats.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading period stats: $e');
    }
  }

  // ==================== QUICK DATE PRESETS ====================

  /// Today
  void setToday() {
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day);
    _dateTo = now;
    loadAllData();
  }

  /// This Week
  void setThisWeek() {
    final now = DateTime.now();
    _dateFrom = now.subtract(Duration(days: now.weekday - 1));
    _dateTo = now;
    loadAllData();
  }

  /// This Month
  void setThisMonth() {
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = now;
    loadAllData();
  }

  /// Last 30 Days
  void setLast30Days() {
    _dateTo = DateTime.now();
    _dateFrom = _dateTo!.subtract(const Duration(days: 30));
    loadAllData();
  }

  /// Last 90 Days
  void setLast90Days() {
    _dateTo = DateTime.now();
    _dateFrom = _dateTo!.subtract(const Duration(days: 90));
    loadAllData();
  }

  /// This Year
  void setThisYear() {
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, 1, 1);
    _dateTo = now;
    loadAllData();
  }

  /// Clear all filters
  void clearFilters() {
    _dateFrom = DateTime.now().subtract(const Duration(days: 30));
    _dateTo = DateTime.now();
    _selectedBranchId = null;
    _selectedPeriod = PeriodType.daily;
    loadAllData();
  }

  // ==================== UTILITY METHODS ====================

  /// Refresh data
  Future<void> refresh() async {
    await loadAllData();
  }

  /// Get formatted date range text
  String getDateRangeText() {
    if (_dateFrom == null || _dateTo == null) return 'Select Date Range';

    final fromStr = '${_dateFrom!.day}/${_dateFrom!.month}';
    final toStr = '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}';

    return '$fromStr - $toStr';
  }

  /// Check if using default date range
  bool get isDefaultDateRange {
    if (_dateFrom == null || _dateTo == null) return true;

    final defaultFrom = DateTime.now().subtract(const Duration(days: 30));
    final daysDiff = _dateFrom!.difference(defaultFrom).inDays.abs();

    return daysDiff <= 1 && _selectedBranchId == null;
  }
}