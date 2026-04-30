import 'package:intl/intl.dart';

import '../../shared/models/transaction_model.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(
    double amount, {
    CurrencyType currency = CurrencyType.dop,
  }) {
    final formatter = NumberFormat.decimalPattern('es_DO')
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;

    final symbol = switch (currency) {
      CurrencyType.dop => 'RD\$',
      CurrencyType.usd => 'US\$',
    };
    final formattedNumber = formatter.format(amount.abs());
    final sign = amount < 0 ? '-' : '';

    return '$sign$symbol$formattedNumber';
  }
}
