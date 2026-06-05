import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider extends ChangeNotifier {
  String? _customerId;
  String? _customerName;
  String? _customerPhone;
  bool _isOwner = false;

  String? get customerId => _customerId;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  bool get isOwner => _isOwner;
  bool get isCustomerLoggedIn => _customerId != null;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _customerId = prefs.getString('customerId');
    _customerName = prefs.getString('customerName');
    _customerPhone = prefs.getString('customerPhone');
    _isOwner = prefs.getBool('isOwner') ?? false;
    notifyListeners();
  }

  Future<void> loginCustomer(
      String id, String name, String phone) async {
    _customerId = id;
    _customerName = name;
    _customerPhone = phone;
    _isOwner = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customerId', id);
    await prefs.setString('customerName', name);
    await prefs.setString('customerPhone', phone);
    await prefs.setBool('isOwner', false);
    notifyListeners();
  }

  Future<void> loginOwner() async {
    _isOwner = true;
    _customerId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOwner', true);
    await prefs.remove('customerId');
    notifyListeners();
  }

  Future<void> logout() async {
    _customerId = null;
    _customerName = null;
    _customerPhone = null;
    _isOwner = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
