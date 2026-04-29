import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../data/dashboard_repository.dart';
import '../../data/dashboard_summary.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._dashboardRepository);

  final DashboardRepository _dashboardRepository;

  DashboardSummary _summary = DashboardSummary.empty();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _dashboardRepository.getDashboardSummary();
    } catch (error, stackTrace) {
      _summary = DashboardSummary.empty();
      _errorMessage = _messageFromError(error);
      debugPrint('[DashboardProvider] loadDashboard failed: $_errorMessage');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() => loadDashboard();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      if (message == null || message.trim().isEmpty) {
        return 'Firebase ${error.code}.';
      }
      return 'Firebase ${error.code}: $message';
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }
}
