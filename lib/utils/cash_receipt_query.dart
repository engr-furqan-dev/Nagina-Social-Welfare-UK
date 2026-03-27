import 'package:intl/intl.dart';

import '../models/cash_receipt_model.dart';

/// Multi-token search: every non-empty token must appear somewhere in the haystack
/// (fields, amounts, dates, payment labels, Firestore id).
bool cashReceiptMatchesSearch(CashReceiptModel r, String rawQuery) {
  final tokens = rawQuery
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return true;

  final haystack = _searchHaystack(r).toLowerCase();
  return tokens.every(haystack.contains);
}

String _paymentHaystack(CashReceiptModel r) {
  final m = r.paymentMethod;
  if (m == 'cheque_online') {
    return 'cheque_online cheque chq online transfer bank';
  }
  return 'cash';
}

String _searchHaystack(CashReceiptModel r) {
  final dfLong = DateFormat('dd MMM yyyy');
  final dfSlash = DateFormat('dd/MM/yyyy');
  final dfDash = DateFormat('dd-MM-yyyy');
  final dfIso = DateFormat('yyyy-MM-dd');
  final dfMonth = DateFormat('MMMM yyyy');
  final amt = r.amount;
  final parts = <String>[
    r.id,
    r.receiptId,
    r.payeeTitle,
    r.payeeName,
    r.payeeLine,
    r.purpose,
    r.receivedBy,
    r.paymentMethod,
    _paymentHaystack(r),
    amt.toString(),
    amt.toStringAsFixed(2),
    amt.toStringAsFixed(0),
    dfLong.format(r.date),
    dfSlash.format(r.date),
    dfDash.format(r.date),
    dfIso.format(r.date),
    dfMonth.format(r.date),
    r.date.year.toString(),
    dfLong.format(r.createdAt),
    dfSlash.format(r.createdAt),
    if (r.updatedAt != null) dfLong.format(r.updatedAt!),
    if (r.updatedAt != null) dfSlash.format(r.updatedAt!),
  ];
  return parts.join('\u001f');
}
