import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // الرابط الأساسي
  static const String baseUrl = "https://willbee-backend.vercel.app/api";

  // ==================== HEADERS ====================
  static Future<Map<String, String>> _getHeaders() async {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // ==================== AUTH ====================

  /// تسجيل الدخول
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          "UserName": username,
          "Password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data));
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'فشل الدخول');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // ==================== GENERIC METHODS ====================

  /// GET Request
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('GET Error [$endpoint]: $e');
      throw Exception('Network Error: $e');
    }
  }

  /// POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('POST Error [$endpoint]: $e');
      throw Exception('Network Error: $e');
    }
  }

  /// PUT Request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('PUT Error [$endpoint]: $e');
      throw Exception('Network Error: $e');
    }
  }

  /// DELETE Request (تدعم مع body أو بدون)
static Future<dynamic> delete(String endpoint, [Map<String, dynamic>? body]) async {
  try {
    if (body != null && body.isNotEmpty) {
      // DELETE with body
      final request = http.Request('DELETE', Uri.parse('$baseUrl/$endpoint'));
      request.headers.addAll(await _getHeaders());
      request.body = jsonEncode(body);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error ${response.statusCode}');
      }
    } else {
      // DELETE without body
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true};
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    }
  } catch (e) {
    debugPrint('DELETE Error [$endpoint]: $e');
    rethrow;
  }
}

  // ==================== EXPENSES - المصروفات ====================

  /// جلب كل المصروفات
  static Future<List<dynamic>> getExpenses() async {
    try {
      final response = await get('expenses');
      if (response is List) {
        return response;
      } else if (response is Map && response['data'] != null) {
        return response['data'];
      }
      return [];
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      throw Exception('فشل تحميل المصروفات: $e');
    }
  }

  /// جلب مصروف واحد بالـ ID
  static Future<Map<String, dynamic>> getExpenseById(int id) async {
    try {
      final response = await get('expenses/$id');
      return response;
    } catch (e) {
      debugPrint('Error loading expense: $e');
      throw Exception('فشل تحميل المصروف: $e');
    }
  }

  /// إضافة مصروف جديد
  static Future<dynamic> addExpense(Map<String, dynamic> data) async {
    try {
      final response = await post('expenses', data);
      return response;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      throw Exception('فشل إضافة المصروف: $e');
    }
  }

  /// تعديل مصروف
  static Future<dynamic> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final response = await put('expenses/$id', data);
      return response;
    } catch (e) {
      debugPrint('Error updating expense: $e');
      throw Exception('فشل تعديل المصروف: $e');
    }
  }

  /// حذف مصروف
  static Future<dynamic> deleteExpense(int id) async {
    try {
      final response = await delete('expenses/$id');
      return response;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      throw Exception('فشل حذف المصروف: $e');
    }
  }

  // ==================== EXPENSE KINDS - أنواع المصروفات ====================

  /// جلب أنواع المصروفات ✅ تم التصحيح
  static Future<List<dynamic>> getExpenseKinds() async {
    try {
      final response = await get('expenses/kinds');  // ✅ الصح
      if (response is List) {
        return response;
      } else if (response is Map && response['data'] != null) {
        return response['data'];
      }
      return [];
    } catch (e) {
      debugPrint('Error loading expense kinds: $e');
      return [];
    }
  }

  // ==================== BRANCHES - الفروع ====================

  /// جلب الفروع ✅ تم التصحيح
  static Future<List<dynamic>> getBranches() async {
    try {
      final response = await get('expenses/branches');  // ✅ الصح
      if (response is List) {
        return response;
      } else if (response is Map && response['data'] != null) {
        return response['data'];
      }
      return [];
    } catch (e) {
      debugPrint('Error loading branches: $e');
      return [];
    }
  }

  // ==================== EMPLOYEES - الموظفين ====================

  /// جلب كل الموظفين
  static Future<List<dynamic>> getEmployees() async {
    try {
      final response = await get('employees');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading employees: $e');
      return [];
    }
  }

  /// جلب موظف واحد بالـ ID
  static Future<Map<String, dynamic>> getEmployeeById(int id) async {
    try {
      final response = await get('employees/$id');
      return response;
    } catch (e) {
      debugPrint('Error loading employee: $e');
      throw Exception('فشل تحميل بيانات الموظف');
    }
  }

  // ==================== CHILDREN - الأطفال ====================

  /// جلب الملف المالي لطفل
  static Future<List<dynamic>> getChildFinance(int childId) async {
    try {
      final response = await get('child-finance/$childId');
      if (response is List) return response;
      return [response];
    } catch (e) {
      debugPrint('Error loading child finance: $e');
      return [];
    }
  }

  // ==================== TRANSLATION - الترجمة ====================

  /// ترجمة الأسماء (مجانية)
  static Future<String> translateName(String arabicText) async {
    if (arabicText.trim().isEmpty) return "";

    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=$arabicText&langpair=ar|en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['responseData']['translatedText'] ?? "";
      }
    } catch (e) {
      debugPrint("Translation Error: $e");
    }
    return "";
  }

// ==================== CHANGE PASSWORD ====================

  /// تغيير كلمة المرور
  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await post('users/change-password', {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return response;
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('فشل تغيير كلمة المرور');
    }
  }

  // ==================== FCM TOKEN ====================

  /// تحديث FCM Token للمستخدم
  static Future<void> updateFcmToken(int userId, String token) async {
    try {
      await post('users/update-fcm-token', {
        'userId': userId,
        'fcmToken': token,
      });
      debugPrint('FCM Token updated successfully');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

    // ==================== NOTIFICATIONS - الإشعارات ====================

  /// جلب إشعارات المستخدم
  static Future<List<dynamic>> getNotifications(int userId) async {
    try {
      final response = await get('notifications/$userId');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  /// تعليم إشعار كمقروء
  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await put('notifications/$notificationId/read', {});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// تعليم كل الإشعارات كمقروءة
  static Future<void> markAllNotificationsAsRead(int userId) async {
    try {
      await put('notifications/$userId/read-all', {});
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
  

// ==================== ESHRAF - الجزاءات والمكافآت ====================

/// جلب أنواع المعاملات (خصومات وإضافات)
static Future<List<dynamic>> getEshrafTypes() async {
  try {
    final response = await get('general/eshraf-types');
    if (response is List) {
      return response;
    }
    return [];
  } catch (e) {
    debugPrint('Error loading eshraf types: $e');
    return [];
  }
}

/// إضافة جزاء أو مكافأة جديدة
static Future<dynamic> addEshraf(Map<String, dynamic> data) async {
  try {
     // ✅ إضافة التوقيت المحلي
    data['localTime'] = DateTime.now().toIso8601String();

    final response = await post('eshraf', data);
    return response;
  } catch (e) {
    debugPrint('Error adding eshraf: $e');
    throw Exception('فشل إضافة المعاملة: $e');
  }
}

/// جلب سجل معاملات موظف (جزاءات ومكافآت)
static Future<List<dynamic>> getEmployeePenalties(int empId) async {
  try {
    final response = await get('eshraf/$empId');
    if (response is List) {
      return response;
    }
    return [];
  } catch (e) {
    debugPrint('Error loading employee penalties: $e');
    return [];
  }
}

  /// حذف معاملة
  static Future<void> deleteEshraf(int id) async {
    await delete('eshraf/$id');
  }

  /// تعديل معاملة
  static Future<void> updateEshraf(int id, Map<String, dynamic> data) async {
     // ✅ إضافة التوقيت المحلي
  data['localTime'] = DateTime.now().toIso8601String();
    await put('eshraf/$id', data);
  }

    // ==================== ESHRAF HISTORY ====================

  /// بحث في سجل الجزاءات والمكافآت
  static Future<List<dynamic>> searchEshraf({
    int? empId,
    DateTime? fromDate,
    DateTime? toDate,
    String? kind,
  }) async {
    String query = 'eshraf/search?'; // ✅ الرابط الجديد

    if (empId != null) query += 'empId=$empId&';
    if (fromDate != null) query += 'fromDate=${fromDate.toIso8601String()}&';
    if (toDate != null) query += 'toDate=${toDate.toIso8601String()}&';
    if (kind != null) query += 'kind=$kind&';

    try {
      final response = await get(query); // استخدام get الموجودة في الكلاس
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      debugPrint('Error searching eshraf: $e');
      throw Exception('فشل البحث في السجلات');
    }
  }
  
    /// تسجيل سلفة مع أقساطها
  
static Future<dynamic> addLoanWithInstallments({
  required int empId,
  required double loanAmount,
  required DateTime loanDate,  // ✅ DateTime مش String
  required String user,
  String? notes,
  required List<Map<String, dynamic>> installments,
}) async {
  return await post('eshraf/loan', {
    'empId': empId,
    'loanAmount': loanAmount,
    'loanDate': loanDate.toIso8601String(),  // ✅ هنا بنحولها لـ String
    'notes': notes ?? '',
    'user': user,
    'installments': installments,
    'localTime': DateTime.now().toIso8601String(),
  });
}
  
  /// جلب عدد الإشعارات غير المقروءة
  static Future<int> getUnreadNotificationsCount(int userId) async {
    try {
      final notifications = await getNotifications(userId);
      return notifications.where((n) => n['IsRead'] == false || n['IsRead'] == 0).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

    // ==================== GENERIC PATCH ====================

  /// PATCH Request
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('PATCH Error [$endpoint]: $e');
      throw Exception('Network Error: $e');
    }
  }

  // ==================== INSTALLMENTS - الأقساط ====================

/// إنشاء أقساط جديدة
static Future<dynamic> createInstallments({
  required int financeId,
  required List<Map<String, dynamic>> installments,
  required String userAdd,
  required DateTime addTime,
}) async {
  try {
    final response = await post('child-payments/installments', {
      'financeId': financeId,
      'installments': installments,
      'userAdd': userAdd,
      'addTime': addTime.toIso8601String(),
    });
    return {'success': true, 'message': response['message'] ?? 'تم إنشاء الأقساط بنجاح'};
  } catch (e) {
    debugPrint('Error creating installments: $e');
    return {'success': false, 'message': 'فشل إنشاء الأقساط: $e'};
  }
}

/// جلب أقساط اشتراك معين
static Future<List<dynamic>> getInstallmentsByFinanceId(int financeId) async {
  try {
    final response = await get('child-payments/installments/$financeId');
    if (response is List) {
      return response;
    }
    return [];
  } catch (e) {
    debugPrint('Error loading installments: $e');
    return [];
  }
}

/// تعديل قسط
static Future<dynamic> updateInstallment({
  required int id,
  required double amount,
  required DateTime date,
  String? notes,
  required String userEdit,
  required DateTime editTime,
}) async {
  try {
    final response = await put('child-payments/installments/$id', {
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'useredit': userEdit,
      'editTime': editTime.toIso8601String(),
    });
    return {'success': true, 'message': response['message'] ?? 'تم تعديل القسط بنجاح'};
  } catch (e) {
    debugPrint('Error updating installment: $e');
    return {'success': false, 'message': 'فشل تعديل القسط: $e'};
  }
}

/// حذف قسط
static Future<dynamic> deleteInstallment(int id) async {
  try {
    final response = await delete('child-payments/installments/$id');
    return {'success': true, 'message': response['message'] ?? 'تم حذف القسط بنجاح'};
  } catch (e) {
    debugPrint('Error deleting installment: $e');
    return {'success': false, 'message': 'فشل حذف القسط: $e'};
  }
}

/// حذف كل أقساط اشتراك معين
static Future<dynamic> deleteAllInstallments(int financeId) async {
  try {
    final response = await delete('child-payments/installments/finance/$financeId');
    return {'success': true, 'message': response['message'] ?? 'تم حذف الأقساط بنجاح'};
  } catch (e) {
    debugPrint('Error deleting all installments: $e');
    return {'success': false, 'message': 'فشل حذف الأقساط: $e'};
  }
}

/// تسجيل دفع قسط
static Future<dynamic> payInstallment({
  required int id,
  String? notes,
  required String userEdit,
  required DateTime editTime,
}) async {
  try {
    final response = await put('child-payments/pay/$id', {
      'notes': notes,
      'useredit': userEdit,
      'editTime': editTime.toIso8601String(),
    });
    return {'success': true, 'message': response['message'] ?? 'تم تسجيل الدفع بنجاح'};
  } catch (e) {
    debugPrint('Error paying installment: $e');
    return {'success': false, 'message': 'فشل تسجيل الدفع: $e'};
  }
}

// ==================== SUBSCRIPTION PAYMENT - تحصيل اشتراك الدراسة ====================

/// جلب بيانات اشتراك طفل مع الأقساط والمدفوعات
static Future<Map<String, dynamic>> getChildSubscriptionDetails({
  required int childId,
  required int sessionId,
  String type = 'study',
}) async {
  try {
    
    final response = await get('incomes/subscription/$childId/$sessionId/$type');
    return {
      'success': true,
      'data': response['data'],
    };
  } catch (e) {
    debugPrint('Error getting subscription details: $e');
    return {
      'success': false,
      'message': 'فشل جلب بيانات الاشتراك: $e',
    };
  }
}

/// تحصيل اشتراك دراسة (مع تحديث القسط لو موجود)
static Future<Map<String, dynamic>> addSubscriptionPayment({
  required double amount,
  required int childId,
  required int branchId,
  required int sessionId,  // ⭐ العام المالي
  int? kindId,
  String? receiptNo,
  String? notes,
  int? installmentId,
  required String userAdd,
  required DateTime addTime,
  required DateTime payDate,
}) async {
  try {
    final response = await post('incomes/subscription', {
      'amount': amount,
      'childId': childId,
      'branchId': branchId,
      'sessionId': sessionId,  // ⭐ العام المالي
      'kindId': kindId ?? 6,
      'receiptNo': receiptNo,
      'notes': notes,
      'installmentId': installmentId,
      'userAdd': userAdd,
      'addTime': addTime.toIso8601String(),
      'payDate': payDate.toIso8601String(),
    });
    return {
      'success': true,
      'message': response['message'] ?? 'تم التحصيل بنجاح',
      'id': response['id'],
    };
  } catch (e) {
    debugPrint('Error adding subscription payment: $e');
    return {
      'success': false,
      'message': 'فشل التحصيل: $e',
    };
  }
}

/// تحصيل إيراد عام (كورسات، أنشطة، مبيعات)
static Future<Map<String, dynamic>> addGeneralIncome({
  required double amount,
  required int childId,
  required int branchId,
  required int kindId,
  required int sessionId,
  String? receiptNo,
  String? notes,
  required String userAdd,
  required DateTime addTime,
  required DateTime payDate,
}) async {
  try {
    final response = await post('incomes/general', {
      'amount': amount,
      'childId': childId,
      'branchId': branchId,
      'kindId': kindId,
      'sessionId': sessionId,
      'receiptNo': receiptNo,
      'notes': notes,
      'userAdd': userAdd,
      'addTime': addTime.toIso8601String(),
      'payDate': payDate.toIso8601String(),
    });
    return {
      'success': true,
      'message': response['message'] ?? 'تم التحصيل بنجاح',
      'id': response['id'],
    };
  } catch (e) {
    debugPrint('Error adding general income: $e');
    return {
      'success': false,
      'message': 'فشل التحصيل: $e',
    };
  }
}

// ==================== INCOMES - الإيرادات ====================

/// جلب كل الإيرادات
static Future<List<dynamic>> getAllIncomes() async {
  try {
    final response = await get('incomes');
    if (response is List) return response;
    return [];
  } catch (e) {
    debugPrint('Error loading incomes: $e');
    return [];
  }
}

/// فلترة الإيرادات
static Future<List<dynamic>> filterIncomes({
  int? sessionId,
  int? branchId,
  int? kindId,
  int? childId,
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  String query = 'incomes/filter?';
  if (sessionId != null) query += 'sessionId=$sessionId&';
  if (branchId != null) query += 'branchId=$branchId&';
  if (kindId != null) query += 'kindId=$kindId&';
  if (childId != null) query += 'childId=$childId&';
  if (fromDate != null) query += 'fromDate=${fromDate.toIso8601String()}&';
  if (toDate != null) query += 'toDate=${toDate.toIso8601String()}&';

  try {
    final response = await get(query);
    if (response is List) return response;
    return [];
  } catch (e) {
    debugPrint('Error filtering incomes: $e');
    return [];
  }
}

/// حذف إيراد
static Future<Map<String, dynamic>> deleteIncome(int id) async {
  try {
    final response = await delete('incomes/$id');
    return {
      'success': true,
      'message': response['message'] ?? 'تم الحذف بنجاح',
    };
  } catch (e) {
    debugPrint('Error deleting income: $e');
    return {
      'success': false,
      'message': 'فشل الحذف: $e',
    };
  }
}
   // ==================== CLASSES & ASSIGNMENT - الفصول والتوزيع ====================

/// 1. جلب لوحة تحكم الفصول (داشبورد)
static Future<List<dynamic>> getClassesDashboard(int branchId) async {
  try {
    final response = await get('classes/dashboard?branchId=$branchId');
    
    // ✅ التعامل مع الـ Response الجديد
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    // للتوافق مع القديم لو رجع List مباشرة
    if (response is List) return response;
    
    return [];
  } catch (e) {
    debugPrint('Error loading classes dashboard: $e');
    throw Exception('فشل تحميل بيانات الفصول: $e');
  }
}

/// 2. تسكين أو نقل طالب
static Future<Map<String, dynamic>> assignStudentToClass({
  required int childId,
  required int classId,
  String? notes,
  required String userAdd,
}) async {
  try {
    final response = await post('classes/assign-student', {
      'childId': childId,
      'classId': classId,
      'notes': notes,
      'userAdd': userAdd,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم التسكين بنجاح',
    };
  } catch (e) {
    debugPrint('Error assigning student: $e');
    rethrow;
  }
}

/// 3. تعيين مدرس لفصل
static Future<Map<String, dynamic>> assignTeacherToClass({
  required int classId,
  required int empId,
  String? notes,
  required String userAdd,
}) async {
  try {
    final response = await post('classes/assign-teacher', {
      'classId': classId,
      'empId': empId,
      'notes': notes,
      'userAdd': userAdd,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم تعيين المدرس بنجاح',
    };
  } catch (e) {
    debugPrint('Error assigning teacher: $e');
    rethrow;
  }
}

/// 4. إلغاء تكليف مدرس ✅ (Route جديد)
static Future<Map<String, dynamic>> removeTeacherFromClass(int assignId) async {
  try {
    final response = await patch('classes/teacher/$assignId/deactivate', {});
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم إلغاء التكليف',
    };
  } catch (e) {
    debugPrint('Error removing teacher: $e');
    rethrow;
  }
}

/// 5. جلب الأطفال غير المسكنين
static Future<List<dynamic>> getUnassignedChildren(int branchId) async {
  try {
    final response = await get('classes/unassigned?branchId=$branchId');
    
    // ✅ التعامل مع الـ Response الجديد
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    if (response is List) return response;
    
    return [];
  } catch (e) {
    debugPrint('Error loading unassigned children: $e');
    return [];
  }
}

/// 6. إضافة فصل جديد ✅ (Route جديد)
static Future<Map<String, dynamic>> addClass({
  required String className,
  required int branchId,
  required int capacity,
  String? notes,
  required String userAdd,
}) async {
  try {
    // ✅ الـ Route اتغير من 'classes/add' إلى 'classes/'
    final response = await post('classes', {
      'className': className,
      'branchId': branchId,
      'capacity': capacity,
      'notes': notes,
      'userAdd': userAdd,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم إضافة الفصل بنجاح',
      'classId': response['classId'],
    };
  } catch (e) {
    debugPrint('Error adding class: $e');
    rethrow;
  }
}

/// 7. تعديل بيانات فصل ✅ (Route جديد)
static Future<Map<String, dynamic>> updateClass({
  required int classId,
  required String className,
  required int capacity,
  String? notes,
  bool? isActive,
  required String userEdit,
}) async {
  try {
    // ✅ الـ Route اتغير من 'classes/update/$classId' إلى 'classes/$classId'
    final response = await put('classes/$classId', {
      'className': className,
      'capacity': capacity,
      'notes': notes,
      'isActive': isActive,
      'userEdit': userEdit,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم تعديل الفصل بنجاح',
    };
  } catch (e) {
    debugPrint('Error updating class: $e');
    rethrow;
  }
}

/// 8. جلب فصل واحد بالـ ID 🆕 (جديدة)
static Future<Map<String, dynamic>?> getClassById(int classId) async {
  try {
    final response = await get('classes/$classId');
    
    if (response is Map && response['success'] == true) {
      return response['data'];
    }
    return null;
  } catch (e) {
    debugPrint('Error loading class: $e');
    return null;
  }
}
 // ==================== CLASS DETAILS - تفاصيل الفصل ====================

/// جلب أطفال الفصل (المسكنين حالياً)
static Future<List<dynamic>> getClassChildren(int classId) async {
  try {
    final response = await get('classes/$classId/children');
    
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    if (response is List) return response;
    
    return [];
  } catch (e) {
    debugPrint('Error loading class children: $e');
    throw Exception('فشل تحميل بيانات الأطفال: $e');
  }
}

/// جلب سجل الفصل (الأطفال السابقين)
static Future<List<dynamic>> getClassHistory(int classId) async {
  try {
    final response = await get('classes/$classId/history');
    
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    if (response is List) return response;
    
    return [];
  } catch (e) {
    debugPrint('Error loading class history: $e');
    throw Exception('فشل تحميل السجل: $e');
  }
}

/// جلب الفصول المتاحة للنقل
static Future<List<dynamic>> getAvailableClassesForTransfer(int classId) async {
  try {
    final response = await get('classes/$classId/available-for-transfer');
    
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    if (response is List) return response;
    
    return [];
  } catch (e) {
    debugPrint('Error loading available classes: $e');
    throw Exception('فشل تحميل الفصول: $e');
  }
}

/// نقل طفل لفصل آخر
static Future<Map<String, dynamic>> transferStudent({
  required int childId,
  required int fromClassId,
  required int toClassId,
  String? notes,
  required String userAdd,
}) async {
  try {
    final response = await post('classes/transfer-student', {
      'childId': childId,
      'fromClassId': fromClassId,
      'toClassId': toClassId,
      'notes': notes,
      'userAdd': userAdd,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم النقل بنجاح',
    };
  } catch (e) {
    debugPrint('Error transferring student: $e');
    rethrow;
  }
}

/// إخراج طفل من الفصل
static Future<Map<String, dynamic>> removeStudentFromClass({
  required int historyId,
  required String userEdit,
}) async {
  try {
    final response = await delete('classes/student/$historyId', {
      'userEdit': userEdit,
    });
    return {
      'success': response['success'] ?? true,
      'message': response['message'] ?? 'تم الإخراج بنجاح',
    };
  } catch (e) {
    debugPrint('Error removing student: $e');
    rethrow;
  }
}

  // ==================== ATTENDANCE - الغياب ====================

  

  /// جلب إحصائيات الفصل
static Future<Map<String, dynamic>?> getClassStatistics(int classId) async {
  try {
    final response = await get('classes/$classId/statistics');
    
    if (response is Map && response['success'] == true) {
      return Map<String, dynamic>.from(response['data']);
    }
    return null;
  } catch (e) {
    debugPrint('Error loading class statistics: $e');
    return null;
  }
}
  // ==================== ATTENDANCE - الغياب ====================

  /// 1. جلب طلاب الفصل مع حالة الغياب ليوم محدد
  static Future<List<dynamic>> getStudentsForAttendance({
    required int classId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // بنبعت التاريخ بس YYYY-MM-DD
      final response = await get('absence/class-students?classId=$classId&date=$dateStr');
      if (response is List) return response;
      return [];
    } catch (e) {
      debugPrint('Error loading students for attendance: $e');
      throw Exception('فشل تحميل قائمة الطلاب');
    }
  }

  /// 2. تسجيل الغياب (للغائبين فقط)
   static Future<Map<String, dynamic>> saveAbsence({
    required DateTime date,
    required String user,
    required String actionTime,
    required List<Map<String, dynamic>> absentChildren,
    required int classId, // 👈 معامل جديد
  }) async {
    try {
      final response = await post('absence/save', {
        'date': date.toIso8601String(),
        'user': user,
        'actionTime': actionTime,
        'absentChildren': absentChildren,
        'classId': classId, // 👈 بنبعته هنا
      });
      return {'success': true, 'message': response['message']};
    } catch (e) {
      rethrow;
    }
  }
    /// تقرير الغياب (إضافي للتقارير)
   /// تقرير الغياب المتقدم
  static Future<List<dynamic>> getAbsenceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    int? classId,
    int? childId,
  }) async {
    String query = 'absence/report?';
    
    // بناء الرابط
    if (fromDate != null) query += 'fromDate=${fromDate.toIso8601String()}&';
    if (toDate != null) query += 'toDate=${toDate.toIso8601String()}&';
    if (branchId != null) query += 'branchId=$branchId&';
    if (classId != null) query += 'classId=$classId&';
    if (childId != null) query += 'childId=$childId&';

    try {
      final response = await get(query);
      if (response is List) return response;
      return [];
    } catch (e) {
      debugPrint('Error loading absence report: $e');
      return [];
    }
  }
    // ==================== FINANCIAL SETTINGS - الإعدادات المالية ====================

  /// جلب الأنواع (إيرادات أو مصروفات)
  static Future<List<dynamic>> getFinancialKinds({required bool isIncome}) async {
    final type = isIncome ? 'income-kinds' : 'expense-kinds';
    try {
      final response = await get('financial-settings/$type');
      if (response is List) return response;
      return [];
    } catch (e) {
      return [];
    }
  }

  /// إضافة نوع جديد
  static Future<void> addFinancialKind({required bool isIncome, required String name, required String group}) async {
    final type = isIncome ? 'income-kinds' : 'expense-kinds';
    await post('financial-settings/$type', {'name': name, 'group': group});
  }

  /// تعديل نوع
  static Future<void> updateFinancialKind({required bool isIncome, required int id, required String name, required String group}) async {
    final type = isIncome ? 'income-kinds' : 'expense-kinds';
    await put('financial-settings/$type/$id', {'name': name, 'group': group});
  }

  /// حذف نوع
  static Future<void> deleteFinancialKind({required bool isIncome, required int id}) async {
    final type = isIncome ? 'income-kinds' : 'expense-kinds';
    await delete('financial-settings/$type/$id');
  }
  
  // ==================== DEBTS - المديونيات ====================

/// جلب مديونيات كل الأطفال حسب العام المالي
static Future<List<dynamic>> getAllDebts(int sessionId) async {
  try {
    final response = await get('debts/all/$sessionId');
    if (response is Map && response['success'] == true) {
      return response['data'] ?? [];
    }
    if (response is List) return response;
    return [];
  } catch (e) {
    debugPrint('Error loading debts: $e');
    return [];
  }
}

/// جلب تفاصيل مديونية طفل واحد
static Future<Map<String, dynamic>> getChildDebtDetails({
  required int childId,
  required int sessionId,
}) async {
  try {
    final response = await get('debts/child/$childId/$sessionId');
    return {
      'success': true,
      'data': response['data'],
    };
  } catch (e) {
    debugPrint('Error loading child debt details: $e');
    return {
      'success': false,
      'message': 'فشل جلب تفاصيل المديونية: $e',
    };
  }
}

/// فحص الأقساط المتأخرة وإرسال إشعارات
static Future<Map<String, dynamic>> checkOverdueInstallments() async {
  try {
    final response = await get('debts/check-overdue');
    return {
      'success': true,
      'data': response['data'],
      'message': response['message'],
    };
  } catch (e) {
    debugPrint('Error checking overdue: $e');
    return {
      'success': false,
      'message': 'فشل فحص الأقساط: $e',
    };
  }
}

   /// جلب مؤشرات الأداء المالي (KPI)
  static Future<Map<String, dynamic>> getFinancialKPIs(int sessionId) async {
    try {
      final response = await get('debts/kpi/$sessionId');
      // الـ API بيرجع { success: true, data: { ... } }
      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل جلب البيانات',
        };
      }
    } catch (e) {
      debugPrint('Error loading KPIs: $e');
      return {
        'success': false,
        'message': 'فشل الاتصال: $e',
      };
    }
  }
  
  // مؤشرات الأداء المتقدمة
// ✅ أضف الدالة دي في ApiService
static Future<Map<String, dynamic>> getAdvancedKPIs({
  required int sessionId,
  int? branchId,
  String? type,
}) async {
  try {
    String url = 'debts/advanced-kpi/$sessionId?';
    if (branchId != null) url += 'branchId=$branchId&';
    if (type != null) url += 'type=$type&';

    final response = await get(url);
    return response is Map<String, dynamic> 
        ? response 
        : {'success': false, 'message': 'Invalid response'};
  } catch (e) {
    debugPrint('Error fetching advanced KPIs: $e');
    return {'success': false, 'message': e.toString()};
  }
}
// كليندر الأقساط الشهرية
static Future<Map<String, dynamic>> getMonthlyCalendar({
  required int sessionId,
  int? branchId,
  String? type,
}) async {
  try {
    String url = 'debts/calendar/$sessionId?';
    if (branchId != null) url += 'branchId=$branchId&';
    if (type != null) url += 'type=$type&';

    final response = await get(url);
    return response is Map<String, dynamic>
        ? response
        : {'success': false, 'message': 'Invalid response'};
  } catch (e) {
    debugPrint('Error fetching calendar: $e');
    return {'success': false, 'message': e.toString()};
  }
}

// تفاصيل أقساط شهر معين
static Future<Map<String, dynamic>> getMonthDetails({
  required int sessionId,
  required int month,
  required int year,
  int? branchId,
  String? type,
}) async {
  try {
    String url = 'debts/calendar/$sessionId/$month/$year?';
    if (branchId != null) url += 'branchId=$branchId&';
    if (type != null) url += 'type=$type&';

    final response = await get(url);
    return response is Map<String, dynamic>
        ? response
        : {'success': false, 'message': 'Invalid response'};
  } catch (e) {
    debugPrint('Error fetching month details: $e');
    return {'success': false, 'message': e.toString()};
  }
}
// تفصيلة الشهر الحالي حسب الفروع
static Future<Map<String, dynamic>> getCurrentMonthBranches({
  required int sessionId,
  String? type,
}) async {
  try {
    String url = 'debts/current-month-branches/$sessionId?';
    if (type != null) url += 'type=$type&';

    final response = await get(url);
    return response is Map<String, dynamic>
        ? response
        : {'success': false, 'message': 'Invalid response'};
  } catch (e) {
    debugPrint('Error fetching current month branches: $e');
    return {'success': false, 'message': e.toString()};
  }
}

// جلب بيانات قسط معين بالـ ID
static Future<Map<String, dynamic>> getInstallmentDetails(int installmentId) async {
  try {
    final response = await get('debts/installment-details/$installmentId');
    return response is Map<String, dynamic>
        ? response
        : {'success': false, 'message': 'Invalid response'};
  } catch (e) {
    debugPrint('Error fetching installment details: $e');
    return {'success': false, 'message': e.toString()};
  }
}

/// جلب خطوط الباص
static Future<List<dynamic>> getBusLines() async {
  try {
    final response = await get('bus-lines');
    return response as List<dynamic>;
  } catch (e) {
    debugPrint('Error getting bus lines: $e');
    return [];
  }
}

/// جلب أطفال خط باص معين
static Future<Map<String, dynamic>> getBusLineChildren({
  required int busLineId,
  required int sessionId,
}) async {
  try {
    final response = await get('bus-lines/children/$busLineId/$sessionId');
    return {
      'success': true,
      'count': response['count'],
      'data': response['data'],
    };
  } catch (e) {
    debugPrint('Error getting bus children: $e');
    return {
      'success': false,
      'message': 'فشل جلب البيانات: $e',
    };
  }
}

/// إضافة خط باص جديد
static Future<Map<String, dynamic>> addBusLine(String busLine) async {
  try {
    final response = await post('bus-lines', {'busLine': busLine});
    return {
      'success': true,
      'message': response['message'] ?? 'تم الإضافة بنجاح',
      'id': response['id'],
    };
  } catch (e) {
    debugPrint('Error adding bus line: $e');
    return {
      'success': false,
      'message': 'فشل الإضافة: $e',
    };
  }
}

/// تعديل خط باص
static Future<Map<String, dynamic>> updateBusLine(int id, String busLine) async {
  try {
    final response = await put('bus-lines/$id', {'busLine': busLine});
    return {
      'success': true,
      'message': response['message'] ?? 'تم التعديل بنجاح',
    };
  } catch (e) {
    debugPrint('Error updating bus line: $e');
    return {
      'success': false,
      'message': 'فشل التعديل: $e',
    };
  }
}

}
  