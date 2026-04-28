import 'transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum FinancialProductType { creditCard, loan }

class FinancialProductModel {
  const FinancialProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.provider,
    required this.currentBalance,
    required this.currency,
    this.creditLimit,
    this.monthlyPayment,
    this.dueDate,
    this.interestRate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final FinancialProductType type;
  final String provider;
  final double currentBalance;
  final CurrencyType currency;
  final double? creditLimit;
  final double? monthlyPayment;
  final DateTime? dueDate;
  final double? interestRate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get balance => currentBalance;
  double get limit => creditLimit ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.firestoreValue,
      'name': name,
      'provider': provider,
      'currency': currency.code,
      'currentBalance': currentBalance,
      'creditLimit': creditLimit,
      'monthlyPayment': monthlyPayment,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'interestRate': interestRate,
      'isActive': isActive,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FinancialProductModel.fromMap(Map<String, dynamic> map) {
    return FinancialProductModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: FinancialProductTypeX.fromFirestoreValue(map['type'] as String?),
      provider: map['provider'] as String? ?? '',
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0,
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
      monthlyPayment: (map['monthlyPayment'] as num?)?.toDouble(),
      dueDate: _readTimestamp(map['dueDate']),
      interestRate: (map['interestRate'] as num?)?.toDouble(),
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
    String? provider,
    double? currentBalance,
    CurrencyType? currency,
    double? creditLimit,
    double? monthlyPayment,
    DateTime? dueDate,
    double? interestRate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      creditLimit: creditLimit ?? this.creditLimit,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}

extension FinancialProductTypeX on FinancialProductType {
  String get firestoreValue =>
      this == FinancialProductType.creditCard ? 'credit_card' : 'loan';

  static FinancialProductType fromFirestoreValue(String? value) {
    switch (value) {
      case 'loan':
        return FinancialProductType.loan;
      case 'credit_card':
      default:
        return FinancialProductType.creditCard;
    }
  }
}
