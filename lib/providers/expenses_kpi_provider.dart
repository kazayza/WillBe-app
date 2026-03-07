import 'package:flutter/material.dart';
import '../models/expenses_kpi_model.dart';
import '../services/expenses_kpi_service.dart';

class ExpensesKPIProvider extends ChangeNotifier {
  ExpensesKPIModel? _kpiData;
  ExpenseFiltersModel? _filtersData;
  bool _isLoading = false;
  bool _isFiltersLoading = false;
  String? _error;
  String? _filtersError;

  String _selectedPeriodType = 'month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _selectedBranchId;
  String? _selectedGroupId;
  int? _selectedKindId;

  String? _selectedBranchName;
  String? _selectedGroupName;
  String? _selectedKindName;

  ExpensesKPIModel? get kpiData => _kpiData;
  ExpenseFiltersModel? get filtersData => _filtersData;
  bool get isLoading => _isLoading;
  bool get isFiltersLoading => _isFiltersLoading;
  String? get error => _error;
  String? get filtersError => _filtersError;
  bool get hasData => _kpiData != null;
  bool get hasError => _error != null;
  bool get hasFilters => _filtersData != null;

  String get selectedPeriodType => _selectedPeriodType;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  int? get selectedBranchId => _selectedBranchId;
  String? get selectedGroupId => _selectedGroupId;
  int? get selectedKindId => _selectedKindId;
  String? get selectedBranchName => _selectedBranchName;
  String? get selectedGroupName => _selectedGroupName;
  String? get selectedKindName => _selectedKindName;

  bool get hasActiveFilters =>
      _selectedBranchId != null ||
      _selectedGroupId != null ||
      _selectedKindId != null;

  int get activeFiltersCount {
    int count = 0;
    if (_selectedBranchId != null) count++;
    if (_selectedGroupId != null) count++;
    if (_selectedKindId != null) count++;
    return count;
  }

  String get periodLabel {
    switch (_selectedPeriodType) {
      case 'month':
        return 'شهري';
      case 'quarter':
        return 'ربع سنوي';
      case 'year':
        return 'سنوي';
      case 'custom':
        return 'مخصص';
      default:
        return 'شهري';
    }
  }

  Future<void> fetchKPI() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📊 Fetching KPI... periodType: $_selectedPeriodType');
      _kpiData = await ExpensesKPIService.getExpensesKPI(
        periodType: _selectedPeriodType,
        startDate: _selectedPeriodType == 'custom' && _customStartDate != null
            ? _formatDate(_customStartDate!)
            : null,
        endDate: _selectedPeriodType == 'custom' && _customEndDate != null
            ? _formatDate(_customEndDate!)
            : null,
        branchId: _selectedBranchId,
        groupId: _selectedGroupId,
        kindId: _selectedKindId,
      );
      print('✅ KPI Data loaded successfully');
      _error = null;
    } catch (e) {
      print('❌ KPI Error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _kpiData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFilters() async {
    _isFiltersLoading = true;
    _filtersError = null;
    notifyListeners();

    try {
      print('🔽 Fetching Filters...');
      _filtersData = await ExpensesKPIService.getFilters();
      print('✅ Filters loaded: ${_filtersData!.branches.length} branches, ${_filtersData!.groups.length} groups');
      _filtersError = null;
    } catch (e) {
      print('❌ Filters Error: $e');
      _filtersError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFiltersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    await Future.wait([
      fetchKPI(),
      fetchFilters(),
    ]);
  }

  void setPeriodType(String type) {
    if (_selectedPeriodType != type) {
      _selectedPeriodType = type;
      if (type != 'custom') {
        _customStartDate = null;
        _customEndDate = null;
      }
      notifyListeners();
      fetchKPI();
    }
  }

  void setCustomDates(DateTime start, DateTime end) {
    _selectedPeriodType = 'custom';
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
    fetchKPI();
  }

  void setBranch(int? id, String? name) {
    _selectedBranchId = id;
    _selectedBranchName = name;
    notifyListeners();
    fetchKPI();
  }

  void setGroup(String? id, String? name) {
    _selectedGroupId = id;
    _selectedGroupName = name;
    _selectedKindId = null;
    _selectedKindName = null;
    notifyListeners();
    fetchKPI();
  }

  void setKind(int? id, String? name) {
    _selectedKindId = id;
    _selectedKindName = name;
    notifyListeners();
    fetchKPI();
  }

  void clearAllFilters() {
    _selectedPeriodType = 'month';
    _customStartDate = null;
    _customEndDate = null;
    _selectedBranchId = null;
    _selectedBranchName = null;
    _selectedGroupId = null;
    _selectedGroupName = null;
    _selectedKindId = null;
    _selectedKindName = null;
    notifyListeners();
    fetchKPI();
  }

  void clearBranch() {
    _selectedBranchId = null;
    _selectedBranchName = null;
    notifyListeners();
    fetchKPI();
  }

  void clearGroup() {
    _selectedGroupId = null;
    _selectedGroupName = null;
    _selectedKindId = null;
    _selectedKindName = null;
    notifyListeners();
    fetchKPI();
  }

  void clearKind() {
    _selectedKindId = null;
    _selectedKindName = null;
    notifyListeners();
    fetchKPI();
  }

  Future<void> refresh() async {
    await fetchKPI();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<FilterKind> getKindsByGroup() {
    if (_filtersData == null || _selectedGroupId == null) {
      return _filtersData?.kinds ?? [];
    }
    return _filtersData!.kinds
        .where((k) => k.groupName == _selectedGroupId)
        .toList();
  }
}