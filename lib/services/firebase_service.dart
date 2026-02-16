import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/box_model.dart';
import '../models/collection_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* -------------------- BOX METHODS -------------------- */

  /// Add a new charity box
  Future<void> addBox(BoxModel box) async {
    await _db.collection('boxes').add(box.toMap());
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



}
