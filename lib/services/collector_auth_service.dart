import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorAuthService {
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    // Check credentials in Firestore
    final query = await FirebaseFirestore.instance
        .collection('collectors')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;

      // Return map including ID
      return {
        'id': doc.id,
        ...doc.data(), // merge the document data
      };
    } else {
      return null;
    }
  }
}
