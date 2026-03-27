import 'package:charity_collection_app/models/cash_receipt_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CashReceiptModel toMap and fromMap round trip', () {
    final now = DateTime(2026, 3, 27, 10, 30);
    final model = CashReceiptModel(
      id: 'doc_1',
      receiptId: 'CR-202603-0001',
      payeeTitle: 'Mr.',
      payeeName: 'John Doe',
      amount: 120.5,
      purpose: 'Donation',
      date: now,
      createdAt: now,
      paymentMethod: 'cash',
      receivedBy: 'Admin',
    );

    expect(model.payeeLine, 'Mr. John Doe');

    final map = model.toMap();
    expect(map['receiptId'], 'CR-202603-0001');
    expect(map['payeeTitle'], 'Mr.');
    expect(map['payeeName'], 'John Doe');
    expect(map['amount'], 120.5);
    expect(map['purpose'], 'Donation');
    expect(map['paymentMethod'], 'cash');
    expect(map['receivedBy'], 'Admin');
    expect(map['date'], isA<Timestamp>());
    expect(map['createdAt'], isA<Timestamp>());

    final decoded = CashReceiptModel.fromMap('doc_1', map);
    expect(decoded.id, 'doc_1');
    expect(decoded.receiptId, model.receiptId);
    expect(decoded.payeeName, model.payeeName);
    expect(decoded.amount, model.amount);
    expect(decoded.purpose, model.purpose);
    expect(decoded.payeeTitle, model.payeeTitle);
    expect(decoded.paymentMethod, model.paymentMethod);
    expect(decoded.receivedBy, model.receivedBy);
    expect(decoded.date, now);
    expect(decoded.createdAt, now);
  });
}
