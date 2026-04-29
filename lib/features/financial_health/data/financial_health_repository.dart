import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/currency_converter.dart';
import '../../../shared/models/financial_product_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';
import 'financial_health_summary.dart';

class FinancialHealthRepository {
  FinancialHealthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection(FirestorePaths.transactions);

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection(FirestorePaths.financialProducts);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para calcular salud financiera.');
    }
    return user.uid;
  }

  Future<FinancialHealthSummary> getFinancialHealthSummary({
    DateTime? currentDate,
  }) async {
    final userId = _currentUserId;
    final now = currentDate ?? DateTime.now();
    final displayCurrency = await _getPreferredCurrency(userId);
    final transactions = await _getTransactionsByMonth(
      userId: userId,
      year: now.year,
      month: now.month,
    );
    final products = await _getActiveProducts(userId);

    return _buildSummary(
      transactions: transactions,
      products: products,
      displayCurrency: displayCurrency,
    );
  }

  Future<CurrencyType> _getPreferredCurrency(String userId) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      final data = userDoc.data();
      if (data == null) {
        return CurrencyType.dop;
      }
      return UserModel.fromMap({...data, 'id': userDoc.id}).preferredCurrency;
    } on FirebaseException catch (error) {
      debugPrint(
        '[FinancialHealthRepository] Preferred currency query failed. '
        'code=${error.code}, message=${error.message}',
      );
      return CurrencyType.dop;
    }
  }

  Future<List<TransactionModel>> _getTransactionsByMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final snapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs.map(TransactionModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[FinancialHealthRepository] Monthly transactions query failed. '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (error.code != 'failed-precondition') {
        rethrow;
      }

      final fallbackSnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      return fallbackSnapshot.docs.map(TransactionModel.fromFirestore).toList()
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    }
  }

  Future<List<FinancialProductModel>> _getActiveProducts(String userId) async {
    final snapshot = await _productsRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map(FinancialProductModel.fromFirestore).toList();
  }

  FinancialHealthSummary _buildSummary({
    required List<TransactionModel> transactions,
    required List<FinancialProductModel> products,
    required CurrencyType displayCurrency,
  }) {
    if (transactions.isEmpty) {
      final recommendations = <String>[
        'Registra ingresos y gastos para calcular tu salud financiera.',
        if (products.isEmpty)
          'Agrega tus tarjetas, prestamos o cuentas para obtener un analisis mas completo.',
      ];
      return FinancialHealthSummary.empty(
        displayCurrency: displayCurrency,
      ).copyWithRecommendations(recommendations);
    }

    var monthlyIncome = 0.0;
    var monthlyExpense = 0.0;
    final expenseByCategory = <String, double>{};

    for (final transaction in transactions) {
      final amount = CurrencyConverter.convert(
        amount: transaction.amount,
        from: transaction.currency,
        to: displayCurrency,
      );

      if (transaction.type == TransactionType.income) {
        monthlyIncome += amount;
        continue;
      }

      monthlyExpense += amount;
      final categoryName =
          transaction.categoryName ?? transaction.category.displayName;
      expenseByCategory.update(
        categoryName,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    var totalDebt = 0.0;
    var monthlyDebtPayments = 0.0;
    for (final product in products) {
      final convertedBalance = CurrencyConverter.convert(
        amount: product.balance,
        from: product.currency,
        to: displayCurrency,
      );
      final convertedMonthlyPayment = CurrencyConverter.convert(
        amount: product.monthlyPayment ?? product.minimumPayment ?? 0,
        from: product.currency,
        to: displayCurrency,
      );

      if (product.type == FinancialProductType.loan ||
          product.type == FinancialProductType.creditCard) {
        totalDebt += convertedBalance;
        monthlyDebtPayments += convertedMonthlyPayment;
      }
    }

    final monthlySavings = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome == 0
        ? 0.0
        : (monthlySavings / monthlyIncome) * 100;
    final debtToIncomeRatio = monthlyIncome == 0
        ? 0.0
        : (monthlyDebtPayments / monthlyIncome) * 100;
    final topExpense = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final score = _calculateScore(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      savingsRate: savingsRate,
      debtToIncomeRatio: debtToIncomeRatio,
      categoryConcentration: monthlyExpense == 0 || topExpense.isEmpty
          ? 0
          : (topExpense.first.value / monthlyExpense) * 100,
      hasProducts: products.isNotEmpty,
    );

    return FinancialHealthSummary(
      displayCurrency: displayCurrency,
      score: score,
      level: _levelFromScore(score),
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlySavings: monthlySavings,
      savingsRate: savingsRate,
      totalDebt: totalDebt,
      monthlyDebtPayments: monthlyDebtPayments,
      debtToIncomeRatio: debtToIncomeRatio,
      activeProducts: products.length,
      topExpenseCategory: topExpense.isEmpty ? null : topExpense.first.key,
      topExpenseCategoryAmount: topExpense.isEmpty ? 0 : topExpense.first.value,
      strengths: _buildStrengths(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        monthlySavings: monthlySavings,
        savingsRate: savingsRate,
        debtToIncomeRatio: debtToIncomeRatio,
        activeProducts: products.length,
      ),
      alerts: _buildAlerts(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        savingsRate: savingsRate,
        debtToIncomeRatio: debtToIncomeRatio,
        activeProducts: products.length,
        hasTransactions: transactions.isNotEmpty,
      ),
      recommendations: _buildRecommendations(
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        savingsRate: savingsRate,
        debtToIncomeRatio: debtToIncomeRatio,
        activeProducts: products.length,
      ),
      hasEnoughData: monthlyIncome > 0 || monthlyExpense > 0,
    );
  }

  double _calculateScore({
    required double monthlyIncome,
    required double monthlyExpense,
    required double savingsRate,
    required double debtToIncomeRatio,
    required double categoryConcentration,
    required bool hasProducts,
  }) {
    if (monthlyIncome == 0 && monthlyExpense == 0) {
      return 0;
    }

    var score = 60.0;

    if (monthlyIncome > 0 && monthlyExpense <= monthlyIncome) {
      score += 12;
    }
    if (monthlyExpense > monthlyIncome && monthlyIncome > 0) {
      score -= 25;
    }

    if (savingsRate >= 20) {
      score += 18;
    } else if (savingsRate >= 10) {
      score += 10;
    } else if (savingsRate >= 0) {
      score -= 6;
    } else {
      score -= 18;
    }

    if (debtToIncomeRatio > 40) {
      score -= 20;
    } else if (debtToIncomeRatio > 25) {
      score -= 10;
    } else if (debtToIncomeRatio > 0) {
      score += 6;
    }

    if (categoryConcentration > 60) {
      score -= 8;
    } else if (categoryConcentration > 0 && categoryConcentration <= 40) {
      score += 5;
    }

    if (hasProducts) {
      score += 4;
    }

    return score.clamp(0, 100).toDouble();
  }

  String _levelFromScore(double score) {
    if (score >= 80) {
      return 'Excelente';
    }
    if (score >= 60) {
      return 'Buena';
    }
    if (score >= 40) {
      return 'Regular';
    }
    return 'Riesgosa';
  }

  List<String> _buildStrengths({
    required double monthlyIncome,
    required double monthlyExpense,
    required double monthlySavings,
    required double savingsRate,
    required double debtToIncomeRatio,
    required int activeProducts,
  }) {
    final strengths = <String>[];
    if (monthlySavings > 0) {
      strengths.add('Ahorro mensual positivo.');
    }
    if (monthlyIncome > 0 && monthlyExpense < monthlyIncome) {
      strengths.add('Tus gastos estan por debajo de tus ingresos.');
    }
    if (savingsRate >= 20) {
      strengths.add('Excelente nivel de ahorro.');
    }
    if (debtToIncomeRatio > 0 && debtToIncomeRatio <= 30) {
      strengths.add('Deuda mensual controlada frente a tus ingresos.');
    }
    if (activeProducts > 0) {
      strengths.add('Tienes productos financieros registrados y organizados.');
    }
    return strengths.isEmpty
        ? ['Aun necesitas mas datos para identificar fortalezas claras.']
        : strengths;
  }

  List<String> _buildAlerts({
    required double monthlyIncome,
    required double monthlyExpense,
    required double savingsRate,
    required double debtToIncomeRatio,
    required int activeProducts,
    required bool hasTransactions,
  }) {
    final alerts = <String>[];
    if (!hasTransactions) {
      alerts.add('Faltan movimientos para calcular tu salud financiera.');
    }
    if (monthlyIncome == 0) {
      alerts.add('No hay ingresos registrados este mes.');
    }
    if (monthlyIncome > 0 && monthlyExpense > monthlyIncome) {
      alerts.add('Tus gastos superaron tus ingresos este mes.');
    }
    if (savingsRate < 10 && monthlyIncome > 0) {
      alerts.add('Tu porcentaje de ahorro esta por debajo de 10%.');
    }
    if (debtToIncomeRatio > 40) {
      alerts.add('Tu relacion deuda/ingreso mensual es elevada.');
    }
    if (activeProducts == 0) {
      alerts.add('No tienes productos financieros activos registrados.');
    }
    return alerts.isEmpty ? ['No hay alertas criticas este mes.'] : alerts;
  }

  List<String> _buildRecommendations({
    required double monthlyIncome,
    required double monthlyExpense,
    required double savingsRate,
    required double debtToIncomeRatio,
    required int activeProducts,
  }) {
    final recommendations = <String>[];
    if (monthlyExpense > monthlyIncome && monthlyIncome > 0) {
      recommendations.add(
        'Tus gastos superaron tus ingresos este mes. Revisa tus gastos variables.',
      );
    }
    if (savingsRate >= 20) {
      recommendations.add('Excelente nivel de ahorro. Manten este habito.');
    } else if (savingsRate >= 10) {
      recommendations.add(
        'Tienes un ahorro moderado. Puedes mejorar reduciendo gastos no esenciales.',
      );
    } else if (monthlyIncome > 0) {
      recommendations.add(
        'Tu ahorro es bajo. Intenta definir una meta de ahorro mensual.',
      );
    }
    if (debtToIncomeRatio > 40) {
      recommendations.add(
        'Tu nivel de deuda mensual es alto. Considera reducir compromisos financieros.',
      );
    }
    if (activeProducts == 0) {
      recommendations.add(
        'Agrega tus tarjetas, prestamos o cuentas para obtener un analisis mas completo.',
      );
    }
    if (monthlyIncome == 0 && monthlyExpense == 0) {
      recommendations.add(
        'Registra ingresos y gastos para calcular tu salud financiera.',
      );
    }
    recommendations.add(
      'Revisa tus gastos recurrentes antes de iniciar el proximo mes.',
    );
    return recommendations;
  }
}

extension on FinancialHealthSummary {
  FinancialHealthSummary copyWithRecommendations(List<String> recommendations) {
    return FinancialHealthSummary(
      displayCurrency: displayCurrency,
      score: score,
      level: level,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlySavings: monthlySavings,
      savingsRate: savingsRate,
      totalDebt: totalDebt,
      monthlyDebtPayments: monthlyDebtPayments,
      debtToIncomeRatio: debtToIncomeRatio,
      activeProducts: activeProducts,
      topExpenseCategory: topExpenseCategory,
      topExpenseCategoryAmount: topExpenseCategoryAmount,
      strengths: strengths,
      alerts: alerts,
      recommendations: recommendations,
      hasEnoughData: hasEnoughData,
    );
  }
}
