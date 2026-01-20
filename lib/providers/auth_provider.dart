import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ==================== PERMISSION METHODS ====================

  // 2. صلاحية الإضافة
  bool canAdd(String screenName) {
    // المدير عنده كل الصلاحيات
    if (_user?.role == 'Admin' || _user?.role == 'Manager' || _user?.role == 'مدير') {
      return true;
    }

    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(
        screenName: '',
        canAdd: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canOpen: false,
      ),
    );
    return perm.canAdd;
  }

  // 3. صلاحية العرض ✅ (جديدة)
  bool canView(String screenName) {
    // المدير عنده كل الصلاحيات
    if (_user?.role == 'Admin' || _user?.role == 'Manager' || _user?.role == 'مدير') {
      return true;
    }

    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(
        screenName: '',
        canAdd: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canOpen: false,
      ),
    );
    return perm.canView;
  }

  // 4. صلاحية التعديل ✅ (جديدة)
  bool canEdit(String screenName) {
    if (_user?.role == 'Admin' || _user?.role == 'Manager' || _user?.role == 'مدير') {
      return true;
    }

    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(
        screenName: '',
        canAdd: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canOpen: false,
      ),
    );
    return perm.canEdit;
  }

  // 5. صلاحية الحذف ✅ (جديدة)
  bool canDelete(String screenName) {
    if (_user?.role == 'Admin' || _user?.role == 'Manager' || _user?.role == 'مدير') {
      return true;
    }

    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(
        screenName: '',
        canAdd: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canOpen: false,
      ),
    );
    return perm.canDelete;
  }

  // 6. صلاحية الفتح ✅ (جديدة)
  bool canOpen(String screenName) {
    // canOpen = canView (نفس المعنى)
    return canView(screenName);
  }

  // 7. التحقق من صلاحية معينة ✅ (جديدة)
  bool hasPermission(String screenName, String action) {
    if (_user?.role == 'Admin' || _user?.role == 'Manager' || _user?.role == 'مدير') {
      return true;
    }

    var perm = _permissions.firstWhere(
      (p) => p.screenName == screenName,
      orElse: () => Permission(
        screenName: '',
        canAdd: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canOpen: false,
      ),
    );

    switch (action) {
      case 'add':
        return perm.canAdd;
      case 'edit':
        return perm.canEdit;
      case 'delete':
        return perm.canDelete;
      case 'view':
        return perm.canView;
      default:
        return false;
    }
  }

  // ==================== AUTO LOGIN & LOGOUT ====================

  // 8. الدخول التلقائي (تذكرني)
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_data')) return false;

    try {
      final extractedUserData =
          jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;

      _user = User.fromJson(extractedUserData['user']);

      if (extractedUserData['permissions'] != null) {
        _permissions = (extractedUserData['permissions'] as List)
            .map((e) => Permission.fromJson(e))
            .toList();
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 9. تسجيل الخروج
  Future<void> logout() async {
    _user = null;
    _permissions = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}