import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/financial_product_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../data/financial_products_repository.dart';

class FinancialProductsProvider extends ChangeNotifier {
  FinancialProductsProvider(this._financialProductsRepository);

  final FinancialProductsRepository _financialProductsRepository;
  final Uuid _uuid = const Uuid();

  List<FinancialProductModel> _products = [];

  List<FinancialProductModel> get products => _products;

  Future<void> loadProducts() async {
    _products = await _financialProductsRepository.getProducts();
    notifyListeners();
  }

  Future<void> addProduct({
    required String name,
    required FinancialProductType type,
    required double balance,
    required double limit,
    required double monthlyPayment,
    required double interestRate,
    required CurrencyType currency,
  }) async {
    final product = FinancialProductModel(
      id: _uuid.v4(),
      userId: '',
      name: name,
      type: type,
      provider: 'Manual',
      currentBalance: balance,
      creditLimit: limit,
      monthlyPayment: monthlyPayment,
      interestRate: interestRate,
      currency: currency,
      dueDate: DateTime.now().add(const Duration(days: 20)),
    );
    final savedProduct = await _financialProductsRepository.createProduct(
      product,
    );
    _products = [..._products, savedProduct];
    notifyListeners();
  }

  Future<void> updateProduct(FinancialProductModel product) async {
    final updatedProduct = await _financialProductsRepository.updateProduct(
      product,
    );
    _products = _products
        .map((item) => item.id == updatedProduct.id ? updatedProduct : item)
        .toList();
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _financialProductsRepository.deleteProduct(productId);
    _products = _products.where((item) => item.id != productId).toList();
    notifyListeners();
  }
}
