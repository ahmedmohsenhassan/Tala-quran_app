import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsModeService extends ChangeNotifier {
  bool _isKidsModeActive = false;
  bool get isKidsModeActive => _isKidsModeActive;

  KidsModeService() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isKidsModeActive = prefs.getBool('kids_mode_active') ?? false;
    notifyListeners();
  }

  Future<void> toggleKidsMode() async {
    _isKidsModeActive = !_isKidsModeActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kids_mode_active', _isKidsModeActive);
    notifyListeners();
  }

  // Kids Mode Colors
  Color get primaryColor => _isKidsModeActive ? Colors.orangeAccent : const Color(0xFFD4A947); // Gold
  Color get backgroundColor => _isKidsModeActive ? const Color(0xFFFFF9C4) : const Color(0xFF0F291E); // Light yellow vs Deep Green
  Color get cardColor => _isKidsModeActive ? Colors.white : const Color(0xFF163C2C);
}
