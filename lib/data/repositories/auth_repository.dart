import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      UserModel? model;
      if (doc.exists && doc.data() != null) {
        model = UserModel.fromMap(doc.data()!, doc.id);
      }

      // If missing or user role, check if user is a mess partner in 'messes' collection
      if (model == null || model.role == UserRole.user) {
        final messDoc = await _firestore.collection(AppConstants.messesCollection).doc(uid).get();
        if (messDoc.exists) {
          model = (model ?? UserModel(id: uid, name: 'Partner', email: _auth.currentUser?.email ?? '')).copyWith(
            role: UserRole.admin,
          );
        } else {
          final querySnap = await _firestore
              .collection(AppConstants.messesCollection)
              .where('adminId', isEqualTo: uid)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            model = (model ?? UserModel(id: uid, name: 'Partner', email: _auth.currentUser?.email ?? '')).copyWith(
              role: UserRole.admin,
            );
          }
        }
      }
      return model;
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> watchUserData(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .asyncMap((doc) async {
      UserModel? model;
      if (doc.exists && doc.data() != null) {
        model = UserModel.fromMap(doc.data()!, doc.id);
      }

      // Check if user owns a mess in 'messes' collection (matches website AuthContext.jsx)
      if (model == null || model.role == UserRole.user) {
        try {
          final messDoc = await _firestore.collection(AppConstants.messesCollection).doc(uid).get();
          if (messDoc.exists) {
            model = (model ?? UserModel(id: uid, name: 'Partner', email: _auth.currentUser?.email ?? '')).copyWith(
              role: UserRole.admin,
            );
          } else {
            final messQuery = await _firestore
                .collection(AppConstants.messesCollection)
                .where('adminId', isEqualTo: uid)
                .limit(1)
                .get();
            if (messQuery.docs.isNotEmpty) {
              model = (model ?? UserModel(id: uid, name: 'Partner', email: _auth.currentUser?.email ?? '')).copyWith(
                role: UserRole.admin,
              );
            }
          }
        } catch (_) {}
      }

      return model;
    });
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> saveUserData(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toMap());
  }

  Future<void> updateUserPhone(String uid, String phone) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'phone': phone});
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> deleteUserData(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }
}
