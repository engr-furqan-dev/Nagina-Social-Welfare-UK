import 'package:cloud_firestore/cloud_firestore.dart';

class BoxModel {
  final String id;
  final String boxId;
  final String venueName;

  final String contactPersonName;
  final String contactPersonPhone;
  final double totalCollected;
  final DateTime createdAt;
  final DateTime updatedAt;
  BoxStatus status;
  DateTime? completedAt;
  final int boxSequence;


  BoxModel({
    required this.id,
    required this.boxId,
    required this.venueName,
    required this.contactPersonName,
    required this.contactPersonPhone,
    required this.totalCollected,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.status = BoxStatus.notCollected,
    required this.boxSequence,

  });
  // 👇 ADD copyWith() HERE
  BoxModel copyWith({
    String? id,
    String? boxId,
    int? boxSequence,
    String? venueName,
    String? contactPersonName,
    String? contactPersonPhone,
    double? totalCollected,
    DateTime? createdAt,
    DateTime? updatedAt,
    BoxStatus? status,
    DateTime? completedAt,
  }) {
    return BoxModel(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      boxSequence: boxSequence ?? this.boxSequence,
      venueName: venueName ?? this.venueName,
      contactPersonName:
      contactPersonName ?? this.contactPersonName,
      contactPersonPhone:
      contactPersonPhone ?? this.contactPersonPhone,
      totalCollected:
      totalCollected ?? this.totalCollected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'boxId': boxId,
      'venueName': venueName,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'totalCollected': totalCollected,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status.name,
      'completedAt': completedAt,
      'boxSequence': boxSequence,


    };
  }

  factory BoxModel.fromMap(String docId, Map<String, dynamic> map) {
    return BoxModel(
      id: docId,
      boxId: map['boxId'] ?? '',
      venueName: map['venueName'] ?? '',
      contactPersonName: map['contactPersonName'] ?? map['ownerName'] ?? '',
      contactPersonPhone: map['contactPersonPhone'] ?? map['ownerPhone'] ?? '',
      totalCollected: (map['totalCollected'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      boxSequence: map['boxSequence'] ?? 0,

      status: BoxStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => BoxStatus.notCollected,
      ),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,


    );
  }

  bool isSame(BoxModel other) {
    return venueName == other.venueName &&
        contactPersonPhone == other.contactPersonPhone &&
        contactPersonName == other.contactPersonName;
  }


}
// ✅ Enum must be OUTSIDE the class
enum BoxStatus {
  notCollected,
  collected,
  sentReceipt,
}
