import 'transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyReportModel {
  const MonthlyReportModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.savings,
    required this.savingsRate,
    required this.currency,
    required this.expenseByCategory,
    required this.expenseByPaymentMethod,
    required this.topExpenses,
    required this.highlights,
    this.generatedAt,
  });

  final String id;
  final String userId;
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double savings;
  final double savingsRate;
  final CurrencyType currency;
  final Map<String, double> expenseByCategory;
  final Map<String, double> expenseByPaymentMethod;
  final List<Map<String, dynamic>> topExpenses;
  final List<String> highlights;
  final DateTime? generatedAt;

  int get year => month.year;
  int get monthNumber => month.month;
  double get netSavings => savings;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month.month,
      'year': month.year,
      'yearMonth': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'currency': currency.code,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': netBalance,
      'savings': savings,
      'savingsRate': savingsRate,
      'expenseByCategory': expenseByCategory,
      'expenseByPaymentMethod': expenseByPaymentMethod,
      'topExpenses': topExpenses,
      'generatedAt': generatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(generatedAt!),
      'highlights': highlights,
    };
  }

  factory MonthlyReportModel.fromMap(Map<String, dynamic> map) {
    return MonthlyReportModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      month: DateTime(
        map['year'] as int? ?? DateTime.now().year,
        map['month'] as int? ?? DateTime.now().month,
      ),
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0,
      netBalance: (map['netBalance'] as num?)?.toDouble() ?? 0,
      savings: (map['savings'] as num?)?.toDouble() ?? 0,
      savingsRate: (map['savingsRate'] as num?)?.toDouble() ?? 0,
      currency: CurrencyTypeX.fromCode(map['currency'] as String?),
      expenseByCategory: _toDoubleMap(map['expenseByCategory']),
      expenseByPaymentMethod: _toDoubleMap(map['expenseByPaymentMethod']),
      topExpenses: ((map['topExpenses'] as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      highlights: ((map['highlights'] as List?) ?? []).cast<String>(),
      generatedAt: _readTimestamp(map['generatedAt']),
    );
  }

  static Map<String, double> _toDoubleMap(dynamic value) {
    return (value as Map<String, dynamic>? ?? {}).map(
      (key, item) => MapEntry(key, (item as num).toDouble()),
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
