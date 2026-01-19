import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/child_model.dart';

class ChildrenProvider with ChangeNotifier {
  List<Child> _children = [];
  List<dynamic> _branches = []; // قائمة الفروع
  bool _isLoading = false;

  List<Child> get children => _children;
  List<dynamic> get branches => _branches;
  bool get isLoading => _isLoading;

  // 🧠 دالة تنظيف النص العربي (تجاهل الهمزات والتاء المربوطة)
  String _normalizeArabic(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا') // توحيد الألف
        .replaceAll('ة', 'ه')             // توحيد التاء المربوطة
        .replaceAll('ى', 'ي')             // توحيد الياء
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), ''); // إزالة التشكيل
  }

  // 1. جلب الأطفال (مع البحث الذكي والفلترة)
  Future<void> fetchChildren({String? query, int? branchId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // بنجيب كل الأطفال من السيرفر
      final data = await ApiService.get('children');
      
      // تحويلهم لـ Objects
      var list = (data as List).map((e) => Child.fromJson(e)).toList();

      // تطبيق فلتر البحث (لو المستخدم كتب حاجة)
      if (query != null && query.isNotEmpty) {
        final normalizedQuery = _normalizeArabic(query.toLowerCase());
        
        list = list.where((c) {
          // بننظف اسم الطفل كمان عشان المقارنة تكون عادلة
          final normalizedName = _normalizeArabic(c.fullNameArabic.toLowerCase());
          return normalizedName.contains(normalizedQuery);
        }).toList();
      }

      // تطبيق فلتر الفرع (لو المستخدم اختار فرع)
      if (branchId != null) {
        // ملاحظة: لو الطفل عنده حقل BranchID في الموديل، فعل السطر ده:
        // list = list.where((c) => c.branchId == branchId).toList();
        list = list.where((c) => c.branchId == branchId).toList();
      }

      _children = list;
    } catch (e) {
      print("Error fetching children: $e");
      _children = []; // تصفية القائمة في حالة الخطأ
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. جلب قائمة الفروع (عشان الفلتر)
  Future<void> fetchBranches() async {
    try {
      final data = await ApiService.get('expenses/branches');
      _branches = data;
      notifyListeners();
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  // 3. إضافة طفل جديد
  // 3. إضافة طفل (بنستقبل Map عشان نبعت كل البيانات)
  Future<bool> addChild(Map<String, dynamic> childData) async { // 👈 غيرنا النوع
    try {
      // مش محتاجين username هنا، لأنه هيكون جوه الـ Map
      await ApiService.post('children', childData);
      await fetchChildren(); 
      return true;
    } catch (e) {
      print("Error adding child: $e");
      return false;
    }
  }

    // 4. تعديل بيانات طفل
  Future<bool> updateChild(int id, Map<String, dynamic> data) async {
    try {
      // بنفترض إن الباك اند بيستقبل PUT على /children/:id
      // لو الباك اند بيستخدم POST للتعديل، غيرها هنا
      // بس في الكود بتاعنا كان PUT
      await ApiService.put('children/$id', data); 
      await fetchChildren(); // تحديث القائمة
      return true;
    } catch (e) {
      print("Error updating child: $e");
      return false;
    }
  }

  // 5. جلب بيانات طفل كاملة (للتعديل)
  Future<Map<String, dynamic>?> fetchChildById(int id) async {
    try {
      final data = await ApiService.get('children/$id');
      return data; // بيرجع Map فيه كل الحقول
    } catch (e) {
      print("Error fetching child details: $e");
      return null;
    }
  }
}