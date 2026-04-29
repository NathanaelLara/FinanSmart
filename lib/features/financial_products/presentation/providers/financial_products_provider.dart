import 'package:firebase_core/firebase_core.dart';
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
  FinancialProductType? _selectedType;
  CurrencyType? _selectedCurrency;
  bool _isLoading = false;
  String? _errorMessage;

  List<FinancialProductModel> get products => _products;
  List<FinancialProductModel> get activeProducts =>
      _products.where((product) => product.isActive).toList();
  FinancialProductType? get selectedType => _selectedType;
  CurrencyType? get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FinancialProductModel> get filteredProducts {
    return _products.where((product) {
      final typeMatch = _selectedType == null || product.type == _selectedType;
      final currencyMatch =
          _selectedCurrency == null || product.currency == _selectedCurrency;
      return typeMatch && currencyMatch;
    }).toList();
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _products = await _financialProductsRepository.getProducts();
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  void setTypeFilter(FinancialProductType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setCurrencyFilter(CurrencyType? currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  Future<bool> addProduct({
    required String name,
    required FinancialProductType type,
    required String institutionName,
    required CurrencyType currency,
    required double balance,
    double? limitAmount,
    double? interestRate,
    double? minimumPayment,
    double? monthlyPayment,
    int? dueDay,
    DateTime? paymentDate,
    DateTime? openingDate,
    String? notes,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = FinancialProductModel(
        id: _uuid.v4(),
        userId: '',
        name: name,
        type: type,
        institutionName: institutionName,
        currency: currency,
        balance: balance,
        limitAmount: limitAmount,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        monthlyPayment: monthlyPayment,
        dueDay: dueDay,
        paymentDate: paymentDate,
        openingDate: openingDate,
        notes: notes,
        isActive: isActive,
      );
      final savedProduct = await _financialProductsRepository.createProduct(
        product,
      );
      _products = [savedProduct, ..._products];
      _sortProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(FinancialProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProduct = await _financialProductsRepository.updateProduct(
        product,
      );
      _products = [
        for (final item in _products)
          item.id == updatedProduct.id ? updatedProduct : item,
      ];
      if (!_products.any((item) => item.id == updatedProduct.id)) {
        _products = [updatedProduct, ..._products];
      }
      _sortProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _financialProductsRepository.deleteProduct(productId);
      _products = _products.where((item) => item.id != productId).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProduct = await _financialProductsRepository
          .deactivateProduct(productId);
      _products = [
        for (final item in _products)
          item.id == updatedProduct.id ? updatedProduct : item,
      ];
      _sortProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _sortProducts() {
    _products.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      if (message == null || message.trim().isEmpty) {
        return 'Firebase ${error.code}.';
      }
      return 'Firebase ${error.code}: $message';
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }
}
