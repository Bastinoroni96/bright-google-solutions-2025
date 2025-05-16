// lib/services/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum NavigationTab {
  dashboard,
  connect,
  scan,
  history,
  replace,
}

class NavigationService extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.dashboard;
  
  NavigationTab get currentTab => _currentTab;
  
  void navigateTo(NavigationTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }
}

// Add this Provider to your MultiProvider list in main.dart
// ChangeNotifierProvider(create: (_) => NavigationService()),