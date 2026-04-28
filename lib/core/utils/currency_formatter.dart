import 'package:intl/intl.dart';

import '../../shared/models/transaction_model.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(
    double amount, {
    CurrencyType currency = CurrencyType.dop,
  }) {
    switch (currency) {
      case CurrencyType.usd:
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
        ).format(amount);
      case CurrencyType.dop:
        return NumberFormat.currency(
          locale: 'es_DO',
          symbol: 'RD\$',
        ).format(amount);
    }
  }
}
