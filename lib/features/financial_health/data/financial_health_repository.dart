import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/financial_health_model.dart';
import '../../../shared/models/financial_product_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

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

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para calcular salud financiera.');
    }
    return user.uid;
  }

  Future<FinancialHealthModel?> getHealthSnapshot() async {
    final userId = _currentUserId;
    final transactionsSnapshot = await _db
        .collection(FirestorePaths.transactions)
        .where('userId', isEqualTo: userId)
        .get();
    final transactions = transactionsSnapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();

    if (transactions.isEmpty) {
      return null;
    }

    final productsSnapshot = await _db
        .collection(FirestorePaths.financialProducts)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();
    final products = productsSnapshot.docs
        .map(
          (doc) => FinancialProductModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (total, item) => total + item.amount);
    final expense = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (total, item) => total + item.amount);
    final debt = products
        .where((item) => item.type == FinancialProductType.loan)
        .fold<double>(0, (total, item) => total + item.currentBalance);
    final savings = income - expense;
    final savingsRate = income == 0 ? 0.0 : (savings / income) * 100;
    final expenseRatio = income == 0 ? 0.0 : (expense / income) * 100;
    final debtToIncomeRatio = income == 0 ? 0.0 : (debt / income) * 100;
    final score = (100 - expenseRatio - (debtToIncomeRatio * 0.4))
        .clamp(0, 100)
        .round();

    return FinancialHealthModel(
      id: '${userId}_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}',
      userId: userId,
      month: DateTime(DateTime.now().year, DateTime.now().month),
      debtToIncomeRatio: debtToIncomeRatio,
      savingsRate: savingsRate,
      budgetUsageRate: 0,
      financialScore: score,
      healthStatus: score >= 75
          ? 'Saludable'
          : score >= 50
          ? 'En observacion'
          : 'Necesita atencion',
      recommendations: [
        if (income == 0)
          'Registra ingresos para calcular indicadores completos.',
        if (expenseRatio > 70) 'Reduce gastos para mejorar tu flujo mensual.',
        if (savingsRate < 10) 'Intenta reservar al menos 10% de tus ingresos.',
        if (debtToIncomeRatio > 35) 'Revisa tus deudas frente a tus ingresos.',
      ],
      expenseRatio: expenseRatio,
      emergencyFundMonths: expense == 0
          ? 0.0
          : (savings.clamp(0, double.infinity).toDouble() / expense),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveSnapshot(FinancialHealthModel snapshot) async {
    await _db
        .collection(FirestorePaths.financialHealth)
        .doc(snapshot.id)
        .set(snapshot.toMap(), SetOptions(merge: true));
  }
}
