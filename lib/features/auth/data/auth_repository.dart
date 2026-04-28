import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/app_category_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/firebase/firestore_paths.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final snapshot = await _db
        .collection(FirestorePaths.users)
        .doc(firebaseUser.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!);
    }

    final user = UserModel(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      preferredCurrency: CurrencyType.dop,
      photoUrl: firebaseUser.photoURL,
    );
    await _createUserProfile(user);
    await _seedDefaultCategories(firebaseUser.uid);
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase no devolvio un usuario autenticado.',
      );
    }

    final snapshot = await _db
        .collection(FirestorePaths.users)
        .doc(firebaseUser.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!);
    }

    final user = UserModel(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? email,
      preferredCurrency: CurrencyType.dop,
      photoUrl: firebaseUser.photoURL,
    );
    await _createUserProfile(user);
    await _seedDefaultCategories(firebaseUser.uid);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);

    final user = UserModel(
      id: credential.user!.uid,
      fullName: name,
      email: email,
      preferredCurrency: CurrencyType.dop,
      photoUrl: credential.user!.photoURL,
    );
    await _createUserProfile(user);
    await _seedDefaultCategories(credential.user!.uid);
    return user;
  }

  Future<void> updatePreferredCurrency(CurrencyType currency) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesion para actualizar tu perfil.');
    }

    await _db.collection(FirestorePaths.users).doc(user.uid).update({
      'preferredCurrency': currency.code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> _createUserProfile(UserModel user) async {
    await _db
        .collection(FirestorePaths.users)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> _seedDefaultCategories(String userId) async {
    final batch = _db.batch();
    for (final category in AppCategoryModel.buildDefaultCategories(userId)) {
      final ref = _db.collection(FirestorePaths.categories).doc(category.id);
      batch.set(ref, category.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
