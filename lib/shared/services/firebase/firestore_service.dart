import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get transactions =>
      _firestore.collection(FirestorePaths.transactions);

  CollectionReference<Map<String, dynamic>> get budgets =>
      _firestore.collection(FirestorePaths.budgets);

  CollectionReference<Map<String, dynamic>> get financialProducts =>
      _firestore.collection(FirestorePaths.financialProducts);

  CollectionReference<Map<String, dynamic>> get monthlyReports =>
      _firestore.collection(FirestorePaths.monthlyReports);

  CollectionReference<Map<String, dynamic>> get categories =>
      _firestore.collection(FirestorePaths.categories);

  CollectionReference<Map<String, dynamic>> get financialHealth =>
      _firestore.collection(FirestorePaths.financialHealth);
}
