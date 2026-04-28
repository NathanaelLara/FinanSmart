import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

class AppCategoryModel {
  const AppCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppCategoryModel.fromMap(Map<String, dynamic> map) {
    return AppCategoryModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#1B365D',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: _readTimestamp(map['createdAt']),
      updatedAt: _readTimestamp(map['updatedAt']),
    );
  }

  static List<AppCategoryModel> buildDefaultCategories(String userId) {
    const categorySeeds = [
      ('salary', TransactionType.income, 'payments_rounded', '#16A34A'),
      ('freelance', TransactionType.income, 'work_outline_rounded', '#2563EB'),
      ('food', TransactionType.expense, 'restaurant_rounded', '#F59E0B'),
      (
        'transport',
        TransactionType.expense,
        'directions_car_rounded',
        '#00A86B',
      ),
      ('housing', TransactionType.expense, 'home_rounded', '#1B365D'),
      ('utilities', TransactionType.expense, 'bolt_rounded', '#8B5CF6'),
      ('entertainment', TransactionType.expense, 'movie_rounded', '#EC4899'),
      (
        'health',
        TransactionType.expense,
        'health_and_safety_rounded',
        '#DC2626',
      ),
      ('education', TransactionType.expense, 'school_rounded', '#0EA5E9'),
      ('debt', TransactionType.expense, 'account_balance_rounded', '#F97316'),
      ('savings', TransactionType.expense, 'savings_rounded', '#10B981'),
      ('other', TransactionType.expense, 'widgets_rounded', '#6B7280'),
    ];

    return categorySeeds
        .map(
          (seed) => AppCategoryModel(
            id: '${seed.$1}_${seed.$2.name}',
            userId: userId,
            name: _titleCase(seed.$1),
            type: seed.$2,
            icon: seed.$3,
            color: seed.$4,
            isDefault: true,
          ),
        )
        .toList();
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
