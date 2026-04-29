import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../data/monthly_report_summary.dart';
import '../../data/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._reportsRepository) {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _reportSummary = MonthlyReportSummary.empty(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  final ReportsRepository _reportsRepository;

  late int _selectedMonth;
  late int _selectedYear;
  late MonthlyReportSummary _reportSummary;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  MonthlyReportSummary get reportSummary => _reportSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MonthlyReportSummary> get reports => [_reportSummary];

  Future<void> loadReports() => loadReport();

  Future<void> loadReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reportSummary = await _reportsRepository.getMonthlyReport(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (error, stackTrace) {
      _reportSummary = MonthlyReportSummary.empty(
        month: _selectedMonth,
        year: _selectedYear,
      );
      _errorMessage = _messageFromError(error);
      debugPrint('[ReportsProvider] loadReport failed: $_errorMessage');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReport() => loadReport();

  Future<void> changeMonth(int month) async {
    if (month == _selectedMonth) {
      return;
    }
    _selectedMonth = month;
    await loadReport();
  }

  Future<void> changeYear(int year) async {
    if (year == _selectedYear) {
      return;
    }
    _selectedYear = year;
    await loadReport();
  }

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
