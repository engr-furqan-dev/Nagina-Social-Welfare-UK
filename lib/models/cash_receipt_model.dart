import 'package:cloud_firestore/cloud_firestore.dart';

class CashReceiptModel {
  final String id;
  final String receiptId;
  /// Salutation exactly as chosen (e.g. `Mr.`, `Mrs.`, `Miss`).
  final String payeeTitle;
  final String payeeName;
  final double amount;
  final String purpose;
  final DateTime date;
  final DateTime createdAt;
  final String paymentMethod;
  final String receivedBy;
  final DateTime? updatedAt;

  CashReceiptModel({
    required this.id,
    required this.receiptId,
    this.payeeTitle = '',
    required this.payeeName,
    required this.amount,
    required this.purpose,
    required this.date,
    required this.createdAt,
    this.paymentMethod = 'cash',
    this.receivedBy = '',
    this.updatedAt,
  });

  CashReceiptModel copyWith({
    String? id,
    String? receiptId,
    String? payeeTitle,
    String? payeeName,
    double? amount,
    String? purpose,
    DateTime? date,
    DateTime? createdAt,
    String? paymentMethod,
    String? receivedBy,
    DateTime? updatedAt,
  }) {
    return CashReceiptModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      payeeTitle: payeeTitle ?? this.payeeTitle,
      payeeName: payeeName ?? this.payeeName,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivedBy: receivedBy ?? this.receivedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'payeeTitle': payeeTitle,
      'payeeName': payeeName,
      'amount': amount,
      'purpose': purpose,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentMethod': paymentMethod,
      'receivedBy': receivedBy,
    };
  }

  factory CashReceiptModel.fromMap(String docId, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return CashReceiptModel(
      id: docId,
      receiptId: map['receiptId'] ?? '',
      payeeTitle: map['payeeTitle'] as String? ?? '',
      payeeName: map['payeeName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      purpose: map['purpose'] ?? '',
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt']),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      receivedBy: map['receivedBy'] as String? ?? '',
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  /// Line as on the printed receipt: title + name, preserving user’s title text.
  String get payeeLine {
    final t = payeeTitle.trim();
    final n = payeeName.trim();
    if (t.isEmpty) return n;
    if (n.isEmpty) return t;
    return '$t $n';
  }
}
