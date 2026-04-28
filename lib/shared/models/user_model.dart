import 'transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.preferredCurrency,
    this.phone,
    this.photoUrl,
    this.monthlyIncomeGoal = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final CurrencyType preferredCurrency;
  final String? phone;
  final String? photoUrl;
  final double monthlyIncomeGoal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get name => fullName;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    CurrencyType? preferredCurrency,
    String? phone,
    String? photoUrl,
    double? monthlyIncomeGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      monthlyIncomeGoal: monthlyIncomeGoal ?? this.monthlyIncomeGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'preferredCurrency': preferredCurrency.code,
      'photoUrl': photoUrl,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      preferredCurrency: CurrencyTypeX.fromCode(
        map['preferredCurrency'] as String?,
      ),
      photoUrl: map['photoUrl'] as String?,
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
