import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../data/financial_health_repository.dart';
import '../../data/financial_health_summary.dart';

class FinancialHealthProvider extends ChangeNotifier {
  FinancialHealthProvider(this._financialHealthRepository);

  final FinancialHealthRepository _financialHealthRepository;

  FinancialHealthSummary _summary = FinancialHealthSummary.empty();
  bool _isLoading = false;
  String? _errorMessage;

  FinancialHealthSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHealth() => loadFinancialHealth();

  Future<void> loadFinancialHealth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _financialHealthRepository.getFinancialHealthSummary();
    } catch (error, stackTrace) {
      _summary = FinancialHealthSummary.empty();
      _errorMessage = _messageFromError(error);
      debugPrint('[FinancialHealthProvider] load failed: $_errorMessage');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFinancialHealth() => loadFinancialHealth();

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
