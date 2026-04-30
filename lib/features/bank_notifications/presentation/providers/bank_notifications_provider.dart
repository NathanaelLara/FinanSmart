import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/transaction_model.dart';
import '../../data/bank_notification_parser.dart';
import '../../data/bank_notification_transaction_candidate.dart';
import '../../data/bank_notifications_platform_service.dart';
import '../../data/bank_notifications_repository.dart';

class BankNotificationsProvider extends ChangeNotifier {
  BankNotificationsProvider(
    this._repository, {
    BankNotificationsPlatformService? platformService,
    BankNotificationParser? parser,
  }) : _platformService = platformService ?? BankNotificationsPlatformService(),
       _parser = parser ?? BankNotificationParser();

  final BankNotificationsRepository _repository;
  final BankNotificationsPlatformService _platformService;
  final BankNotificationParser _parser;

  StreamSubscription<BankNotificationEvent>? _subscription;
  List<BankNotificationTransactionCandidate> _candidates = [];
  bool _isListeningEnabled = false;
  bool _autoSaveEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<BankNotificationTransactionCandidate> get candidates => _candidates;
  bool get isAndroid => _platformService.isAndroid;
  bool get isListeningEnabled => _isListeningEnabled;
  bool get autoSaveEnabled => _autoSaveEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (!isAndroid) {
      return;
    }
    await refreshPermissionStatus();
    await loadCandidates();
    _subscription ??= _platformService.events.listen(_handleNotificationEvent);
  }

  Future<void> refreshPermissionStatus() async {
    _isListeningEnabled = await _platformService
        .isNotificationListenerEnabled();
    notifyListeners();
  }

  Future<void> openNotificationSettings() async {
    await _platformService.openNotificationListenerSettings();
  }

  Future<void> loadCandidates() async {
    if (!isAndroid) {
      return;
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      _candidates = await _repository.loadPendingCandidates();
    } catch (error) {
      _errorMessage = _messageFromError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptCandidate(
    BankNotificationTransactionCandidate candidate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.acceptCandidate(candidate);
      _candidates = _candidates
          .where((item) => item.id != candidate.id)
          .toList();
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

  Future<bool> rejectCandidate(String candidateId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.rejectCandidate(candidateId);
      _candidates = _candidates
          .where((item) => item.id != candidateId)
          .toList();
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

  Future<bool> saveCandidateAsTransaction(
    BankNotificationTransactionCandidate candidate, {
    String? merchantName,
    double? amount,
    TransactionCategory? category,
  }) async {
    final editedCandidate = candidate.copyWith(
      merchantName: merchantName,
      amount: amount,
      detectedCategory: category,
      deduplicationKey: BankNotificationParser.buildDeduplicationKey(
        bankName: candidate.bankName,
        cardLast4: candidate.cardLast4,
        merchantName: merchantName ?? candidate.merchantName,
        amount: amount ?? candidate.amount,
        notificationTime: candidate.notificationTime,
      ),
    );
    return acceptCandidate(editedCandidate);
  }

  void toggleAutoSave(bool value) {
    _autoSaveEnabled = value;
    notifyListeners();
  }

  Future<void> _handleNotificationEvent(BankNotificationEvent event) async {
    final candidate = _parser.parse(
      sourceApp: event.packageName,
      title: event.title,
      text: event.text,
      subText: event.subText,
      notificationTime: event.postTime,
    );
    if (candidate == null) {
      return;
    }

    try {
      if (await _repository.hasDuplicate(candidate.deduplicationKey)) {
        return;
      }

      if (_autoSaveEnabled) {
        await _repository.autoSaveCandidate(candidate);
      } else {
        final saved = await _repository.createCandidateIfNew(candidate);
        if (saved != null) {
          _candidates = [saved, ..._candidates];
        }
      }
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = _messageFromError(error);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      return message == null || message.trim().isEmpty
          ? 'Firebase ${error.code}.'
          : 'Firebase ${error.code}: $message';
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
