import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/transaction_model.dart';
import '../../data/transactions_repository.dart';

class TransactionsProvider extends ChangeNotifier {
  TransactionsProvider(this._transactionsRepository);

  final TransactionsRepository _transactionsRepository;
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  CurrencyType? _selectedCurrency;
  TransactionType? _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  CurrencyType? get selectedCurrency => _selectedCurrency;
  CurrencyType get defaultCurrency => _selectedCurrency ?? CurrencyType.dop;
  TransactionType? get selectedType => _selectedType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((transaction) {
      final currencyMatch =
          _selectedCurrency == null ||
          transaction.currency == _selectedCurrency;
      final typeMatch =
          _selectedType == null || transaction.type == _selectedType;
      return currencyMatch && typeMatch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> loadTransactions() async {
    _setLoading(true);
    _errorMessage = null;
    debugPrint('[TransactionsProvider] Loading transactions...');

    try {
      _transactions = await _transactionsRepository.getTransactions();
      debugPrint(
        '[TransactionsProvider] Loaded ${_transactions.length} transactions.',
      );
    } catch (error, stackTrace) {
      _errorMessage = _messageFromError(error);
      debugPrint(
        '[TransactionsProvider] loadTransactions failed: $_errorMessage',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrency(CurrencyType? currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  void setTransactionType(TransactionType? type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required CurrencyType currency,
    DateTime? transactionDate,
    String accountName = 'Cuenta principal',
    String paymentMethod = 'cash',
    String? financialProductId,
    String? notes,
    String? attachmentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final transaction = TransactionModel(
        id: _uuid.v4(),
        userId: '',
        description: title,
        amount: amount,
        type: type,
        category: category,
        currency: currency,
        transactionDate: transactionDate ?? DateTime.now(),
        accountName: accountName,
        paymentMethod: paymentMethod,
        financialProductId: financialProductId,
        notes: notes,
        attachmentUrl: attachmentUrl,
      );
      final savedTransaction = await _transactionsRepository.createTransaction(
        transaction,
      );
      _transactions = [savedTransaction, ..._transactions];
      _sortTransactions();
      _isLoading = false;
      _notifyListenersAfterFrame();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      _notifyListenersAfterFrame();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final updatedTransaction = await _transactionsRepository
          .updateTransaction(transaction);
      final existingIndex = _transactions.indexWhere(
        (item) => item.id == updatedTransaction.id,
      );
      if (existingIndex == -1) {
        _transactions = [updatedTransaction, ..._transactions];
      } else {
        _transactions = [
          for (final item in _transactions)
            item.id == updatedTransaction.id ? updatedTransaction : item,
        ];
      }
      _sortTransactions();
      _isLoading = false;
      _notifyListenersAfterFrame();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      _notifyListenersAfterFrame();
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      await _transactionsRepository.deleteTransaction(transactionId);
      _transactions = _transactions
          .where((transaction) => transaction.id != transactionId)
          .toList();
      _isLoading = false;
      _notifyListenersAfterFrame();
      return true;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      _isLoading = false;
      _notifyListenersAfterFrame();
      return false;
    }
  }

  void _sortTransactions() {
    _transactions.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _notifyListenersAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
