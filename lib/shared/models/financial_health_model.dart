import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialHealthModel {
  const FinancialHealthModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.debtToIncomeRatio,
    required this.savingsRate,
    required this.budgetUsageRate,
    required this.financialScore,
    required this.healthStatus,
    required this.recommendations,
    this.expenseRatio = 0,
    this.emergencyFundMonths = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime month;
  final double debtToIncomeRatio;
  final double savingsRate;
  final double budgetUsageRate;
  final int financialScore;
  final String healthStatus;
  final List<String> recommendations;
  final double expenseRatio;
  final double emergencyFundMonths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get score => financialScore;
  String get status => healthStatus;
  List<String> get insights => recommendations;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month.month,
      'year': month.year,
      'yearMonth': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'debtToIncomeRatio': debtToIncomeRatio,
      'savingsRate': savingsRate,
      'budgetUsageRate': budgetUsageRate,
      'financialScore': financialScore,
      'healthStatus': healthStatus,
      'recommendations': recommendations,
      'expenseRatio': expenseRatio,
      'emergencyFundMonths': emergencyFundMonths,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FinancialHealthModel.fromMap(Map<String, dynamic> map) {
    return FinancialHealthModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      month: DateTime(
        map['year'] as int? ?? DateTime.now().year,
        map['month'] as int? ?? DateTime.now().month,
      ),
      debtToIncomeRatio: (map['debtToIncomeRatio'] as num?)?.toDouble() ?? 0,
      savingsRate: (map['savingsRate'] as num?)?.toDouble() ?? 0,
      budgetUsageRate: (map['budgetUsageRate'] as num?)?.toDouble() ?? 0,
      financialScore: map['financialScore'] as int? ?? 0,
      healthStatus: map['healthStatus'] as String? ?? 'unknown',
      recommendations: ((map['recommendations'] as List?) ?? []).cast<String>(),
      expenseRatio: (map['expenseRatio'] as num?)?.toDouble() ?? 0,
      emergencyFundMonths:
          (map['emergencyFundMonths'] as num?)?.toDouble() ?? 0,
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
