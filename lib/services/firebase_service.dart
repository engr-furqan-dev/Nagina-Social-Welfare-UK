import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/box_model.dart';
import '../models/cash_receipt_model.dart';
import '../models/collection_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _cashReceiptsCollection = 'cash_receipts';

  /* -------------------- BOX METHODS -------------------- */

  /// Add a new charity box
  Future<String> addBox(BoxModel box) async {
    final docRef = await _db.collection('boxes').add(box.toMap());
    return docRef.id;
  }

  /// Update existing box
  Future<void> updateBox(BoxModel box) async {
    await _db.collection('boxes').doc(box.id).update({
      'venueName': box.venueName,
      'contactPersonName': box.contactPersonName,
      'contactPersonPhone': box.contactPersonPhone,
      'totalCollected': box.totalCollected,
      'status': box.status.name, // Correctly update status
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete existing box
  Future<void> deleteBox(String id) async {
    await _db.collection('boxes').doc(id).delete();
  }

  /// Stream of all boxes (type-safe)
  Stream<List<BoxModel>> getBoxesStream() {
    return _db
        .collection('boxes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BoxModel.fromMap(
                  doc.id, // ✅ String FIRST
                  doc.data() as Map<String, dynamic>, // ✅ Map SECOND
                ),
              )
              .toList(),
        );
  }


  Future<void> completeBoxCycle(String boxId) async {
    final query = await _db
        .collection('boxes')
        .where('boxId', isEqualTo: boxId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final docId = query.docs.first.id;

    await _db.collection('boxes').doc(docId).update({
      'status': BoxStatus.sentReceipt.name,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /* -------------------- COLLECTION METHODS -------------------- */

  /// Add a collection entry
  Future<void> addCollection(CollectionModel collection) async {
    final docRef = _db.collection('collections').doc(); // auto-generated id
    await docRef.set({
      'id': docRef.id,
      'boxId': collection.boxId,
      'amount': collection.amount,
      'date': Timestamp.fromDate(collection.date),
      'receiptSent': collection.receiptSent,
      'collectedBy': collection.collectedBy,
    });
  }


  /// Stream of all collections (type-safe)
 /* Stream<List<CollectionModel>> getCollections() {
    return _db.collection('collections').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CollectionModel(
          id: doc.id,
          boxId: data['boxId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          date: data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          receiptSent: data['receiptSent'] ?? true,
        );
      }).toList();
    });
  }*/

  Stream<List<CollectionModel>> getCollections() {
    return _db.collection('collections').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CollectionModel.fromMap(doc.id, data);
      }).toList();
    });
  }


  /// Fetch a BoxModel from Firestore by boxId when Scan
  Future<BoxModel?> getBoxByBoxId(String boxId) async {
    final query = await _db
        .collection('boxes')
        .where('boxId', isEqualTo: boxId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final data = doc.data() as Map<String, dynamic>; // ensure type
    return BoxModel.fromMap(doc.id, data);
  }

// filter for status
  Future<void> updateBoxStatus(
      String boxId,
      BoxStatus status, {
        String? collectorName,
      }) async {
    final query = await _db
        .collection('boxes')
        .where('boxId', isEqualTo: boxId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Box with boxId $boxId not found");
    }

    final docId = query.docs.first.id;

    final updateData = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only store collectorName when provided
    if (collectorName != null) {
      updateData['collectorName'] = collectorName;
    }

    await _db.collection('boxes').doc(docId).update(updateData);
  }


  /* -------------------- Admin Info Method -------------------- */

  static const String _adminCollection = 'admin';

  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc('info')
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveAdminInfo(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(_adminCollection)
        .doc('info')
        .set(data, SetOptions(merge: true));
  }

  Future<bool> loginAdmin(String username, String password) async {
    final doc = await _db
        .collection('admin')
        .doc('info')
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;

    if (data['isActive'] != true) return false;

    return data['username'] == username &&
        data['password'] == password;
  }


// firebase_service.dart
  Future<void> resetAllBoxesStatus() async {
    final firestore = FirebaseFirestore.instance;

    final query = await firestore.collection('boxes').get();
    final batch = firestore.batch();

    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'status': BoxStatus.notCollected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /* -------------------- CASH RECEIPT METHODS -------------------- */

  Future<String> _nextReceiptId() async {
    final now = DateTime.now();
    final monthKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}';
    final counterRef = _db
        .collection('meta')
        .doc('counters')
        .collection('cash_receipts')
        .doc(monthKey);

    final counter = await _db.runTransaction((txn) async {
      final snapshot = await txn.get(counterRef);
      final current = snapshot.exists
          ? ((snapshot.data()?['value'] as num?)?.toInt() ?? 0)
          : 0;
      final next = current + 1;
      txn.set(counterRef, {'value': next}, SetOptions(merge: true));
      return next;
    });

    return 'CR-$monthKey-${counter.toString().padLeft(4, '0')}';
  }

  Future<String> addCashReceipt({
    required String payeeName,
    String payeeTitle = '',
    required double amount,
    required String purpose,
    required DateTime date,
    String paymentMethod = 'cash',
    String receivedBy = '',
  }) async {
    final doc = _db.collection(_cashReceiptsCollection).doc();
    final now = DateTime.now();
    final receiptId = await _nextReceiptId();
    final receipt = CashReceiptModel(
      id: doc.id,
      receiptId: receiptId,
      payeeTitle: payeeTitle,
      payeeName: payeeName,
      amount: amount,
      purpose: purpose,
      date: date,
      createdAt: now,
      paymentMethod: paymentMethod,
      receivedBy: receivedBy,
    );
    await doc.set({
      'id': doc.id,
      ...receipt.toMap(),
    });
    return doc.id;
  }

  /// Updates editable fields only. [receiptId] and [createdAt] are not changed.
  Future<void> updateCashReceipt(CashReceiptModel receipt) async {
    await _db.collection(_cashReceiptsCollection).doc(receipt.id).update({
      'payeeTitle': receipt.payeeTitle,
      'payeeName': receipt.payeeName,
      'amount': receipt.amount,
      'purpose': receipt.purpose,
      'date': Timestamp.fromDate(receipt.date),
      'paymentMethod': receipt.paymentMethod,
      'receivedBy': receipt.receivedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<CashReceiptModel>> getCashReceiptsStream() {
    return _db
        .collection(_cashReceiptsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CashReceiptModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<double> getCurrentMonthCashTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final query = await _db
        .collection(_cashReceiptsCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    return query.docs.fold<double>(0, (sum, doc) {
      final data = doc.data();
      return sum + (data['amount'] ?? 0).toDouble();
    });
  }



}
