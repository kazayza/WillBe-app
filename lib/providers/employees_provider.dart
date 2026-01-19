import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/employee_model.dart';

class EmployeesProvider with ChangeNotifier {
  List<Employee> _employees = [];
  
  // قوائم الفلاتر
  List<dynamic> _branches = [];
  List<dynamic> _jobs = [];
  List<dynamic> _workerTypes = [];

  bool _isLoading = false;

  List<Employee> get employees => _employees;
  List<dynamic> get branches => _branches;
  List<dynamic> get jobs => _jobs;
  List<dynamic> get workerTypes => _workerTypes;
  bool get isLoading => _isLoading;

  // 1. جلب الموظفين (إرسال الفلاتر للباك اند)
  Future<void> fetchEmployees({
    String? query,
    bool? isActive, // true=نشط, false=غير نشط, null=الكل
    int? branchId,
    String? jobTitle,
    int? workerTypeId
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // بناء رابط الاستعلام بالفلاتر (Query Parameters)
      String url = 'employees?';
      
      // ملاحظة: الباك اند بيفترض activeOnly=true لو مبعتناش حاجة
      // فإحنا هنبعت القيمة الصريحة
      if (isActive != null) {
        url += 'activeOnly=$isActive&';
      } else {
        url += 'activeOnly=null&'; // عشان الباك اند يجيب الكل
      }

      if (query != null && query.isNotEmpty) url += 'search=$query&';
      if (branchId != null) url += 'branchId=$branchId&';
      if (jobTitle != null) url += 'jobTitle=$jobTitle&';
      if (workerTypeId != null) url += 'workerTypeId=$workerTypeId&';

      // إزالة آخر علامة & لو موجودة (اختياري، المتصفح بيعالجها)
      if (url.endsWith('&')) url = url.substring(0, url.length - 1);

      final data = await ApiService.get(url);
      _employees = (data as List).map((e) => Employee.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching employees: $e");
      _employees = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. جلب القوائم (من المصادر الصحيحة)
  Future<void> fetchLookups() async {
    try {
      // الفروع
      _branches = await ApiService.get('expenses/branches');
      
      // الوظائف (من جدول الموظفين الفعليين)
      // ملاحظة: تأكد إنك ضفت الروت ده في الباك اند: router.get('/jobs', ...)
      _jobs = await ApiService.get('employees/jobs'); 
      
      // أنواع العمالة
      _workerTypes = await ApiService.get('general/worker-types');
      
      notifyListeners();
    }  catch (e, stackTrace) { // 👈 لازم نعرفه هنا الأول
      print("Error fetching employees: $e");
      print(stackTrace); 
      _employees = [];
    }
  }
   
    // جلب بيانات موظف للتعديل
  Future<Map<String, dynamic>?> fetchEmployeeById(int id) async {
    try {
      return await ApiService.getEmployeeById(id);
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  // 4. تعديل بيانات موظف
  Future<bool> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      print("Updating Employee ($id): $data");
      
      // بنستخدم دالة PUT اللي ضفناها في ApiService
      await ApiService.put('employees/$id', data);
      
      // تحديث القائمة عشان التعديل يظهر
      await fetchEmployees(isActive: null);
      
      return true;
    } catch (e) {
      print("Error updating employee: $e");
      return false;
    }
  }
  
  // 3. إضافة موظف
 Future<bool> addEmployee(Map<String, dynamic> data) async {
    try {
      // طباعة البيانات المرسلة للتأكد
      print("Sending Data: $data");

      await ApiService.post('employees', data);
      
      // تحديث القائمة بعد الإضافة
      await fetchEmployees(isActive: null); 
      return true;
    } catch (e) {
      // 👇 اطبع الخطأ عشان نشوفه في التيرمنال
      print("Error adding employee: $e");
      return false;
    }
  }
  }