import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData extends ChangeNotifier {
  String? _userId;
  String? _userName;

  String? get userId => _userId;
  String? get userName => _userName;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('id_usuario');
    final savedName = prefs.getString('nome_usuario');
    if (savedId != null && savedName != null) {
      _userId = savedId;
      _userName = savedName;
      notifyListeners();
    }
  }

  Future<void> setUser(String userId, String userName) async {
    _userId = userId;
    _userName = userName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_usuario', userId);
    await prefs.setString('nome_usuario', userName);
    notifyListeners();
  }

  Future<void> clearUser() async {
    _userId = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id_usuario');
    await prefs.remove('nome_usuario');
    notifyListeners();
  }
}