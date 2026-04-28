import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class TransactionsRepository {
  TransactionsRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection(FirestorePaths.transactions);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para gestionar transacciones.');
    }
    return user.uid;
  }

  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    final userId = _currentUserId;
    final docRef = transaction.id.isEmpty
        ? _transactionsRef.doc()
        : _transactionsRef.doc(transaction.id);
    final transactionToSave = transaction.copyWith(
      id: docRef.id,
      userId: userId,
      categoryId: transaction.categoryId ?? transaction.category.firestoreId,
      categoryName:
          transaction.categoryName ?? transaction.category.displayName,
      year: transaction.transactionDate.year,
      month: transaction.transactionDate.month,
      yearMonth:
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}',
    );

    await docRef.set(transactionToSave.toMap());
    final savedDoc = await docRef.get();
    return TransactionModel.fromFirestore(savedDoc);
  }

  Future<List<TransactionModel>> getTransactions() {
    final userId = _currentUserId;
    debugPrint('[TransactionsRepository] getTransactions userId=$userId');
    return getTransactionsByUser(userId);
  }

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    if (userId != _currentUserId) {
      throw StateError('No puedes consultar transacciones de otro usuario.');
    }

    debugPrint(
      '[TransactionsRepository] Query transactions where userId == $userId '
      'orderBy transactionDate desc',
    );

    try {
      final snapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true)
          .get();

      debugPrint(
        '[TransactionsRepository] Query OK. docs=${snapshot.docs.length}',
      );
      return snapshot.docs.map(TransactionModel.fromFirestore).toList();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[TransactionsRepository] Ordered query failed. '
        'code=${error.code}, message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (error.code != 'failed-precondition') {
        rethrow;
      }

      debugPrint(
        '[TransactionsRepository] Trying fallback query without orderBy. '
        'If this works, deploy the composite index for userId + transactionDate.',
      );

      final fallbackSnapshot = await _transactionsRef
          .where('userId', isEqualTo: userId)
          .get();
      final transactions =
          fallbackSnapshot.docs.map(TransactionModel.fromFirestore).toList()
            ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      debugPrint(
        '[TransactionsRepository] Fallback query OK. '
        'docs=${transactions.length}',
      );
      return transactions;
    }
  }

  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    final userId = _currentUserId;
    final docRef = _transactionsRef.doc(transaction.id);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw StateError('La transaccion no existe.');
    }

    final existingTransaction = TransactionModel.fromFirestore(snapshot);
    if (existingTransaction.userId != userId) {
      throw StateError('No puedes editar transacciones de otro usuario.');
    }

    final transactionToSave = transaction.copyWith(
      userId: userId,
      createdAt: existingTransaction.createdAt,
      categoryId: transaction.categoryId ?? transaction.category.firestoreId,
      categoryName:
          transaction.categoryName ?? transaction.category.displayName,
      year: transaction.transactionDate.year,
      month: transaction.transactionDate.month,
      yearMonth:
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}',
    );

    await docRef.set(transactionToSave.toMap(), SetOptions(merge: true));
    final updatedDoc = await docRef.get();
    return TransactionModel.fromFirestore(updatedDoc);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = _currentUserId;
    final docRef = _transactionsRef.doc(transactionId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      return;
    }

    final transaction = TransactionModel.fromFirestore(snapshot);
    if (transaction.userId != userId) {
      throw StateError('No puedes eliminar transacciones de otro usuario.');
    }

    await docRef.delete();
  }

  Future<List<TransactionModel>> getTransactionsByMonth({
    required int year,
    required int month,
  }) async {
    final userId = _currentUserId;
    final snapshot = await _transactionsRef
        .where('userId', isEqualTo: userId)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .orderBy('transactionDate', descending: true)
        .get();

    return snapshot.docs.map(TransactionModel.fromFirestore).toList();
  }
}
