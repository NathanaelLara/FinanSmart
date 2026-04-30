import '../../../shared/models/budget_model.dart';

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.usagePercentage,
  });

  final BudgetModel budget;
  final double spentAmount;
  final double remainingAmount;
  final double usagePercentage;

  String get statusLabel {
    if (usagePercentage > 100) {
      return 'Presupuesto excedido';
    }
    if (usagePercentage >= 100) {
      return 'Limite alcanzado';
    }
    if (usagePercentage >= 80) {
      return 'Cerca del limite';
    }
    return 'Dentro del presupuesto';
  }

  bool get isNearLimit => usagePercentage >= 80 && usagePercentage < 100;
  bool get isExceeded => usagePercentage > 100;
}
