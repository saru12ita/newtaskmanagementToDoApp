

import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // Dark Mode
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Notifications
  bool _isNotificationsEnabled = true;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  void toggleNotifications(bool value) {
    _isNotificationsEnabled = value;
    notifyListeners();
  }

  // Cloud Sync
  bool _isCloudSyncEnabled = false;
  bool get isCloudSyncEnabled => _isCloudSyncEnabled;
  void toggleCloudSync(bool value) {
    _isCloudSyncEnabled = value;
    notifyListeners();
  }

  // Language
  String _selectedLanguage = "English";
  String get selectedLanguage => _selectedLanguage;
  void changeLanguage(String val) {
    _selectedLanguage = val;
    notifyListeners();
  }

  // Clear all tasks (dummy for now, integrate with your task provider)
  void clearAllTasks() {
    // Add your task clearing logic here
    debugPrint("All tasks cleared!");
    notifyListeners();
  }
}
