import '../../../shared/models/transaction_model.dart';
import 'bank_notification_transaction_candidate.dart';

class BankNotificationParser {
  BankNotificationTransactionCandidate? parse({
    required String sourceApp,
    required String title,
    required String text,
    required String subText,
    required DateTime notificationTime,
  }) {
    final raw = [title, text, subText]
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final normalized = raw.toUpperCase();

    if (!_looksLikeConsumption(normalized)) {
      return null;
    }

    final amount = _extractAmount(raw);
    final merchantName = _extractMerchant(raw);
    if (amount == null || merchantName == null || merchantName.isEmpty) {
      return null;
    }

    final bankName = _detectBankName(sourceApp, normalized);
    final cardLast4 = _extractCardLast4(raw);
    final currency = _detectCurrency(normalized);
    final category = suggestCategory(merchantName);
    final confidence = _confidenceScore(
      bankName: bankName,
      cardLast4: cardLast4,
      merchantName: merchantName,
      normalized: normalized,
    );
    final deduplicationKey = buildDeduplicationKey(
      bankName: bankName,
      cardLast4: cardLast4,
      merchantName: merchantName,
      amount: amount,
      notificationTime: notificationTime,
    );

    return BankNotificationTransactionCandidate(
      id: '',
      userId: '',
      bankName: bankName,
      cardLast4: cardLast4,
      merchantName: merchantName,
      amount: amount,
      currency: currency,
      detectedCategory: category,
      rawSourceApp: sourceApp,
      notificationTime: notificationTime,
      confidenceScore: confidence,
      status: BankNotificationCandidateStatus.pending,
      deduplicationKey: deduplicationKey,
    );
  }

  TransactionCategory suggestCategory(String merchantName) {
    final value = merchantName.toUpperCase();
    if (_containsAny(value, [
      'SUPERMERCADO',
      'MARKET',
      'GROCERY',
      'SIRVENA',
      'OLE',
      'NACIONAL',
      'BRAVO',
    ])) {
      return TransactionCategory.food;
    }
    if (_containsAny(value, [
      'GASOLINA',
      'TEXACO',
      'SHELL',
      'SUNIX',
      'TOTAL',
    ])) {
      return TransactionCategory.transport;
    }
    if (value.contains('FARMACIA')) {
      return TransactionCategory.health;
    }
    if (value.contains('UBER EATS') || value.contains('PEDIDOS')) {
      return TransactionCategory.food;
    }
    if (value.contains('UBER')) {
      return TransactionCategory.transport;
    }
    return TransactionCategory.other;
  }

  static String buildDeduplicationKey({
    required String bankName,
    required String? cardLast4,
    required String merchantName,
    required double amount,
    required DateTime notificationTime,
  }) {
    final hourBucket = DateTime(
      notificationTime.year,
      notificationTime.month,
      notificationTime.day,
      notificationTime.hour,
    );
    final normalizedMerchant = merchantName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '')
        .trim();
    return [
      bankName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), ''),
      cardLast4 ?? 'NONE',
      normalizedMerchant,
      amount.toStringAsFixed(2),
      hourBucket.toIso8601String(),
    ].join('|');
  }

  bool _looksLikeConsumption(String normalized) {
    final hasConsumption =
        normalized.contains('CONSUMO') ||
        normalized.contains('COMPRA') ||
        normalized.contains('PRESENTA UN CONSUMO');
    final hasAmount = RegExp(
      r'(RD\$|DOP|USD|\$)?\s*\d{1,3}(,\d{3})*(\.\d{2})',
    ).hasMatch(normalized);
    final hasFinancialSignal =
        normalized.contains('TCNO') ||
        normalized.contains('TC NO') ||
        normalized.contains('TARJETA') ||
        normalized.contains('BANCO') ||
        normalized.contains('BANCARIBE') ||
        normalized.contains('BANCOCARIBE');

    return hasConsumption && hasAmount && hasFinancialSignal;
  }

  double? _extractAmount(String raw) {
    final match = RegExp(
      r'(?:por\s*)?(?:RD\$|DOP|USD|\$)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2}))',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  String? _extractMerchant(String raw) {
    final match = RegExp(
      r'\ben\s*([A-Z0-9 .&\-]+?)(?:\s*\.|\s+De no reconocerlo|\s+DE NO RECONOCERLO|$)',
      caseSensitive: false,
    ).firstMatch(raw);
    final merchant = match?.group(1);
    if (merchant == null) {
      return null;
    }
    return merchant
        .replaceAll(RegExp(r'\bDO\b\.?$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _extractCardLast4(String raw) {
    final match = RegExp(
      r'TC\s*No\s*:?\s*(\d{4})|TCNo\s*:?\s*(\d{4})',
      caseSensitive: false,
    ).firstMatch(raw);
    return match?.group(1) ?? match?.group(2);
  }

  CurrencyType _detectCurrency(String normalized) {
    if (normalized.contains('USD') || normalized.contains('US\$')) {
      return CurrencyType.usd;
    }
    return CurrencyType.dop;
  }

  String _detectBankName(String sourceApp, String normalized) {
    final packageName = sourceApp.toLowerCase();
    if (normalized.contains('BANCOCARIBE') ||
        normalized.contains('BANCO CARIBE') ||
        packageName.contains('bancocaribe')) {
      return 'Banco Caribe';
    }
    if (normalized.contains('BANRESERVAS') ||
        packageName.contains('banreservas')) {
      return 'Banreservas';
    }
    if (normalized.contains('POPULAR') || packageName.contains('popular')) {
      return 'Banco Popular';
    }
    if (normalized.contains('BHD') || packageName.contains('bhd')) {
      return 'BHD';
    }
    if (normalized.contains('SCOTIABANK') || packageName.contains('scotia')) {
      return 'Scotiabank';
    }
    if (normalized.contains('APAP') || packageName.contains('apap')) {
      return 'APAP';
    }
    return 'Banco';
  }

  double _confidenceScore({
    required String bankName,
    required String? cardLast4,
    required String merchantName,
    required String normalized,
  }) {
    var score = 0.55;
    if (bankName != 'Banco') {
      score += 0.15;
    }
    if (cardLast4 != null) {
      score += 0.1;
    }
    if (merchantName.length >= 4) {
      score += 0.1;
    }
    if (normalized.contains('CONSUMO')) {
      score += 0.1;
    }
    return score.clamp(0, 1);
  }

  bool _containsAny(String source, List<String> values) {
    return values.any(source.contains);
  }
}
