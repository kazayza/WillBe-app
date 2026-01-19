import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // كانت ناقصة
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  List<Permission> _permissions = [];
  bool _isLoading = false;
  String? _errorMessage;
  

  User? get user => _user;
  List<Permission> get permissions => _permissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get empId => _user?.empId;

  // 1. تسجيل الدخول
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.login(username, password);
      
      _user = User.fromJson(data['user']);

      if (data['permissions'] != null) {
        _permissions = (data['permissions'] as List)
            .map((e) => Permission.fromJson(e))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      notifyListeners();
      return false;
    }
  }

  // 2. التحقق من الصلاحيات
  bool canAdd(String screenName) {
    if (_user?.role == 'Admin' || _user?.role == 'Manager') return true; 
    
    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(screenName: '', canAdd: false, canEdit: false, canDelete: false, canView: false),
    );
    return perm.canAdd;
  }

  // 3. الدخول التلقائي (تذكرني) ✅
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_data')) return false;

    final extractedUserData = jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;
    
    _user = User.fromJson(extractedUserData['user']);
    
    if (extractedUserData['permissions'] != null) {
      _permissions = (extractedUserData['permissions'] as List)
          .map((e) => Permission.fromJson(e))
          .toList();
    }
    
    notifyListeners();
    return true;
  }

  // 4. تسجيل الخروج ✅
  Future<void> logout() async {
    _user = null;
    _permissions = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}