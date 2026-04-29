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

  Future<FinancialProductModel> createProduct(
    FinancialProductModel product,
  ) async {
    final userId = _currentUserId;
    final docRef = product.id.isEmpty
        ? _productsRef.doc()
        : _productsRef.doc(product.id);
    final productToSave = product.copyWith(id: docRef.id, userId: userId);

    await docRef.set(productToSave.toMap());
    final savedDoc = await docRef.get();
    return FinancialProductModel.fromFirestore(savedDoc);
  }

  Future<List<FinancialProductModel>> getProducts() async {
    final userId = _currentUserId;
    final snapshot = await _productsRef
        .where('userId', isEqualTo: userId)
        .get();

    final products =
        snapshot.docs.map(FinancialProductModel.fromFirestore).toList()
          ..sort((a, b) {
            final activeCompare = b.isActive.toString().compareTo(
              a.isActive.toString(),
            );
            if (activeCompare != 0) {
              return activeCompare;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return products;
  }

  Future<List<FinancialProductModel>> getActiveProducts() async {
    final userId = _currentUserId;
    final snapshot = await _productsRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map(FinancialProductModel.fromFirestore).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

    final existing = FinancialProductModel.fromFirestore(snapshot);
    if (existing.userId != userId) {
      throw StateError('No puedes editar productos de otro usuario.');
    }

    final productToSave = product.copyWith(
      userId: userId,
      createdAt: existing.createdAt,
    );
    await docRef.set(productToSave.toMap(), SetOptions(merge: true));
    final updatedDoc = await docRef.get();
    return FinancialProductModel.fromFirestore(updatedDoc);
  }

  Future<void> deleteProduct(String productId) async {
    final docRef = await _verifiedProductRef(productId);
    await docRef.delete();
  }

  Future<FinancialProductModel> deactivateProduct(String productId) async {
    final docRef = await _verifiedProductRef(productId);
    await docRef.update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final updatedDoc = await docRef.get();
    return FinancialProductModel.fromFirestore(updatedDoc);
  }

  Future<void> saveProduct(FinancialProductModel product) async {
    await createProduct(product);
  }

  Future<DocumentReference<Map<String, dynamic>>> _verifiedProductRef(
    String productId,
  ) async {
    final userId = _currentUserId;
    final docRef = _productsRef.doc(productId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw StateError('El producto financiero no existe.');
    }

    final product = FinancialProductModel.fromFirestore(snapshot);
    if (product.userId != userId) {
      throw StateError('No puedes gestionar productos de otro usuario.');
    }

    return docRef;
  }
}
