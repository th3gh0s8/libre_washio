import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userDataKey = 'userData';

  // Save user data to SharedPreferences
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String userJson = jsonEncode(userData);
      await prefs.setString(_userDataKey, userJson);
    } catch (e) {
      // Handle potential errors, e.g., by logging them
      print('Error saving user data: $e');
    }
  }

  // Load user data from SharedPreferences
  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString(_userDataKey);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  // Clear user data from SharedPreferences (for logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
