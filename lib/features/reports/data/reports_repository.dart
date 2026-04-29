import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/currency_converter.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';
import 'monthly_report_summary.dart';

class ReportsRepository {
  ReportsRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection(FirestorePaths.transactions);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para generar reportes.');
    }
    return user.uid;
  }

  Future<MonthlyReportSummary> getMonthlyReport({
    required int year,
    required int month,
  }) async {
    final userId = _currentUserId;
    final displayCurrency = await _getPreferredCurrency(userId);
    final transactions = await _getTransactionsByMonth(
      userId: userId,
      year: year,
      month: month,
    );

    return _buildSummary(
      transactions: transactions,
      year: year,
      month: month,
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
        '[ReportsRepository] Preferred currency query failed. '
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
    debugPrint(
      '[ReportsRepository] Query report transactions userId=$userId year=$year month=$month',
    );

    try {
      final snapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .orderBy('transactionDate', descending: true)
          .get();

      debugPrint(
        '[ReportsRepository] Monthly query OK. docs=${snapshot.docs.length}',
      );
      return snapshot.docs.map(TransactionModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[ReportsRepository] Monthly ordered query failed. '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (error.code != 'failed-precondition') {
        rethrow;
      }

      debugPrint(
        '[ReportsRepository] Trying monthly fallback without orderBy. '
        'Create an index for userId + year + month + transactionDate.',
      );
      final fallbackSnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      final transactions =
          fallbackSnapshot.docs.map(TransactionModel.fromFirestore).toList()
            ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      debugPrint(
        '[ReportsRepository] Monthly fallback OK. docs=${transactions.length}',
      );
      return transactions;
    }
  }

  MonthlyReportSummary _buildSummary({
    required List<TransactionModel> transactions,
    required int year,
    required int month,
    required CurrencyType displayCurrency,
  }) {
    if (transactions.isEmpty) {
      return MonthlyReportSummary.empty(
        month: month,
        year: year,
        displayCurrency: displayCurrency,
      );
    }

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    var incomeTransactions = 0;
    var expenseTransactions = 0;
    final expensesByCategory = <String, double>{};
    final expenseItems = <TransactionModel>[];

    for (final transaction in transactions) {
      final convertedAmount = CurrencyConverter.convert(
        amount: transaction.amount,
        from: transaction.currency,
        to: displayCurrency,
      );

      if (transaction.type == TransactionType.income) {
        incomeTransactions++;
        totalIncome += convertedAmount;
        continue;
      }

      expenseTransactions++;
      totalExpense += convertedAmount;
      expenseItems.add(transaction);
      final categoryName =
          transaction.categoryName ?? transaction.category.displayName;
      expensesByCategory.update(
        categoryName,
        (value) => value + convertedAmount,
        ifAbsent: () => convertedAmount,
      );
    }

    final sortedExpenseEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedExpensesByCategory = Map<String, double>.fromEntries(
      sortedExpenseEntries,
    );

    expenseItems.sort((a, b) {
      final amountA = CurrencyConverter.convert(
        amount: a.amount,
        from: a.currency,
        to: displayCurrency,
      );
      final amountB = CurrencyConverter.convert(
        amount: b.amount,
        from: b.currency,
        to: displayCurrency,
      );
      return amountB.compareTo(amountA);
    });

    final netBalance = totalIncome - totalExpense;
    final savingsRate = totalIncome == 0
        ? 0.0
        : (netBalance / totalIncome) * 100;

    return MonthlyReportSummary(
      month: month,
      year: year,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
      estimatedSavings: netBalance,
      savingsRate: savingsRate,
      totalTransactions: transactions.length,
      incomeTransactions: incomeTransactions,
      expenseTransactions: expenseTransactions,
      expensesByCategory: Map.unmodifiable(sortedExpensesByCategory),
      topExpenses: List.unmodifiable(expenseItems.take(5)),
      transactions: List.unmodifiable(transactions),
      insights: List.unmodifiable(
        _buildInsights(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          savingsRate: savingsRate,
          incomeTransactions: incomeTransactions,
          expenseTransactions: expenseTransactions,
        ),
      ),
      recommendations: List.unmodifiable(
        _buildRecommendations(sortedExpenseEntries),
      ),
      displayCurrency: displayCurrency,
    );
  }

  List<String> _buildInsights({
    required double totalIncome,
    required double totalExpense,
    required double savingsRate,
    required int incomeTransactions,
    required int expenseTransactions,
  }) {
    final insights = <String>[];

    if (incomeTransactions == 0) {
      insights.add('No hay ingresos registrados para este periodo.');
    }
    if (expenseTransactions == 0) {
      insights.add('No hay gastos registrados para este periodo.');
    }
    if (totalExpense > totalIncome && totalIncome > 0) {
      insights.add('Tus gastos superaron tus ingresos este mes.');
    }
    if (totalIncome - totalExpense > 0) {
      insights.add('Terminaste el mes con ahorro positivo.');
    }
    if (totalIncome > 0) {
      if (savingsRate >= 20) {
        insights.add('Buen nivel de ahorro.');
      } else if (savingsRate >= 10) {
        insights.add('Ahorro moderado.');
      } else {
        insights.add('Ahorro bajo.');
      }
    }

    return insights.isEmpty
        ? ['Registra mas movimientos para obtener una lectura financiera clara.']
        : insights;
  }

  List<String> _buildRecommendations(
    List<MapEntry<String, double>> categories,
  ) {
    final recommendations = <String>[];

    if (categories.isNotEmpty) {
      recommendations.add(
        'Revisa y reduce la categoria con mayor gasto: ${categories.first.key}.',
      );
    }

    recommendations.addAll(const [
      'Registra ingresos y gastos de forma constante.',
      'Define un presupuesto mensual para cada categoria importante.',
      'Revisa gastos recurrentes antes de iniciar el proximo mes.',
      'Evita endeudamiento innecesario y prioriza pagos esenciales.',
    ]);

    return recommendations;
  }
}
