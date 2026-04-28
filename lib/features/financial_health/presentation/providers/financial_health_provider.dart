import 'package:flutter/material.dart';

import '../../../../shared/models/financial_health_model.dart';
import '../../data/financial_health_repository.dart';

class FinancialHealthProvider extends ChangeNotifier {
  FinancialHealthProvider(this._financialHealthRepository);

  final FinancialHealthRepository _financialHealthRepository;

  FinancialHealthModel? _health;

  FinancialHealthModel? get health => _health;

  Future<void> loadHealth() async {
    _health = await _financialHealthRepository.getHealthSnapshot();
    notifyListeners();
  }
}
