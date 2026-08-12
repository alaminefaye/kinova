import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('#,##0', 'fr_FR');

/// Montants en Franc CFA (sans décimales), ex. `12 500 FCFA`.
String formatMoney(num value) => '${_amountFormat.format(value.round())} FCFA';
