import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class TwilioService {
  static const String _collectionName = 'twilio_credentials';
  static const String _documentId = 'uv90i5Nh85Hp38XDSB1h';

  /// Fetches Twilio credentials from Firestore and sends an SMS to the `toNumber`.
  static Future<void> sendSMS({
    required String toNumber,
    required String messageBody,
  }) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Twilio credentials document not found in Firestore.');
      }

      final data = docSnapshot.data()!;
      final accountSid = data['Account_SID'] as String?;
      final authToken = data['Auth_Token'] as String?;
      final twilioNumber = data['Phone_Number'] as String?;

      if (accountSid == null || authToken == null || twilioNumber == null) {
        throw Exception('Incomplete Twilio credentials in Firestore.');
      }

      final twilioFlutter = TwilioFlutter(
        accountSid: accountSid,
        authToken: authToken,
        twilioNumber: twilioNumber,
      );

      await twilioFlutter.sendSMS(
        toNumber: toNumber,
        messageBody: messageBody,
      );

      debugPrint('Twilio SMS sent successfully to $toNumber');
    } catch (e) {
      debugPrint('TwilioService Error: $e');
      rethrow;
    }
  }
}
