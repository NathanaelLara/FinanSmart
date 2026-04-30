import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/currency_converter.dart';
import '../../../shared/models/budget_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';
import 'budget_month_summary.dart';
import 'budget_progress.dart';

class BudgetsRepository {
  BudgetsRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _budgetsRef =>
      _db.collection(FirestorePaths.budgets);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection(FirestorePaths.transactions);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(FirestorePaths.users);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para gestionar presupuestos.');
    }
    return user.uid;
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final userId = _currentUserId;
    final docRef = budget.id.isEmpty
        ? _budgetsRef.doc()
        : _budgetsRef.doc(budget.id);
    final budgetToSave = budget.copyWith(
      id: docRef.id,
      userId: userId,
      categoryName: budget.categoryName.isEmpty
          ? TransactionCategoryX.fromFirestoreId(budget.categoryId).displayName
          : budget.categoryName,
    );
    await docRef.set(budgetToSave.toMap());
    final savedDoc = await docRef.get();
    return BudgetModel.fromFirestore(savedDoc);
  }

  Future<List<BudgetModel>> getBudgetsByMonth({
    required int year,
    required int month,
  }) async {
    final userId = _currentUserId;
    final snapshot = await _budgetsRef
        .where('userId', isEqualTo: userId)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .get();

    return snapshot.docs.map(BudgetModel.fromFirestore).toList()
      ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
  }

  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    final userId = _currentUserId;
    final docRef = _budgetsRef.doc(budget.id);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('El presupuesto no existe.');
    }

    final existing = BudgetModel.fromFirestore(snapshot);
    if (existing.userId != userId) {
      throw StateError('No puedes editar presupuestos de otro usuario.');
    }

    final budgetToSave = budget.copyWith(
      userId: userId,
      createdAt: existing.createdAt,
      categoryName: budget.categoryName.isEmpty
          ? TransactionCategoryX.fromFirestoreId(budget.categoryId).displayName
          : budget.categoryName,
    );
    await docRef.set(budgetToSave.toMap(), SetOptions(merge: true));
    final updatedDoc = await docRef.get();
    return BudgetModel.fromFirestore(updatedDoc);
  }

  Future<void> deleteBudget(String budgetId) async {
    final docRef = await _verifiedBudgetRef(budgetId);
    await docRef.delete();
  }

  Future<BudgetModel> deactivateBudget(String budgetId) async {
    final docRef = await _verifiedBudgetRef(budgetId);
    await docRef.update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final updatedDoc = await docRef.get();
    return BudgetModel.fromFirestore(updatedDoc);
  }

  Future<BudgetMonthSummary> getBudgetMonthSummary({
    required int year,
    required int month,
  }) async {
    final displayCurrency = await _getPreferredCurrency(_currentUserId);
    final budgets = (await getBudgetsByMonth(
      year: year,
      month: month,
    )).where((budget) => budget.isActive).toList();
    final transactions = await _getExpenseTransactionsByMonth(
      year: year,
      month: month,
    );

    return _buildSummary(
      year: year,
      month: month,
      budgets: budgets,
      transactions: transactions,
      displayCurrency: displayCurrency,
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> _verifiedBudgetRef(
    String budgetId,
  ) async {
    final userId = _currentUserId;
    final docRef = _budgetsRef.doc(budgetId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('El presupuesto no existe.');
    }
    final budget = BudgetModel.fromFirestore(snapshot);
    if (budget.userId != userId) {
      throw StateError('No puedes gestionar presupuestos de otro usuario.');
    }
    return docRef;
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
        '[BudgetsRepository] Preferred currency query failed. '
        'code=${error.code}, message=${error.message}',
      );
      return CurrencyType.dop;
    }
  }

  Future<List<TransactionModel>> _getExpenseTransactionsByMonth({
    required int year,
    required int month,
  }) async {
    final userId = _currentUserId;
    try {
      final snapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .where('type', isEqualTo: TransactionType.expense.name)
          .get();
      return snapshot.docs.map(TransactionModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[BudgetsRepository] Expense transaction query failed. '
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
      return fallbackSnapshot.docs
          .map(TransactionModel.fromFirestore)
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();
    }
  }

  BudgetMonthSummary _buildSummary({
    required int year,
    required int month,
    required List<BudgetModel> budgets,
    required List<TransactionModel> transactions,
    required CurrencyType displayCurrency,
  }) {
    final spentByCategory = <String, double>{};
    for (final transaction in transactions) {
      final categoryId =
          transaction.categoryId ?? transaction.category.firestoreId;
      final amount = CurrencyConverter.convert(
        amount: transaction.amount,
        from: transaction.currency,
        to: displayCurrency,
      );
      spentByCategory.update(
        categoryId,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    var totalBudgeted = 0.0;
    var totalSpent = 0.0;
    final progresses = budgets.map((budget) {
      final convertedLimit = CurrencyConverter.convert(
        amount: budget.limitAmount,
        from: budget.currency,
        to: displayCurrency,
      );
      final spent = spentByCategory[budget.categoryId] ?? 0;
      final remaining = convertedLimit - spent;
      final usage = convertedLimit <= 0 ? 0.0 : (spent / convertedLimit) * 100;
      totalBudgeted += convertedLimit;
      totalSpent += spent;
      return BudgetProgress(
        budget: budget.copyWith(
          currency: displayCurrency,
          limitAmount: convertedLimit,
        ),
        spentAmount: spent,
        remainingAmount: remaining,
        usagePercentage: usage,
      );
    }).toList()..sort((a, b) => b.usagePercentage.compareTo(a.usagePercentage));

    return BudgetMonthSummary(
      month: month,
      year: year,
      displayCurrency: displayCurrency,
      totalBudgeted: totalBudgeted,
      totalSpent: totalSpent,
      totalRemaining: totalBudgeted - totalSpent,
      activeBudgets: progresses.length,
      exceededBudgets: progresses.where((item) => item.isExceeded).length,
      budgets: List.unmodifiable(progresses),
    );
  }
}
