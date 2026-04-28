import 'package:cloud_firestore/cloud_firestore.dart';

enum CurrencyType { dop, usd }

enum TransactionType { income, expense }

enum TransactionCategory {
  salary,
  freelance,
  food,
  transport,
  housing,
  utilities,
  entertainment,
  health,
  education,
  debt,
  savings,
  other,
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.currency,
    required this.transactionDate,
    this.categoryId,
    this.categoryName,
    this.accountName = 'Cuenta principal',
    this.paymentMethod = 'cash',
    this.financialProductId,
    this.notes,
    this.attachmentUrl,
    this.createdAt,
    this.updatedAt,
    this.year,
    this.month,
    this.yearMonth,
  });

  final String id;
  final String userId;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final CurrencyType currency;
  final DateTime transactionDate;
  final String? categoryId;
  final String? categoryName;
  final String accountName;
  final String paymentMethod;
  final String? financialProductId;
  final String? notes;
  final String? attachmentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? year;
  final int? month;
  final String? yearMonth;

  bool get isIncome => type == TransactionType.income;
  String get title => description;
  DateTime get date => transactionDate;

  Map<String, dynamic> toMap() {
    final effectiveDate = transactionDate;

    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'currency': currency.code,
      'description': description,
      'categoryId': categoryId ?? category.firestoreId,
      'categoryName': categoryName ?? category.displayName,
      'accountName': accountName,
      'paymentMethod': paymentMethod,
      'financialProductId': financialProductId,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'transactionDate': Timestamp.fromDate(effectiveDate),
      'year': year ?? effectiveDate.year,
      'month': month ?? effectiveDate.month,
      'yearMonth':
          yearMonth ??
          '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}',
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TransactionModel.fromMap({...?doc.data(), 'id': doc.id});
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final categoryId = map['categoryId'] as String?;

    return TransactionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategoryX.fromFirestoreId(categoryId),
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      transactionDate: _readTimestamp(map['transactionDate']) ?? DateTime.now(),
      categoryId: categoryId,
      categoryName: map['categoryName'] as String?,
      accountName: map['accountName'] as String? ?? 'Cuenta principal',
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      financialProductId: map['financialProductId'] as String?,
      notes: map['notes'] as String?,
      attachmentUrl: map['attachmentUrl'] as String?,
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
      year: map['year'] as int?,
      month: map['month'] as int?,
      yearMonth: map['yearMonth'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    CurrencyType? currency,
    DateTime? transactionDate,
    String? categoryId,
    String? categoryName,
    String? accountName,
    String? paymentMethod,
    String? financialProductId,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? year,
    int? month,
    String? yearMonth,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      accountName: accountName ?? this.accountName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      financialProductId: financialProductId ?? this.financialProductId,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      year: year ?? this.year,
      month: month ?? this.month,
      yearMonth: yearMonth ?? this.yearMonth,
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

extension CurrencyTypeX on CurrencyType {
  String get code => name.toUpperCase();

  static CurrencyType fromCode(String? value) {
    switch (value) {
      case 'USD':
        return CurrencyType.usd;
      case 'DOP':
      default:
        return CurrencyType.dop;
    }
  }
}

extension TransactionCategoryX on TransactionCategory {
  String get firestoreId => name;
  String get displayName => name[0].toUpperCase() + name.substring(1);

  static TransactionCategory fromFirestoreId(String? value) {
    return TransactionCategory.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TransactionCategory.other,
    );
  }
}
