import 'package:flutter/material.dart';

class RefreshService extends ChangeNotifier {
  // Singleton instance
  static final RefreshService _instance = RefreshService._internal();
  factory RefreshService() => _instance;
  RefreshService._internal();

  static RefreshService get instance => _instance;

  void refreshDashboard() {
    print('🔄 Refresh triggered in RefreshService');
    notifyListeners();
  }

}
