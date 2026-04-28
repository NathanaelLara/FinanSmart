import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/app_category_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class CategoriesRepository {
  CategoriesRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para consultar categorias.');
    }
    return user.uid;
  }

  Future<List<AppCategoryModel>> getCategories({TransactionType? type}) async {
    final userId = _currentUserId;
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.categories)
        .where('userId', isEqualTo: userId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    final snapshot = await query.get();
    final categories =
        snapshot.docs
            .map((doc) => AppCategoryModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    if (categories.isNotEmpty) {
      return categories;
    }

    final defaults = AppCategoryModel.buildDefaultCategories(userId);
    final batch = _db.batch();
    for (final category in defaults) {
      batch.set(
        _db.collection(FirestorePaths.categories).doc(category.id),
        category.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    return type == null
        ? defaults
        : defaults.where((item) => item.type == type).toList();
  }

  Future<void> saveCategory(AppCategoryModel category) async {
    await _db
        .collection(FirestorePaths.categories)
        .doc(category.id)
        .set(category.toMap(), SetOptions(merge: true));
  }
}
