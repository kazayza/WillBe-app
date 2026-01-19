import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // الرابط بتاعنا
  static const String baseUrl = "https://willbee-backend.vercel.app/api";

  // دالة خاصة (Private) لتجهيز الهيدر
  static Future<Map<String, String>> _getHeaders() async {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // 1. تسجيل الدخول
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

  // 2. دالة GET
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
      throw Exception('Network Error: $e');
    }
  }

  // 3. دالة POST (اللي كانت ناقصة)
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
      throw Exception('Network Error: $e');
    }
  }

    // 4. دالة ترجمة الأسماء (مجانية)
  static Future<String> translateName(String arabicText) async {
    if (arabicText.trim().isEmpty) return "";

    try {
      // بنستخدم خدمة MyMemory المجانية
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=$arabicText&langpair=ar|en'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // بنرجع النص المترجم
        return data['responseData']['translatedText'] ?? "";
      }
    } catch (e) {
      print("Translation Error: $e");
    }
    return ""; // لو حصل خطأ نرجع نص فاضي
    
  }

  // جلب الملف المالي لطفل
  static Future<List<dynamic>> getChildFinance(int childId) async {
    // هنستخدم الرابط اللي عملناه في الباك اند (بيجيب السجل بالطفل)
    // ملحوظة: الباك اند الحالي getChildSubscription بيرجع سجل واحد (آخر واحد).
    // عشان نعرض "قائمة"، الأفضل نعدل الباك اند يرجع List، أو نستخدم اللي موجود مؤقتاً.
    
    // الحل السريع حالياً: هنجيب السجل المتاح
    try {
      final response = await get('child-finance/$childId');
      
      // لو الباك اند رجع List، رجعها زي ما هي
      if (response is List) return response;
      
      // لو (لسبب ما) رجع Object، حطه جوه List
      return [response];
    } catch (e) {
      return [];
    }
  }



    // جلب موظف واحد بالـ ID
  static Future<Map<String, dynamic>> getEmployeeById(int id) async {
    final response = await get('employees/$id'); // ده هيشتغل لما ترفع الباك اند الجديد
    return response;
  }

  

  // 4. دالة PUT (للتعديل)
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
      throw Exception('Network Error: $e');
    }
  }
}