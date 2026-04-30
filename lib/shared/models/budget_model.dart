import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.currency,
    required this.limitAmount,
    required this.month,
    required this.year,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final CurrencyType currency;
  final double limitAmount;
  final int month;
  final int year;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get yearMonth => '$year-${month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'currency': currency.code,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
      'yearMonth': yearMonth,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BudgetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BudgetModel.fromMap({...?doc.data(), 'id': doc.id});
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      limitAmount:
          (map['limitAmount'] as num?)?.toDouble() ??
          (map['totalBudget'] as num?)?.toDouble() ??
          0,
      month: (map['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    CurrencyType? currency,
    double? limitAmount,
    int? month,
    int? year,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      currency: currency ?? this.currency,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
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
