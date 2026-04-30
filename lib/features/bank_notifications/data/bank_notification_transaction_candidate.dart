import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/transaction_model.dart';

enum BankNotificationCandidateStatus { pending, accepted, rejected, autoSaved }

class BankNotificationTransactionCandidate {
  const BankNotificationTransactionCandidate({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.cardLast4,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.detectedCategory,
    required this.rawSourceApp,
    required this.notificationTime,
    required this.confidenceScore,
    required this.status,
    required this.deduplicationKey,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String bankName;
  final String? cardLast4;
  final String merchantName;
  final double amount;
  final CurrencyType currency;
  final TransactionCategory detectedCategory;
  final String rawSourceApp;
  final DateTime notificationTime;
  final double confidenceScore;
  final BankNotificationCandidateStatus status;
  final String deduplicationKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get maskedCard => cardLast4 == null || cardLast4!.isEmpty
      ? 'No detectada'
      : '****$cardLast4';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bankName': bankName,
      'cardLast4': cardLast4,
      'merchantName': merchantName,
      'amount': amount,
      'currency': currency.code,
      'detectedCategory': detectedCategory.firestoreId,
      'rawSourceApp': rawSourceApp,
      'notificationTime': Timestamp.fromDate(notificationTime),
      'confidenceScore': confidenceScore,
      'status': status.name,
      'deduplicationKey': deduplicationKey,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BankNotificationTransactionCandidate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BankNotificationTransactionCandidate.fromMap({
      ...?doc.data(),
      'id': doc.id,
    });
  }

  factory BankNotificationTransactionCandidate.fromMap(
    Map<String, dynamic> map,
  ) {
    return BankNotificationTransactionCandidate(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      bankName: map['bankName'] as String? ?? 'Banco',
      cardLast4: map['cardLast4'] as String?,
      merchantName: map['merchantName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      detectedCategory: TransactionCategoryX.fromFirestoreId(
        map['detectedCategory'] as String?,
      ),
      rawSourceApp: map['rawSourceApp'] as String? ?? '',
      notificationTime:
          _readTimestamp(map['notificationTime']) ?? DateTime.now(),
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0,
      status: BankNotificationCandidateStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => BankNotificationCandidateStatus.pending,
      ),
      deduplicationKey: map['deduplicationKey'] as String? ?? '',
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
    );
  }

  BankNotificationTransactionCandidate copyWith({
    String? id,
    String? userId,
    String? bankName,
    String? cardLast4,
    String? merchantName,
    double? amount,
    CurrencyType? currency,
    TransactionCategory? detectedCategory,
    String? rawSourceApp,
    DateTime? notificationTime,
    double? confidenceScore,
    BankNotificationCandidateStatus? status,
    String? deduplicationKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankNotificationTransactionCandidate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      cardLast4: cardLast4 ?? this.cardLast4,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      detectedCategory: detectedCategory ?? this.detectedCategory,
      rawSourceApp: rawSourceApp ?? this.rawSourceApp,
      notificationTime: notificationTime ?? this.notificationTime,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
