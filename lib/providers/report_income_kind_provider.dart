import 'package:flutter/material.dart';
import '../models/income_models.dart';
import '../services/report_income_kind_services.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportIncomeKindProvider extends ChangeNotifier {
  final ReportIncomeKindService _service = ReportIncomeKindService();
  //final BranchService _branchService = BranchService();
  
  // =============================================
  // حالة التحميل والخطأ
  // =============================================
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // =============================================
  // بيانات الشاشة الأولى (تقرير الإيرادات)
  // =============================================
  List<IncomeItemModel> _incomeItems = [];
  ReportSummaryModel? _summary;
  
  List<IncomeItemModel> get incomeItems => _incomeItems;
  ReportSummaryModel? get summary => _summary;
  
  // =============================================
  // الفلاتر
  // =============================================
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedBranchId;
  String? _selectedGroup;
  int? _selectedKindId;
  
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get selectedBranchId => _selectedBranchId;
  String? get selectedGroup => _selectedGroup;
  int? get selectedKindId => _selectedKindId;
  
  // =============================================
  // قوائم الفلاتر
  // =============================================
  List<BranchModel> _branches = [];
  List<String> _groups = [];
  List<IncomeKindModel> _kinds = [];
  
  List<BranchModel> get branches => _branches;
  List<String> get groups => _groups;
  List<IncomeKindModel> get kinds => _kinds;
  
  // =============================================
  // بيانات الشاشة الثانية (إيرادات الطفل)
  // =============================================
  List<ChildModel> _childrenList = [];
  ChildModel? _selectedChild;
  List<ChildIncomeModel> _childIncomes = [];
  ChildIncomeSummary? _childSummary;
  
  List<ChildModel> get childrenList => _childrenList;
  ChildModel? get selectedChild => _selectedChild;
  List<ChildIncomeModel> get childIncomes => _childIncomes;
  ChildIncomeSummary? get childSummary => _childSummary;
  
  // =============================================
  // دوال الشاشة الأولى
  // =============================================
  
  // تحميل الفروع
  Future<void> loadBranches() async {
    try {
      _branches = await _service.getBranches();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل مجموعات الإيراد
  Future<void> loadIncomeGroups() async {
    try {
      _groups = await _service.getIncomeGroups();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل أنواع الإيراد حسب المجموعة
  Future<void> loadIncomeKindsByGroup(String? group) async {
    try {
      _kinds = await _service.getIncomeKindsByGroup(group);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل تقرير الإيرادات
  Future<void> loadIncomesReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _service.getIncomesReport(
        fromDate: _fromDate,
        toDate: _toDate,
        branchId: _selectedBranchId,
        incomeGroup: _selectedGroup,
        incomeKindId: _selectedKindId,
      );
      
      if (response['success'] == true) {
  final List items = response['data'] ?? [];
  _incomeItems = items.map((e) => IncomeItemModel.fromJson(e)).toList();
  
  if (response['summary'] != null) {
    _summary = ReportSummaryModel.fromJson(response['summary']);
  }
}
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // تحديث الفلاتر
  void updateFilters({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    String? group,
    int? kindId,
  }) {
    _fromDate = fromDate;
    _toDate = toDate;
    _selectedBranchId = branchId;
    _selectedGroup = group;
    _selectedKindId = kindId;
    
    // إذا تغيرت المجموعة، نعيد تحميل الأنواع
    //if (group != null) {
      //loadIncomeKindsByGroup(group);
    //}
    
    notifyListeners();
  }
  
  // إعادة تعيين الفلاتر
  void resetFilters() {
    _fromDate = null;
    _toDate = null;
    _selectedBranchId = null;
    _selectedGroup = null;
    _selectedKindId = null;
    notifyListeners();
  }
  
  // =============================================
  // دوال الشاشة الثانية
  // =============================================
  
  // البحث عن الأطفال
  Future<void> searchChildren(String query) async {
    try {
      _childrenList = await _service.getChildrenList(search: query);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // اختيار طفل
  void selectChild(ChildModel? child) {
    _selectedChild = child;
    notifyListeners();
  }
  
  // تحميل إيرادات الطفل
  Future<void> loadChildIncomes({
    required int childId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _service.getChildIncomes(
        childId: childId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      if (response['success'] == true) {
  final List items = response['data'] ?? [];
  _childIncomes = items.map((e) => ChildIncomeModel.fromJson(e)).toList();
  
  if (response['summary'] != null) {
    _childSummary = ChildIncomeSummary.fromJson(response['summary']);
  }
}
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // تحميل إيرادات الطفل مع الفلاتر الحالية
  Future<void> refreshChildIncomes() async {
    if (_selectedChild == null) return;
    
    await loadChildIncomes(
      childId: _selectedChild!.id,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }
  
  // =============================================
  // دوال عامة
  // =============================================
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // أضف هذه الدوال داخل class ReportIncomeKindProvider

// =============================================
// دوال التصدير
// =============================================

bool _isExporting = false;
bool get isExporting => _isExporting;

// تصدير تقرير الإيرادات إلى Excel
Future<void> exportIncomesToExcel() async {
  _isExporting = true;
  notifyListeners();
  
  try {
    final bytes = await _service.exportIncomesToExcel(
      fromDate: _fromDate,
      toDate: _toDate,
      branchId: _selectedBranchId,
      incomeGroup: _selectedGroup,
      incomeKindId: _selectedKindId,
    );
    
    // حفظ الملف أو مشاركته
    await _saveAndShareFile(bytes, 'تقرير_الإيرادات.xlsx');
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isExporting = false;
    notifyListeners();
  }
}

// تصدير تقرير الإيرادات إلى PDF
Future<void> exportIncomesToPDF() async {
  _isExporting = true;
  notifyListeners();
  
  try {
    final bytes = await _service.exportIncomesToPDF(
      fromDate: _fromDate,
      toDate: _toDate,
      branchId: _selectedBranchId,
      incomeGroup: _selectedGroup,
      incomeKindId: _selectedKindId,
    );
    
    await _saveAndShareFile(bytes, 'تقرير_الإيرادات.pdf');
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isExporting = false;
    notifyListeners();
  }
}

// تصدير إيرادات الطفل إلى Excel
Future<void> exportChildIncomesToExcel() async {
  if (_selectedChild == null) return;
  
  _isExporting = true;
  notifyListeners();
  
  try {
    final bytes = await _service.exportChildIncomesToExcel(
      childId: _selectedChild!.id,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    
    await _saveAndShareFile(bytes, 'إيرادات_${_selectedChild!.fullName}.xlsx');
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isExporting = false;
    notifyListeners();
  }
}

// تصدير إيرادات الطفل إلى PDF
Future<void> exportChildIncomesToPDF() async {
  if (_selectedChild == null) return;
  
  _isExporting = true;
  notifyListeners();
  
  try {
    final bytes = await _service.exportChildIncomesToPDF(
      childId: _selectedChild!.id,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    
    await _saveAndShareFile(bytes, 'إيرادات_${_selectedChild!.fullName}.pdf');
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isExporting = false;
    notifyListeners();
  }
}

// حفظ ومشاركة الملف
Future<void> _saveAndShareFile(Uint8List bytes, String fileName) async {
  // نحتاج مكتبة share_plus و path_provider و permission_handler
  
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'تقرير الإيرادات',
  );
}
}