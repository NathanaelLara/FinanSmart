import '../../../shared/models/transaction_model.dart';
import 'budget_progress.dart';

class BudgetMonthSummary {
  const BudgetMonthSummary({
    required this.month,
    required this.year,
    required this.displayCurrency,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
    required this.activeBudgets,
    required this.exceededBudgets,
    required this.budgets,
  });

  final int month;
  final int year;
  final CurrencyType displayCurrency;
  final double totalBudgeted;
  final double totalSpent;
  final double totalRemaining;
  final int activeBudgets;
  final int exceededBudgets;
  final List<BudgetProgress> budgets;

  bool get hasBudgets => budgets.isNotEmpty;

  factory BudgetMonthSummary.empty({
    required int month,
    required int year,
    CurrencyType displayCurrency = CurrencyType.dop,
  }) {
    return BudgetMonthSummary(
      month: month,
      year: year,
      displayCurrency: displayCurrency,
      totalBudgeted: 0,
      totalSpent: 0,
      totalRemaining: 0,
      activeBudgets: 0,
      exceededBudgets: 0,
      budgets: const [],
    );
  }
}
