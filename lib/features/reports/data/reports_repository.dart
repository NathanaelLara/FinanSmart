import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/monthly_report_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class ReportsRepository {
  ReportsRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para generar reportes.');
    }
    return user.uid;
  }

  Future<List<MonthlyReportModel>> getReports() async {
    final userId = _currentUserId;
    final snapshot = await _db
        .collection(FirestorePaths.transactions)
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
    if (transactions.isEmpty) {
      return [];
    }

    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final key =
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    final reports = grouped.entries.map((entry) {
      final items = entry.value;
      final month = DateTime(
        items.first.transactionDate.year,
        items.first.transactionDate.month,
      );
      final currency = items.first.currency;
      final incomeItems = items.where(
        (item) => item.type == TransactionType.income,
      );
      final expenseItems = items.where(
        (item) => item.type == TransactionType.expense,
      );
      final totalIncome = incomeItems.fold<double>(
        0,
        (total, item) => total + item.amount,
      );
      final totalExpense = expenseItems.fold<double>(
        0,
        (total, item) => total + item.amount,
      );
      final expenseByCategory = <String, double>{};
      final expenseByPaymentMethod = <String, double>{};

      for (final item in expenseItems) {
        final category = item.categoryName ?? item.category.displayName;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + item.amount;
        expenseByPaymentMethod[item.paymentMethod] =
            (expenseByPaymentMethod[item.paymentMethod] ?? 0) + item.amount;
      }

      final topExpenses = expenseItems.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      return MonthlyReportModel(
        id: '${userId}_${entry.key}',
        userId: userId,
        month: month,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        savings: (totalIncome - totalExpense)
            .clamp(0, double.infinity)
            .toDouble(),
        savingsRate: totalIncome == 0
            ? 0.0
            : ((totalIncome - totalExpense) / totalIncome) * 100,
        currency: currency,
        expenseByCategory: expenseByCategory,
        expenseByPaymentMethod: expenseByPaymentMethod,
        topExpenses: topExpenses
            .take(5)
            .map(
              (item) => {
                'description': item.description,
                'amount': item.amount,
                'categoryName': item.categoryName ?? item.category.displayName,
                'transactionDate': item.transactionDate.toIso8601String(),
              },
            )
            .toList(),
        highlights: const [],
        generatedAt: DateTime.now(),
      );
    }).toList()..sort((a, b) => b.month.compareTo(a.month));

    return reports;
  }

  Future<void> saveReport(MonthlyReportModel report) async {
    await _db
        .collection(FirestorePaths.monthlyReports)
        .doc(report.id)
        .set(report.toMap(), SetOptions(merge: true));
  }
}
