import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/budget_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class BudgetsRepository {
  BudgetsRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para gestionar presupuestos.');
    }
    return user.uid;
  }

  Future<BudgetModel> getBudget({required int year, required int month}) async {
    final userId = _currentUserId;
    final docId = '${userId}_${year}_${month.toString().padLeft(2, '0')}';
    final snapshot = await _db
        .collection(FirestorePaths.budgets)
        .doc(docId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return BudgetModel(
        id: docId,
        userId: userId,
        month: month,
        year: year,
        totalBudget: 0,
        currency: CurrencyType.dop,
        spentAmount: 0,
        availableAmount: 0,
        categories: const {},
      );
    }

    return BudgetModel.fromMap(snapshot.data()!);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _db
        .collection(FirestorePaths.budgets)
        .doc(budget.id)
        .set(budget.toMap(), SetOptions(merge: true));
  }
}
