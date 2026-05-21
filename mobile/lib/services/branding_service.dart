import 'package:cloud_firestore/cloud_firestore.dart';

class BrandingService {
  final _db = FirebaseFirestore.instance;

  Stream<String?> watchLogoUrl() {
    return _db
        .collection('settings')
        .doc('branding')
        .snapshots()
        .map((snap) => snap.data()?['logoUrl'] as String?);
  }
}
