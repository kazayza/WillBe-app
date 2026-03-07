import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClassesProvider with ChangeNotifier {
  // ==================== State ====================
  List<dynamic> _classes = [];
  List<dynamic> _unassignedChildren = [];
  Map<String, dynamic>? _selectedClass;
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _classChildren = [];
  List<dynamic> _classHistory = [];
  List<dynamic> _availableClassesForTransfer = [];
  Map<String, dynamic>? _classStatistics;

  // ==================== Getters ====================
  List<dynamic> get classes => _classes;
  List<dynamic> get unassignedChildren => _unassignedChildren;
  Map<String, dynamic>? get selectedClass => _selectedClass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get classChildren => _classChildren;
  List<dynamic> get classHistory => _classHistory;
  List<dynamic> get availableClassesForTransfer => _availableClassesForTransfer;
  Map<String, dynamic>? get classStatistics => _classStatistics;

  // ==================== Helper Methods ====================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== API Methods ====================

  /// 1. جلب الفصول (Dashboard)
  Future<void> fetchClasses(int branchId) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      _classes = await ApiService.getClassesDashboard(branchId);
    } catch (e) {
      debugPrint("Error fetching classes: $e");
      _classes = [];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. جلب فصل واحد بالـ ID 🆕
  Future<void> fetchClassById(int classId) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      _selectedClass = await ApiService.getClassById(classId);
    } catch (e) {
      debugPrint("Error fetching class: $e");
      _selectedClass = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. جلب الأطفال غير المسكنين
  Future<void> fetchUnassignedChildren(int branchId) async {
    try {
      _unassignedChildren = await ApiService.getUnassignedChildren(branchId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching unassigned children: $e");
      _unassignedChildren = [];
    }
  }

  /// 4. إضافة فصل جديد
  Future<bool> addClass({
    required String className,
    required int branchId,
    required int capacity,
    String? notes,
    required String userAdd,
  }) async {
    try {
      _setLoading(true);
      
      final result = await ApiService.addClass(
        className: className,
        branchId: branchId,
        capacity: capacity,
        notes: notes,
        userAdd: userAdd,
      );

      if (result['success'] == true) {
        await fetchClasses(branchId);
        return true;
      }
      
      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error adding class: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 5. تعديل فصل
  Future<bool> updateClass({
    required int classId,
    required String className,
    required int capacity,
    required int branchId,
    String? notes,
    bool? isActive,
    required String userEdit,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.updateClass(
        classId: classId,
        className: className,
        capacity: capacity,
        notes: notes,
        isActive: isActive,
        userEdit: userEdit,
      );

      if (result['success'] == true) {
        await fetchClasses(branchId);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error updating class: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 6. تسكين طالب
  Future<bool> assignStudent({
    required int childId,
    required int classId,
    required int branchId,
    String? notes,
    required String userAdd,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.assignStudentToClass(
        childId: childId,
        classId: classId,
        notes: notes,
        userAdd: userAdd,
      );

      if (result['success'] == true) {
        // تحديث البيانات فوراً
        await fetchClasses(branchId);
        await fetchUnassignedChildren(branchId);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error assigning student: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 7. تعيين مدرس
  Future<bool> assignTeacher({
    required int classId,
    required int empId,
    required int branchId,
    String? notes,
    required String userAdd,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.assignTeacherToClass(
        classId: classId,
        empId: empId,
        notes: notes,
        userAdd: userAdd,
      );

      if (result['success'] == true) {
        await fetchClasses(branchId);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error assigning teacher: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 8. إلغاء تكليف مدرس 🆕
  Future<bool> removeTeacher({
    required int assignId,
    required int branchId,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.removeTeacherFromClass(assignId);

      if (result['success'] == true) {
        await fetchClasses(branchId);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error removing teacher: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 9. تحديث كل البيانات مرة واحدة
  Future<void> refreshAll(int branchId) async {
    await Future.wait([
      fetchClasses(branchId),
      fetchUnassignedChildren(branchId),
    ]);
  }

  /// 10. مسح البيانات (عند تسجيل الخروج مثلاً)
  void clearData() {
    _classes = [];
    _unassignedChildren = [];
    _selectedClass = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
    // ==================== Class Details Methods ====================

  /// جلب أطفال الفصل (المسكنين حالياً)
  Future<void> fetchClassChildren(int classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _classChildren = await ApiService.getClassChildren(classId);
    } catch (e) {
      debugPrint("Error fetching class children: $e");
      _classChildren = [];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب سجل الفصل (الأطفال السابقين)
  Future<void> fetchClassHistory(int classId) async {
    try {
      _classHistory = await ApiService.getClassHistory(classId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching class history: $e");
      _classHistory = [];
    }
  }

  /// جلب الفصول المتاحة للنقل
  Future<void> fetchAvailableClassesForTransfer(int classId) async {
    try {
      _availableClassesForTransfer = await ApiService.getAvailableClassesForTransfer(classId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching available classes: $e");
      _availableClassesForTransfer = [];
    }
  }
  
  /// جلب إحصائيات الفصل
Future<void> fetchClassStatistics(int classId) async {
  try {
    _classStatistics = await ApiService.getClassStatistics(classId);
    notifyListeners();
  } catch (e) {
    debugPrint("Error fetching class statistics: $e");
    _classStatistics = null;
  }
 }

  /// نقل طفل لفصل آخر
  Future<bool> transferStudent({
    required int childId,
    required int fromClassId,
    required int toClassId,
    required int branchId,
    String? notes,
    required String userAdd,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.transferStudent(
        childId: childId,
        fromClassId: fromClassId,
        toClassId: toClassId,
        notes: notes,
        userAdd: userAdd,
      );

      if (result['success'] == true) {
        // تحديث البيانات
        await Future.wait([
          fetchClasses(branchId),
          fetchClassChildren(fromClassId),
        ]);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error transferring student: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// إخراج طفل من الفصل
  Future<bool> removeStudentFromClass({
    required int historyId,
    required int classId,
    required int branchId,
    required String userEdit,
  }) async {
    try {
      _setLoading(true);

      final result = await ApiService.removeStudentFromClass(
        historyId: historyId,
        userEdit: userEdit,
      );

      if (result['success'] == true) {
        // تحديث البيانات
        await Future.wait([
          fetchClasses(branchId),
          fetchClassChildren(classId),
          fetchUnassignedChildren(branchId),
        ]);
        return true;
      }

      _setError(result['message']);
      return false;
    } catch (e) {
      debugPrint("Error removing student: $e");
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchClassDetails(int classId) async {
  await Future.wait([
    fetchClassChildren(classId),
    fetchClassHistory(classId),
    fetchAvailableClassesForTransfer(classId),
    fetchClassStatistics(classId),
  ]);
}

  /// مسح بيانات تفاصيل الفصل
  void clearClassDetails() {
  _classChildren = [];
  _classHistory = [];
  _availableClassesForTransfer = [];
  _classStatistics = null;
  notifyListeners();
}

}