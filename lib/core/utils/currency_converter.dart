import '../../shared/models/transaction_model.dart';

class CurrencyConverter {
  const CurrencyConverter._();

  static const double defaultUsdToDopRate = 60;

  static double convert({
    required double amount,
    required CurrencyType from,
    required CurrencyType to,
    double usdToDopRate = defaultUsdToDopRate,
  }) {
    if (from == to) {
      return amount;
    }

    switch ((from, to)) {
      case (CurrencyType.usd, CurrencyType.dop):
        return amount * usdToDopRate;
      case (CurrencyType.dop, CurrencyType.usd):
        return amount / usdToDopRate;
      default:
        return amount;
    }
  }

  static String conversionNote(CurrencyType currency) {
    return 'Totales convertidos a ${currency.code} usando una tasa referencial de 1 USD = ${defaultUsdToDopRate.toStringAsFixed(0)} DOP.';
  }
}
