import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> createUserDocument(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);

    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      projectIds: [],
      createdAt: DateTime.now(),
      isOnline: true,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update online status — don't crash if this fails
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .update({'isOnline': true});
    } catch (_) {}

    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .get();

    if (!doc.exists) {
      // Create missing user document
      final userModel = UserModel(
        uid: credential.user!.uid,
        name: credential.user!.displayName ??
            email.split('@')[0],
        email: email,
        role: 'member',
        projectIds: [],
        createdAt: DateTime.now(),
        isOnline: true,
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());
      return userModel;
    }

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'isOnline': false});
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _db
        .collection(AppConstants.usersCollection)
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) =>
            doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}