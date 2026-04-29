import '../../../shared/models/transaction_model.dart';

class MonthlyReportSummary {
  const MonthlyReportSummary({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.estimatedSavings,
    required this.savingsRate,
    required this.totalTransactions,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.expensesByCategory,
    required this.topExpenses,
    required this.transactions,
    required this.insights,
    required this.recommendations,
    required this.displayCurrency,
  });

  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double estimatedSavings;
  final double savingsRate;
  final int totalTransactions;
  final int incomeTransactions;
  final int expenseTransactions;
  final Map<String, double> expensesByCategory;
  final List<TransactionModel> topExpenses;
  final List<TransactionModel> transactions;
  final List<String> insights;
  final List<String> recommendations;
  final CurrencyType displayCurrency;

  bool get hasTransactions => totalTransactions > 0;

  factory MonthlyReportSummary.empty({
    required int month,
    required int year,
    CurrencyType displayCurrency = CurrencyType.dop,
  }) {
    return MonthlyReportSummary(
      month: month,
      year: year,
      totalIncome: 0,
      totalExpense: 0,
      netBalance: 0,
      estimatedSavings: 0,
      savingsRate: 0,
      totalTransactions: 0,
      incomeTransactions: 0,
      expenseTransactions: 0,
      expensesByCategory: const {},
      topExpenses: const [],
      transactions: const [],
      insights: const ['No hay transacciones registradas para este periodo.'],
      recommendations: const [
        'Registra ingresos y gastos de forma constante.',
        'Define un presupuesto mensual para controlar tus salidas.',
      ],
      displayCurrency: displayCurrency,
    );
  }
}
