import '../../../../shared/models/transaction_model.dart';

class FinancialHealthSummary {
  const FinancialHealthSummary({
    required this.displayCurrency,
    required this.score,
    required this.level,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySavings,
    required this.savingsRate,
    required this.totalDebt,
    required this.monthlyDebtPayments,
    required this.debtToIncomeRatio,
    required this.activeProducts,
    required this.topExpenseCategory,
    required this.topExpenseCategoryAmount,
    required this.strengths,
    required this.alerts,
    required this.recommendations,
    required this.hasEnoughData,
  });

  final CurrencyType displayCurrency;
  final double score;
  final String level;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySavings;
  final double savingsRate;
  final double totalDebt;
  final double monthlyDebtPayments;
  final double debtToIncomeRatio;
  final int activeProducts;
  final String? topExpenseCategory;
  final double topExpenseCategoryAmount;
  final List<String> strengths;
  final List<String> alerts;
  final List<String> recommendations;
  final bool hasEnoughData;

  factory FinancialHealthSummary.empty({
    CurrencyType displayCurrency = CurrencyType.dop,
  }) {
    return FinancialHealthSummary(
      displayCurrency: displayCurrency,
      score: 0,
      level: 'Sin informacion suficiente',
      monthlyIncome: 0,
      monthlyExpense: 0,
      monthlySavings: 0,
      savingsRate: 0,
      totalDebt: 0,
      monthlyDebtPayments: 0,
      debtToIncomeRatio: 0,
      activeProducts: 0,
      topExpenseCategory: null,
      topExpenseCategoryAmount: 0,
      strengths: const [],
      alerts: const [
        'Registra ingresos y gastos para calcular tu salud financiera.',
      ],
      recommendations: const [
        'Registra ingresos y gastos para obtener un analisis completo.',
        'Agrega tus tarjetas, prestamos o cuentas para mejorar el diagnostico.',
      ],
      hasEnoughData: false,
    );
  }
}
