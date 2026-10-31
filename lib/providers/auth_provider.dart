import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/notification_service.dart';
import '../core/services/analytics_tracker.dart';
import 'mess_provider.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AuthRepository(auth: auth, firestore: firestore);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final repository = ref.watch(authRepositoryProvider);
      return repository.watchUserData(user.uid).map((profile) {
        if (profile != null) {
          if ((profile.photoUrl == null || profile.photoUrl!.isEmpty) && user.photoURL != null) {
            profile = profile.copyWith(photoUrl: user.photoURL);
          }
          AnalyticsTracker.instance.identifyUser(
            profile.id,
            role: profile.role.name,
            email: profile.email,
            name: profile.name,
          );
        }
        return profile;
      });
    },
    loading: () => Stream.value(null),
    error: (error, stackTrace) => Stream.value(null),
  );
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password);
      // Save FCM token after successful login
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        await NotificationService.saveTokenToFirestore(user.uid);
        NotificationService.listenForTokenRefresh(user.uid);
      }
    });
    AnalyticsTracker.instance.trackLoginAttempt(
      !state.hasError,
      method: 'email',
      errorMsg: state.error?.toString(),
    );
    return !state.hasError;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final credential = await repo.createUserWithEmailAndPassword(email, password);
      
      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: UserRole.user,
          createdAt: DateTime.now(),
        );
        
        await repo.saveUserData(newUser);
      }
    });
    AnalyticsTracker.instance.trackSignupAttempt(
      !state.hasError,
      method: 'email',
      role: 'student',
      errorMsg: state.error?.toString(),
    );
    return !state.hasError;
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      User? user;
      
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await ref.read(firebaseAuthProvider).signInWithPopup(googleProvider);
        user = userCredential.user;
      } else {
        final googleSignIn = GoogleSignIn.instance;
        final googleUser = await googleSignIn.authenticate();
        
        final googleAuth = googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await ref.read(authRepositoryProvider).signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user != null) {
        final repo = ref.read(authRepositoryProvider);
        final userDoc = await repo.getUserData(user.uid);

        if (userDoc == null) {
          final newUser = UserModel(
            id: user.uid,
            name: user.displayName ?? 'New User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            role: UserRole.user,
            createdAt: DateTime.now(),
          );
          await repo.saveUserData(newUser);
        } else if (user.photoURL != null && (userDoc.photoUrl == null || userDoc.photoUrl!.isEmpty)) {
          await repo.saveUserData(userDoc.copyWith(photoUrl: user.photoURL));
        }

        // Save FCM token after successful Google sign-in
        await NotificationService.saveTokenToFirestore(user.uid);
        NotificationService.listenForTokenRefresh(user.uid);
      }
    });
    AnalyticsTracker.instance.trackLoginAttempt(
      !state.hasError,
      method: 'google',
      errorMsg: state.error?.toString(),
    );
    return !state.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await GoogleSignIn.instance.signOut();
      await ref.read(authRepositoryProvider).signOut();
    });
    AnalyticsTracker.instance.trackLogout();
  }

  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('No user is currently logged in.');

      // 1. Delete Firestore user document
      await ref.read(authRepositoryProvider).deleteUserData(user.uid);

      // 2. Delete Firebase Auth user
      await user.delete();

      // 3. Sign out from Google
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    });
    AnalyticsTracker.instance.trackAccountDelete(
      !state.hasError,
      errorMsg: state.error?.toString(),
    );
    return !state.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});
