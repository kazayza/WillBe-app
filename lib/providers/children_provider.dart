import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/child_model.dart';

// 🔽 أنواع الترتيب
enum SortType {
  nameAsc,      // الاسم أ → ي
  nameDesc,     // الاسم ي → أ
  codeAsc,      // الكود 1 → 100
  codeDesc,     // الكود 100 → 1
  dateAsc,      // الأقدم أولاً
  dateDesc,     // الأحدث أولاً
}

class ChildrenProvider with ChangeNotifier {
  List<Child> _children = [];
  List<Child> _allChildren = [];  // 👈 جديد - كل الأطفال بدون فلترة
  List<dynamic> _branches = [];
  List<dynamic> _sessions = [];   // 👈 جديد - السنوات المالية
  bool _isLoading = false;
  
  // 🔽 متغيرات الترتيب والفلترة
  SortType _currentSort = SortType.nameAsc;
  int? _selectedSessionId;

  // Getters
  List<Child> get children => _children;
  List<Child> get allChildren => _allChildren;
  List<dynamic> get branches => _branches;
  List<dynamic> get sessions => _sessions;
  bool get isLoading => _isLoading;
  SortType get currentSort => _currentSort;
  int? get selectedSessionId => _selectedSessionId;
  
  // 👈 جديد - عدد النتائج
  int get totalCount => _allChildren.length;
  int get filteredCount => _children.length;

  // 🧠 دالة تنظيف النص العربي
  String _normalizeArabic(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '');
  }

  // 1️⃣ جلب الأطفال
  // 1️⃣ جلب الأطفال
Future<void> fetchChildren({String? query, int? branchId, int? sessionId}) async {
  _isLoading = true;
  notifyListeners();

  try {
    // بناء الـ endpoint مع الفلتر
    String endpoint = 'children';
    if (sessionId != null) {
      endpoint = 'children?sessionId=$sessionId';
      _selectedSessionId = sessionId;
    }

    final data = await ApiService.get(endpoint);
    var list = (data as List).map((e) => Child.fromJson(e)).toList();

    // حفظ كل الأطفال
    _allChildren = list;

    // فلتر البحث (في الـ Frontend)
    if (query != null && query.isNotEmpty) {
      final normalizedQuery = _normalizeArabic(query.toLowerCase());
      list = list.where((c) {
        final normalizedName = _normalizeArabic(c.fullNameArabic.toLowerCase());
        return normalizedName.contains(normalizedQuery) ||
               c.id.toString().contains(query);
      }).toList();
    }

    // فلتر الفرع (في الـ Frontend)
    if (branchId != null) {
      list = list.where((c) => c.branchId == branchId).toList();
    }

    _children = list;

    // تطبيق الترتيب
    _applySorting();

  } catch (e) {
    print("Error fetching children: $e");
    _children = [];
    _allChildren = [];
  }

  _isLoading = false;
  notifyListeners();
}

  // 2️⃣ تغيير الترتيب
  void setSortType(SortType sortType) {
    _currentSort = sortType;
    _applySorting();
    notifyListeners();
  }

  // 3️⃣ تطبيق الترتيب
  void _applySorting() {
    switch (_currentSort) {
      case SortType.nameAsc:
        _children.sort((a, b) => 
          _normalizeArabic(a.fullNameArabic).compareTo(_normalizeArabic(b.fullNameArabic)));
        break;
      case SortType.nameDesc:
        _children.sort((a, b) => 
          _normalizeArabic(b.fullNameArabic).compareTo(_normalizeArabic(a.fullNameArabic)));
        break;
      case SortType.codeAsc:
        _children.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortType.codeDesc:
        _children.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortType.dateAsc:
        _children.sort((a, b) => 
          (a.addTime ?? '').compareTo(b.addTime ?? ''));
        break;
      case SortType.dateDesc:
        _children.sort((a, b) => 
          (b.addTime ?? '').compareTo(a.addTime ?? ''));
        break;
    }
  }

  // 4️⃣ فلتر السنة المالية
  void setSessionFilter(int? sessionId) {
    _selectedSessionId = sessionId;
    fetchChildren(sessionId: sessionId);
  }

  // 5️⃣ مسح كل الفلاتر
  void clearFilters() {
    _selectedSessionId = null;
    _currentSort = SortType.nameAsc;
    fetchChildren();
  }

  // 6️⃣ جلب الفروع
  Future<void> fetchBranches() async {
    try {
      final data = await ApiService.get('general/branches');
      _branches = data;
      notifyListeners();
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  // 7️⃣ جلب السنوات المالية
  Future<void> fetchSessions() async {
    try {
      final data = await ApiService.get('general/sessions');
      _sessions = data;
      notifyListeners();
    } catch (e) {
      print("Error fetching sessions: $e");
    }
  }

  // 8️⃣ إضافة طفل
  Future<bool> addChild(Map<String, dynamic> childData) async {
    try {
      await ApiService.post('children', childData);
      await fetchChildren();
      return true;
    } catch (e) {
      print("Error adding child: $e");
      return false;
    }
  }

  // 9️⃣ تعديل طفل
  Future<bool> updateChild(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.put('children/$id', data);
      await fetchChildren();
      return true;
    } catch (e) {
      print("Error updating child: $e");
      return false;
    }
  }

  // 🔟 حذف طفل
  Future<bool> deleteChild(int id) async {
    try {
      await ApiService.delete('children/$id');
      await fetchChildren();
      return true;
    } catch (e) {
      print("Error deleting child: $e");
      return false;
    }
  }

  // 1️⃣1️⃣ جلب بيانات طفل
  Future<Map<String, dynamic>?> fetchChildById(int id) async {
    try {
      final data = await ApiService.get('children/$id');
      return data;
    } catch (e) {
      print("Error fetching child details: $e");
      return null;
    }
  }
}