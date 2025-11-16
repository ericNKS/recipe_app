import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/database_helper.dart';
import 'package:recipe_app/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.loginUser(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password) async {
    final user = await _dbHelper.registerUser(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}