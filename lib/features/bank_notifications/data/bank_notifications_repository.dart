import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';
import '../../transactions/data/transactions_repository.dart';
import 'bank_notification_transaction_candidate.dart';

class BankNotificationsRepository {
  BankNotificationsRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    TransactionsRepository? transactionsRepository,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _transactionsRepository = transactionsRepository;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;
  final TransactionsRepository? _transactionsRepository;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  TransactionsRepository get _transactions =>
      _transactionsRepository ?? TransactionsRepository();

  CollectionReference<Map<String, dynamic>> get _candidatesRef =>
      _db.collection(FirestorePaths.notificationCandidates);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection(FirestorePaths.transactions);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para leer consumos bancarios.');
    }
    return user.uid;
  }

  Future<List<BankNotificationTransactionCandidate>>
  loadPendingCandidates() async {
    final userId = _currentUserId;
    final snapshot = await _candidatesRef
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          isEqualTo: BankNotificationCandidateStatus.pending.name,
        )
        .get();
    final candidates =
        snapshot.docs
            .map(BankNotificationTransactionCandidate.fromFirestore)
            .toList()
          ..sort((a, b) => b.notificationTime.compareTo(a.notificationTime));
    return candidates;
  }

  Future<BankNotificationTransactionCandidate?> createCandidateIfNew(
    BankNotificationTransactionCandidate candidate,
  ) async {
    final userId = _currentUserId;
    if (await _deduplicationKeyExists(candidate.deduplicationKey, userId)) {
      return null;
    }

    final docRef = _candidatesRef.doc();
    final candidateToSave = candidate.copyWith(id: docRef.id, userId: userId);
    await docRef.set(candidateToSave.toMap());
    final savedDoc = await docRef.get();
    return BankNotificationTransactionCandidate.fromFirestore(savedDoc);
  }

  Future<bool> hasDuplicate(String deduplicationKey) {
    return _deduplicationKeyExists(deduplicationKey, _currentUserId);
  }

  Future<void> rejectCandidate(String candidateId) async {
    await _updateCandidateStatus(
      candidateId,
      BankNotificationCandidateStatus.rejected,
    );
  }

  Future<TransactionModel> acceptCandidate(
    BankNotificationTransactionCandidate candidate,
  ) async {
    final transaction = await saveCandidateAsTransaction(candidate);
    await _updateCandidateStatus(
      candidate.id,
      BankNotificationCandidateStatus.accepted,
    );
    return transaction;
  }

  Future<TransactionModel> autoSaveCandidate(
    BankNotificationTransactionCandidate candidate,
  ) async {
    final userId = _currentUserId;
    final docRef = _candidatesRef.doc();
    final candidateToSave = candidate.copyWith(
      id: docRef.id,
      userId: userId,
      status: BankNotificationCandidateStatus.autoSaved,
    );
    await docRef.set(candidateToSave.toMap());
    return saveCandidateAsTransaction(candidateToSave);
  }

  Future<TransactionModel> saveCandidateAsTransaction(
    BankNotificationTransactionCandidate candidate,
  ) async {
    final transaction = TransactionModel(
      id: '',
      userId: '',
      description: candidate.merchantName,
      amount: candidate.amount,
      type: TransactionType.expense,
      category: candidate.detectedCategory,
      currency: candidate.currency,
      transactionDate: candidate.notificationTime,
      accountName: candidate.bankName,
      paymentMethod: 'card',
      notes:
          'Consumo detectado desde notificacion bancaria ${candidate.maskedCard}.',
    );
    final saved = await _transactions.createTransaction(transaction);
    await _transactionsRef.doc(saved.id).set({
      'source': 'bank_notification',
      'deduplicationKey': candidate.deduplicationKey,
      'bankName': candidate.bankName,
      'cardLast4': candidate.cardLast4,
    }, SetOptions(merge: true));
    return saved;
  }

  Future<void> _updateCandidateStatus(
    String candidateId,
    BankNotificationCandidateStatus status,
  ) async {
    await _candidatesRef.doc(candidateId).set({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _deduplicationKeyExists(
    String deduplicationKey,
    String userId,
  ) async {
    final candidates = await _candidatesRef
        .where('userId', isEqualTo: userId)
        .where('deduplicationKey', isEqualTo: deduplicationKey)
        .limit(1)
        .get();
    if (candidates.docs.isNotEmpty) {
      return true;
    }

    final transactions = await _transactionsRef
        .where('userId', isEqualTo: userId)
        .where('deduplicationKey', isEqualTo: deduplicationKey)
        .limit(1)
        .get();
    return transactions.docs.isNotEmpty;
  }
}
