import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

enum FinancialProductType {
  bankAccount,
  creditCard,
  loan,
  savingsAccount,
  investment,
  other,
}

class FinancialProductModel {
  const FinancialProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.institutionName,
    required this.currency,
    required this.balance,
    this.limitAmount,
    this.interestRate,
    this.minimumPayment,
    this.monthlyPayment,
    this.dueDay,
    this.paymentDate,
    this.openingDate,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final FinancialProductType type;
  final String institutionName;
  final CurrencyType currency;
  final double balance;
  final double? limitAmount;
  final double? interestRate;
  final double? minimumPayment;
  final double? monthlyPayment;
  final int? dueDay;
  final DateTime? paymentDate;
  final DateTime? openingDate;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get provider => institutionName;
  double get currentBalance => balance;
  double get limit => limitAmount ?? 0;
  double? get creditLimit => limitAmount;
  DateTime? get dueDate => paymentDate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.firestoreValue,
      'institutionName': institutionName,
      'currency': currency.code,
      'balance': balance,
      'limitAmount': limitAmount,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'monthlyPayment': monthlyPayment,
      'dueDay': dueDay,
      'paymentDate': paymentDate == null
          ? null
          : Timestamp.fromDate(paymentDate!),
      'openingDate': openingDate == null
          ? null
          : Timestamp.fromDate(openingDate!),
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FinancialProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FinancialProductModel.fromMap({...?doc.data(), 'id': doc.id});
  }

  factory FinancialProductModel.fromMap(Map<String, dynamic> map) {
    return FinancialProductModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: FinancialProductTypeX.fromFirestoreValue(map['type'] as String?),
      institutionName:
          map['institutionName'] as String? ?? map['provider'] as String? ?? '',
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      balance:
          (map['balance'] as num?)?.toDouble() ??
          (map['currentBalance'] as num?)?.toDouble() ??
          0,
      limitAmount:
          (map['limitAmount'] as num?)?.toDouble() ??
          (map['creditLimit'] as num?)?.toDouble(),
      interestRate: (map['interestRate'] as num?)?.toDouble(),
      minimumPayment: (map['minimumPayment'] as num?)?.toDouble(),
      monthlyPayment: (map['monthlyPayment'] as num?)?.toDouble(),
      dueDay: (map['dueDay'] as num?)?.toInt(),
      paymentDate:
          _readTimestamp(map['paymentDate']) ?? _readTimestamp(map['dueDate']),
      openingDate: _readTimestamp(map['openingDate']),
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
    );
  }

  FinancialProductModel copyWith({
    String? id,
    String? userId,
    String? name,
    FinancialProductType? type,
    String? institutionName,
    CurrencyType? currency,
    double? balance,
    double? limitAmount,
    double? interestRate,
    double? minimumPayment,
    double? monthlyPayment,
    int? dueDay,
    DateTime? paymentDate,
    DateTime? openingDate,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      institutionName: institutionName ?? this.institutionName,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      limitAmount: limitAmount ?? this.limitAmount,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      dueDay: dueDay ?? this.dueDay,
      paymentDate: paymentDate ?? this.paymentDate,
      openingDate: openingDate ?? this.openingDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
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

extension FinancialProductTypeX on FinancialProductType {
  String get firestoreValue {
    switch (this) {
      case FinancialProductType.bankAccount:
        return 'bank_account';
      case FinancialProductType.creditCard:
        return 'credit_card';
      case FinancialProductType.loan:
        return 'loan';
      case FinancialProductType.savingsAccount:
        return 'savings_account';
      case FinancialProductType.investment:
        return 'investment';
      case FinancialProductType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case FinancialProductType.bankAccount:
        return 'Cuenta bancaria';
      case FinancialProductType.creditCard:
        return 'Tarjeta de credito';
      case FinancialProductType.loan:
        return 'Prestamo';
      case FinancialProductType.savingsAccount:
        return 'Cuenta de ahorro';
      case FinancialProductType.investment:
        return 'Inversion';
      case FinancialProductType.other:
        return 'Otro';
    }
  }

  IconDataData get iconData {
    switch (this) {
      case FinancialProductType.creditCard:
        return IconDataData.creditCard;
      case FinancialProductType.loan:
        return IconDataData.loan;
      case FinancialProductType.investment:
        return IconDataData.investment;
      case FinancialProductType.bankAccount:
      case FinancialProductType.savingsAccount:
        return IconDataData.account;
      case FinancialProductType.other:
        return IconDataData.other;
    }
  }

  static FinancialProductType fromFirestoreValue(String? value) {
    switch (value) {
      case 'bank_account':
      case 'bankAccount':
        return FinancialProductType.bankAccount;
      case 'loan':
        return FinancialProductType.loan;
      case 'savings_account':
      case 'savingsAccount':
        return FinancialProductType.savingsAccount;
      case 'investment':
        return FinancialProductType.investment;
      case 'other':
        return FinancialProductType.other;
      case 'credit_card':
      case 'creditCard':
      default:
        return FinancialProductType.creditCard;
    }
  }
}

enum IconDataData { account, creditCard, loan, investment, other }
