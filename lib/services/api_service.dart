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

  /// DELETE Request
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');

    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true};
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('DELETE Error [$endpoint]: $e');
      throw Exception('Network Error: $e');
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
}