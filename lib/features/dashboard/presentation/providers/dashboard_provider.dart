import 'package:flutter/material.dart';

import '../../../../shared/models/financial_product_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../data/dashboard_repository.dart';

class DashboardOverview {
  const DashboardOverview({
    required this.balance,
    required this.income,
    required this.expense,
    required this.estimatedSavings,
    required this.activeProducts,
  });

  final double balance;
  final double income;
  final double expense;
  final double estimatedSavings;
  final int activeProducts;
}

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._dashboardRepository);

  final DashboardRepository _dashboardRepository;

  List<String> _alerts = [];

  List<String> get alerts => _alerts;

  Future<void> loadDashboard() async {
    _alerts = await _dashboardRepository.getAlerts();
    notifyListeners();
  }

  DashboardOverview buildOverview({
    required List<TransactionModel> transactions,
    required List<FinancialProductModel> products,
  }) {
    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final activeProducts = products.where((item) => item.isActive).length;

    return DashboardOverview(
      balance: income - expense,
      income: income,
      expense: expense,
      estimatedSavings: (income - expense).clamp(0, double.infinity),
      activeProducts: activeProducts,
    );
  }
}
