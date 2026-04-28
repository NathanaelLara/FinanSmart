import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/financial_product_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class FinancialProductsRepository {
  FinancialProductsRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection(FirestorePaths.financialProducts);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para gestionar productos.');
    }
    return user.uid;
  }

  Future<List<FinancialProductModel>> getProducts() async {
    final userId = _currentUserId;
    final snapshot = await _productsRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final products =
        snapshot.docs
            .map(
              (doc) =>
                  FinancialProductModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  Future<FinancialProductModel> createProduct(
    FinancialProductModel product,
  ) async {
    final userId = _currentUserId;
    final docRef = product.id.isEmpty
        ? _productsRef.doc()
        : _productsRef.doc(product.id);
    final productToSave = product.copyWith(id: docRef.id, userId: userId);
    await docRef.set(productToSave.toMap());
    final snapshot = await docRef.get();
    return FinancialProductModel.fromMap({
      ...snapshot.data()!,
      'id': snapshot.id,
    });
  }

  Future<FinancialProductModel> updateProduct(
    FinancialProductModel product,
  ) async {
    final userId = _currentUserId;
    final docRef = _productsRef.doc(product.id);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('El producto financiero no existe.');
    }
    final existing = FinancialProductModel.fromMap(snapshot.data()!);
    if (existing.userId != userId) {
      throw StateError('No puedes editar productos de otro usuario.');
    }

    final productToSave = product.copyWith(
      userId: userId,
      createdAt: existing.createdAt,
    );
    await docRef.set(productToSave.toMap(), SetOptions(merge: true));
    final updatedSnapshot = await docRef.get();
    return FinancialProductModel.fromMap({
      ...updatedSnapshot.data()!,
      'id': updatedSnapshot.id,
    });
  }

  Future<void> deleteProduct(String productId) async {
    final userId = _currentUserId;
    final docRef = _productsRef.doc(productId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      return;
    }
    final product = FinancialProductModel.fromMap(snapshot.data()!);
    if (product.userId != userId) {
      throw StateError('No puedes eliminar productos de otro usuario.');
    }
    await docRef.update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveProduct(FinancialProductModel product) async {
    await createProduct(product);
  }
}
