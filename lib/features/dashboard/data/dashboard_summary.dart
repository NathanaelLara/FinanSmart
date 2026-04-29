import '../../../../shared/models/transaction_model.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.displayCurrency,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.estimatedSavings,
    required this.savingsRate,
    required this.expensesByCategory,
    required this.recentTransactions,
    required this.activeProducts,
  });

  final CurrencyType displayCurrency;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double estimatedSavings;
  final double savingsRate;
  final Map<String, double> expensesByCategory;
  final List<TransactionModel> recentTransactions;
  final int activeProducts;

  bool get hasTransactions => totalIncome > 0 || totalExpense > 0;

  factory DashboardSummary.empty({
    CurrencyType displayCurrency = CurrencyType.dop,
  }) {
    return DashboardSummary(
      displayCurrency: displayCurrency,
      totalIncome: 0,
      totalExpense: 0,
      totalBalance: 0,
      monthlyIncome: 0,
      monthlyExpense: 0,
      estimatedSavings: 0,
      savingsRate: 0,
      expensesByCategory: const {},
      recentTransactions: const [],
      activeProducts: 0,
    );
  }
}
