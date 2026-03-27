import 'package:charity_collection_app/screens/admin/generate_cash_receipt_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payee validation requires non-empty value', () {
    expect(
      ReceiptFormValidators.validatePayee(''),
      'Payee name is required',
    );
    expect(ReceiptFormValidators.validatePayee('John'), isNull);
  });

  test('amount validation requires positive numeric value', () {
    expect(
      ReceiptFormValidators.validateAmount(''),
      'Amount is required',
    );
    expect(
      ReceiptFormValidators.validateAmount('abc'),
      'Enter a valid amount',
    );
    expect(
      ReceiptFormValidators.validateAmount('-1'),
      'Enter a valid amount',
    );
    expect(ReceiptFormValidators.validateAmount('120.75'), isNull);
  });
}
