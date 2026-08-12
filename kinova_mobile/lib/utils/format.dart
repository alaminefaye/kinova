import 'package:intl/intl.dart';

final moneyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '€',
  decimalDigits: 2,
);

String formatMoney(num value) => moneyFormat.format(value);
