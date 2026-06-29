// lib/models/user_model.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';

class UserModel with ChangeNotifier {
  String _name = '';
  String _phoneNumber = '';
  String _role = '';
  String _city = '';

  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get role => _role;
  String get city => _city;

  bool get isAdmin => _role.toLowerCase() == 'admin';
  bool get isLoggedIn => _name.isNotEmpty && _phoneNumber.isNotEmpty;

  void setUser(String name, String phoneNumber, String role,
      {String? city}) async {
    _name = name;
    _phoneNumber = phoneNumber;
    _role = role;
    _city = city ?? '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserName, _name);
    await prefs.setString(AppConstants.prefPhoneNumber, _phoneNumber);
    await prefs.setString(AppConstants.prefRole, _role);
    await prefs.setString(AppConstants.prefCity, _city);
    await prefs.setBool('isLoggedIn', true);
  }

  void clearUser() async {
    _name = '';
    _phoneNumber = '';
    _role = '';
    _city = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(AppConstants.prefUserName) ?? '';
    _phoneNumber = prefs.getString(AppConstants.prefPhoneNumber) ?? '';
    _role = prefs.getString(AppConstants.prefRole) ?? '';
    _city = prefs.getString(AppConstants.prefCity) ?? '';
    notifyListeners();
  }
}
