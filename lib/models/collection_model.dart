import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionModel {
  final String id;
  final String boxId;
  final double amount;
  final DateTime date;
  final bool receiptSent;
  final String collectedBy;
// NEW

  CollectionModel({
    required this.id,
    required this.boxId,
    required this.amount,
    required this.date,
    this.receiptSent = false,
    required this.collectedBy,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'boxId': boxId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'receiptSent': receiptSent,
      'collectedBy': collectedBy,// save in Firestore
    };
  }

  factory CollectionModel.fromMap(String docId, Map<String, dynamic> map) {
    return CollectionModel(
      id: docId,
      boxId: map['boxId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      receiptSent: map['receiptSent'] ?? false,
      collectedBy: map['collectedBy'] ?? 'Unknown',
    );
  }
}
