import 'package:charity_collection_app/models/cash_receipt_model.dart';
import 'package:charity_collection_app/utils/cash_receipt_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sample = CashReceiptModel(
    id: 'abc123',
    receiptId: 'CR-202603-0001',
    payeeTitle: 'Mr.',
    payeeName: 'Khan',
    amount: 250.5,
    purpose: 'Zakat',
    date: DateTime(2026, 3, 15),
    createdAt: DateTime(2026, 3, 15, 10, 0),
  );

  test('empty query matches', () {
    expect(cashReceiptMatchesSearch(sample, ''), isTrue);
    expect(cashReceiptMatchesSearch(sample, '   '), isTrue);
  });

  test('matches receipt id and document id', () {
    expect(cashReceiptMatchesSearch(sample, 'CR-202603'), isTrue);
    expect(cashReceiptMatchesSearch(sample, 'abc123'), isTrue);
  });

  test('multi-token AND search', () {
    expect(cashReceiptMatchesSearch(sample, 'Mr. Khan'), isTrue);
    expect(cashReceiptMatchesSearch(sample, '250 zakat'), isTrue);
    expect(cashReceiptMatchesSearch(sample, 'khan 2026'), isTrue);
    expect(cashReceiptMatchesSearch(sample, 'khan nomatch'), isFalse);
  });

  test('matches amount and payment labels', () {
    final cash = sample.copyWith(paymentMethod: 'cash');
    final online = sample.copyWith(paymentMethod: 'cheque_online');
    expect(cashReceiptMatchesSearch(cash, 'cash'), isTrue);
    expect(cashReceiptMatchesSearch(online, 'online'), isTrue);
    expect(cashReceiptMatchesSearch(online, 'chq'), isTrue);
  });
}
