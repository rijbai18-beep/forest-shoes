import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = await getUserData(cred.user!.uid);
    if (user == null) throw Exception('User data not found.');
    if (!user.isActive) {
      await _auth.signOut();
      throw Exception('Your account has been deactivated. Please contact support.');
    }
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await cred.user!.updateDisplayName(name);

    final userModel = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name,
      phone: phone,
      isActive: true,
      isAdmin: false,
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.colUsers)
        .doc(cred.user!.uid)
        .set(userModel.toMap());

    return userModel;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      await _auth.currentUser?.updateDisplayName(name);
    }
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _db.collection(AppConstants.colUsers).doc(uid).update(updates);
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  Future<void> addAddress(String uid, Map<String, dynamic> address) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'addresses': FieldValue.arrayUnion([address]),
    });
  }

  Future<void> setAddresses(
      String uid, List<Map<String, dynamic>> addresses) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({'addresses': addresses});
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
