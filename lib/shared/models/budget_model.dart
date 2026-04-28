import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

class BudgetCategoryEntry {
  const BudgetCategoryEntry({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.availableAmount,
  });

  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double availableAmount;

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'availableAmount': availableAmount,
    };
  }

  factory BudgetCategoryEntry.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryEntry(
      categoryName: map['categoryName'] as String? ?? '',
      budgetAmount: (map['budgetAmount'] as num?)?.toDouble() ?? 0,
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0,
      availableAmount: (map['availableAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.currency,
    required this.spentAmount,
    required this.availableAmount,
    required this.categories,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final int month;
  final int year;
  final double totalBudget;
  final CurrencyType currency;
  final double spentAmount;
  final double availableAmount;
  final Map<String, BudgetCategoryEntry> categories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get yearMonth => '$year-${month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'year': year,
      'yearMonth': yearMonth,
      'totalBudget': totalBudget,
      'currency': currency.code,
      'spentAmount': spentAmount,
      'availableAmount': availableAmount,
      'categories': categories.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    final categoryMap = (map['categories'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(
        key,
        BudgetCategoryEntry.fromMap(Map<String, dynamic>.from(value as Map)),
      ),
    );

    return BudgetModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      month: map['month'] as int? ?? 1,
      year: map['year'] as int? ?? DateTime.now().year,
      totalBudget: (map['totalBudget'] as num?)?.toDouble() ?? 0,
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0,
      availableAmount: (map['availableAmount'] as num?)?.toDouble() ?? 0,
      categories: categoryMap,
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
