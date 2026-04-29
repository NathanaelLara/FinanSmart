import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/currency_converter.dart';
import '../../../../shared/models/financial_product_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/firebase/firestore_paths.dart';
import 'dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository({
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
      throw StateError('Debes iniciar sesion para consultar el dashboard.');
    }
    return user.uid;
  }

  Future<DashboardSummary> getDashboardSummary({DateTime? currentDate}) async {
    final userId = _currentUserId;
    final now = currentDate ?? DateTime.now();
    final displayCurrency = await _getPreferredCurrency(userId);
    final transactions = await _getTransactionsByUser(userId);
    final activeProducts = await _getActiveProductsCount(userId);

    return _buildSummary(
      transactions: transactions,
      activeProducts: activeProducts,
      currentDate: now,
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
        '[DashboardRepository] Preferred currency query failed. '
        'code=${error.code}, message=${error.message}',
      );
      return CurrencyType.dop;
    }
  }

  Future<List<TransactionModel>> _getTransactionsByUser(String userId) async {
    debugPrint(
      '[DashboardRepository] Query dashboard transactions userId=$userId',
    );

    try {
      final snapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true)
          .get();

      debugPrint(
        '[DashboardRepository] Ordered transactions OK. docs=${snapshot.docs.length}',
      );
      return snapshot.docs.map(TransactionModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[DashboardRepository] Ordered transactions failed. '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (error.code != 'failed-precondition') {
        rethrow;
      }

      debugPrint(
        '[DashboardRepository] Fallback without orderBy. '
        'Create an index for userId + transactionDate if this appears often.',
      );
      final fallbackSnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .get();
      final transactions =
          fallbackSnapshot.docs.map(TransactionModel.fromFirestore).toList()
            ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      debugPrint(
        '[DashboardRepository] Fallback transactions OK. docs=${transactions.length}',
      );
      return transactions;
    }
  }

  Future<int> _getActiveProductsCount(String userId) async {
    try {
      final snapshot = await _productsRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                FinancialProductModel.fromMap({...doc.data(), 'id': doc.id}),
          )
          .where((product) => product.isActive)
          .length;
    } on FirebaseException catch (error) {
      debugPrint(
        '[DashboardRepository] Active products query failed. '
        'code=${error.code}, message=${error.message}',
      );
      return 0;
    }
  }

  DashboardSummary _buildSummary({
    required List<TransactionModel> transactions,
    required int activeProducts,
    required DateTime currentDate,
    required CurrencyType displayCurrency,
  }) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    var monthlyIncome = 0.0;
    var monthlyExpense = 0.0;
    final expensesByCategory = <String, double>{};

    for (final transaction in transactions) {
      final convertedAmount = CurrencyConverter.convert(
        amount: transaction.amount,
        from: transaction.currency,
        to: displayCurrency,
      );
      final isCurrentMonth =
          transaction.transactionDate.year == currentDate.year &&
          transaction.transactionDate.month == currentDate.month;

      if (transaction.type == TransactionType.income) {
        totalIncome += convertedAmount;
        if (isCurrentMonth) {
          monthlyIncome += convertedAmount;
        }
        continue;
      }

      totalExpense += convertedAmount;
      if (isCurrentMonth) {
        monthlyExpense += convertedAmount;
        final categoryName =
            transaction.categoryName ?? transaction.category.displayName;
        expensesByCategory.update(
          categoryName,
          (value) => value + convertedAmount,
          ifAbsent: () => convertedAmount,
        );
      }
    }

    final estimatedSavings = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome == 0
        ? 0.0
        : (estimatedSavings / monthlyIncome) * 100;

    return DashboardSummary(
      displayCurrency: displayCurrency,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalBalance: totalIncome - totalExpense,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      estimatedSavings: estimatedSavings,
      savingsRate: savingsRate,
      expensesByCategory: Map.unmodifiable(expensesByCategory),
      recentTransactions: List.unmodifiable(transactions.take(5)),
      activeProducts: activeProducts,
    );
  }
}
