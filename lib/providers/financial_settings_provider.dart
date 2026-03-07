import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FinancialSettingsProvider with ChangeNotifier {
  List<dynamic> _items = [];
  bool _isLoading = false;

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchKinds(bool isIncome) async {
    _isLoading = true;
    // notifyListeners(); // بلاش هنا عشان الوميض
    try {
      _items = await ApiService.getFinancialKinds(isIncome: isIncome);
    } catch (e) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addKind(bool isIncome, String name, String group) async {
    await ApiService.addFinancialKind(isIncome: isIncome, name: name, group: group);
    await fetchKinds(isIncome);
  }

  Future<void> updateKind(bool isIncome, int id, String name, String group) async {
    await ApiService.updateFinancialKind(isIncome: isIncome, id: id, name: name, group: group);
    await fetchKinds(isIncome);
  }

  Future<void> deleteKind(bool isIncome, int id) async {
    await ApiService.deleteFinancialKind(isIncome: isIncome, id: id);
    await fetchKinds(isIncome);
  }
}