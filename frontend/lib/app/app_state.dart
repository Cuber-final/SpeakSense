import 'package:flutter/material.dart';
import 'package:speaksense_app/app/env.dart';

class AppState extends ChangeNotifier {
  bool _useMockApi = const bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  bool get useMockApi => _useMockApi;
  String get apiBaseUrl => AppEnv.apiBaseUrl;

  void setUseMockApi(bool value) {
    if (_useMockApi == value) {
      return;
    }
    _useMockApi = value;
    notifyListeners();
  }
}
