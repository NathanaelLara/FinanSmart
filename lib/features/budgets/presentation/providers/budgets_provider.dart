import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/budget_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../data/budget_month_summary.dart';
import '../../data/budgets_repository.dart';

class BudgetsProvider extends ChangeNotifier {
  BudgetsProvider(this._budgetsRepository) {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _summary = BudgetMonthSummary.empty(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  final BudgetsRepository _budgetsRepository;
  final Uuid _uuid = const Uuid();

  late int _selectedMonth;
  late int _selectedYear;
  late BudgetMonthSummary _summary;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  BudgetMonthSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _budgetsRepository.getBudgetMonthSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (error, stackTrace) {
      _summary = BudgetMonthSummary.empty(
        month: _selectedMonth,
        year: _selectedYear,
      );
      _errorMessage = _messageFromError(error);
      debugPrint('[BudgetsProvider] loadBudgets failed: $_errorMessage');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBudgets() => loadBudgets();

  Future<void> changeMonth(int month) async {
    if (month == _selectedMonth) {
      return;
    }
    _selectedMonth = month;
    await loadBudgets();
  }

  Future<void> changeYear(int year) async {
    if (year == _selectedYear) {
      return;
    }
    _selectedYear = year;
    await loadBudgets();
  }

  Future<bool> addBudget({
    required TransactionCategory category,
    required CurrencyType currency,
    required double limitAmount,
    required int month,
    required int year,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final budget = BudgetModel(
        id: _uuid.v4(),
        userId: '',
        categoryId: category.firestoreId,
        categoryName: category.displayName,
        currency: currency,
        limitAmount: limitAmount,
        month: month,
        year: year,
        notes: notes,
      );
      await _budgetsRepository.createBudget(budget);
      _selectedMonth = month;
      _selectedYear = year;
      _summary = await _budgetsRepository.getBudgetMonthSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetsRepository.updateBudget(budget);
      _selectedMonth = budget.month;
      _selectedYear = budget.year;
      _summary = await _budgetsRepository.getBudgetMonthSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetsRepository.deleteBudget(budgetId);
      _summary = await _budgetsRepository.getBudgetMonthSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateBudget(String budgetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetsRepository.deactivateBudget(budgetId);
      _summary = await _budgetsRepository.getBudgetMonthSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
