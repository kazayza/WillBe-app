import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<dynamic> _students = []; // قائمة الطلاب
  Set<int> _absentIds = {};     // أرقام الغائبين (Set لمنع التكرار)
  Map<int, String> _notes = {}; // الملاحظات {id: note}
  bool _isLoading = false;

  List<dynamic> get students => _students;
  bool get isLoading => _isLoading;
  int get absentCount => _absentIds.length;
  int get presentCount => _students.length - _absentIds.length;

  // هل الطالب ده غايب؟
  bool isAbsent(int childId) => _absentIds.contains(childId);
  
  // هات الملاحظة لو موجودة
  String getNote(int childId) => _notes[childId] ?? '';

  /// تحميل طلاب الفصل ليوم معين
  Future<void> fetchStudents(int classId, DateTime date) async {
    _isLoading = true;
    _students = []; // تصفير القائمة القديمة
    _absentIds.clear();
    _notes.clear();
    notifyListeners();

    try {
      final data = await ApiService.getStudentsForAttendance(classId: classId, date: date);
      _students = data;

      // ملء الغائبين مسبقاً (لو كنا سجلناهم قبل كده)
      for (var student in data) {
        if (student['IsAbsent'] == 1 || student['IsAbsent'] == true) {
          _absentIds.add(student['ID_Child']);
          if (student['Notes'] != null && student['Notes'].toString().isNotEmpty) {
            _notes[student['ID_Child']] = student['Notes'];
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تبديل حالة الطالب (حضور <-> غياب)
  void toggleAbsence(int childId) {
    if (_absentIds.contains(childId)) {
      _absentIds.remove(childId); // خليه حضور
      _notes.remove(childId);     // امسح الملاحظة
    } else {
      _absentIds.add(childId);    // خليه غياب
    }
    notifyListeners();
  }

  /// تحديث ملاحظة
  void updateNote(int childId, String note) {
    if (note.trim().isEmpty) {
      _notes.remove(childId);
    } else {
      _notes[childId] = note;
    }
    // مش لازم notifyListeners هنا عشان الأداء (إلا لو عاوز تعرض أيقونة ملاحظة)
    notifyListeners();
  }

  /// حفظ الغياب للسيرفر
 Future<bool> saveAttendance(DateTime date, String user, int classId) async { // 👈 استقبل classId
    if (_students.isEmpty) return false; // (ممكن نشيل الشرط ده لو عاوزين نحفظ فصل كله حضور)

    _isLoading = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> absentList = [];
      for (int id in _absentIds) {
        absentList.add({
          'childId': id,
          'notes': _notes[id] ?? '',
        });
      }

      await ApiService.saveAbsence(
        date: date,
        user: user,
        actionTime: DateTime.now().toIso8601String(),
        absentChildren: absentList,
        classId: classId, // 👈 بنمرره للسيرفس
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
    // ==================== REPORT SECTION - قسم التقارير ====================

  List<dynamic> _reportList = []; // المتغير اللي هيشيل التقرير
  List<dynamic> get reportList => _reportList; // الـ Getter عشان الشاشة تقراه

  /// جلب تقرير غياب الأطفال (الدالة الجديدة)
 Future<void> fetchChildrenAbsenceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    int? classId,
    int? childId,
  }) async {
    _isLoading = true;
    _reportList = [];
    notifyListeners();

    try {
      _reportList = await ApiService.getAbsenceReport(
        fromDate: fromDate ?? DateTime.now(), // الافتراضي اليوم
        toDate: toDate ?? DateTime.now(),
        branchId: branchId,
        classId: classId,
        childId: childId,
      );
    } catch (e) {
      _reportList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
    // ==================== CHILD HISTORY - سجل الطفل ====================

  List<dynamic> _childHistory = [];
  List<dynamic> get childHistory => _childHistory;

  /// جلب سجل غياب طفل معين
  Future<void> fetchChildHistory(int childId) async {
    _isLoading = true;
    _childHistory = [];
    notifyListeners();

    try {
      // إحنا لسه ما ضفناش الدالة دي في ApiService، هنضيفها حالاً
      // الرابط: /api/absence/history/:childId
      final response = await ApiService.get('absence/history/$childId');
      if (response is List) {
        _childHistory = response;
      }
    } catch (e) {
      debugPrint("History Error: $e");
      _childHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // دالة مساعدة للإحصائيات (للكروت الملونة)
  int get totalAbsenceDays => _reportList.length;
  // ممكن نضيف دوال تانية هنا لحساب "أكتر فصل" في الفرونت
}