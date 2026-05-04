import 'package:flutter/material.dart';
import '../models/profit_loss_model.dart';
import '../services/profit_loss_service.dart';

class ProfitLossProvider with ChangeNotifier {
  // ============================================
  // 📊 State Variables
  // ============================================
  bool _isLoading = false;
  String? _errorMessage;
  
  ProfitLossReport? _report;
  List<MonthlyData> _monthlyData = [];
  List<BranchReport> _branchReports = [];
  Map<String, dynamic>? _quickSummary;
  Map<String, dynamic>? _comparisonData;

  // الفلاتر
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  String _selectedBranchId = 'all';
  int _selectedYear = DateTime.now().year;

  // ============================================
  // 📤 Getters
  // ============================================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfitLossReport? get report => _report;
  List<MonthlyData> get monthlyData => _monthlyData;
  List<BranchReport> get branchReports => _branchReports;
  Map<String, dynamic>? get quickSummary => _quickSummary;
  Map<String, dynamic>? get comparisonData => _comparisonData;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get selectedBranchId => _selectedBranchId;
  int get selectedYear => _selectedYear;

  // ============================================
  // 🔧 Setters & Filters
  // ============================================
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setBranch(String branchId) {
    _selectedBranchId = branchId;
    notifyListeners();
  }

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================
  // 📊 جلب التقرير التفصيلي
  // ============================================
  Future<void> fetchReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await ProfitLossService.getReport(
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        branchId: _selectedBranchId,
      );

      if (_report == null) {
        _errorMessage = 'فشل في تحميل التقرير';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // 📈 جلب ملخص سريع
  // ============================================
  Future<void> fetchQuickSummary({String period = 'month'}) async {
    try {
      _quickSummary = await ProfitLossService.getSummary(period: period);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  // ============================================
  // 📅 جلب التقرير الشهري
  // ============================================
  Future<void> fetchMonthlyTrend() async {
    _isLoading = true;
    notifyListeners();

    try {
      _monthlyData = await ProfitLossService.getMonthlyTrend(
        year: _selectedYear,
        branchId: _selectedBranchId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // 🏢 جلب تقرير الفروع
  // ============================================
  Future<void> fetchBranchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      _branchReports = await ProfitLossService.getReportByBranch(
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // 🔄 مقارنة فترتين
  // ============================================
  Future<void> comparePeriods({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _comparisonData = await ProfitLossService.comparePeriods(
        period1Start: _formatDate(period1Start),
        period1End: _formatDate(period1End),
        period2Start: _formatDate(period2Start),
        period2End: _formatDate(period2End),
        branchId: _selectedBranchId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // 🔄 تحميل كل البيانات
  // ============================================
  Future<void> loadAllData() async {
    await Future.wait([
      fetchReport(),
      fetchMonthlyTrend(),
      fetchBranchReports(),
    ]);
  }

  // ============================================
  // 🧹 Clear
  // ============================================
  void clear() {
    _report = null;
    _monthlyData = [];
    _branchReports = [];
    _quickSummary = null;
    _comparisonData = null;
    _errorMessage = null;
    notifyListeners();
  }
}