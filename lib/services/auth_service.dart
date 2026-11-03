import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import 'user_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, UserService? users})
    : _auth = auth ?? FirebaseAuth.instance,
      _users = users ?? UserService();

  final FirebaseAuth _auth;
  final UserService _users;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String authErrorMessage(
    Object error, {
    required bool creatingAccount,
  }) {
    if (error is! FirebaseAuthException) {
      return 'Unable to ${creatingAccount ? 'create your account' : 'sign in'}. '
          'Please try again.';
    }
    return switch (error.code) {
      'email-already-in-use' =>
        'This email is already registered in Clean Connect. Sign in instead.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Choose a stronger password.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'The email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'operation-not-allowed' =>
        'Email sign-in is unavailable. Contact the app administrator.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Unable to connect. Check your internet connection and try again.',
      _ =>
        error.message ??
            'Unable to ${creatingAccount ? 'create your account' : 'sign in'}. '
                'Please try again.',
    };
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return the newly created user.');
    }

    await user.updateDisplayName(fullName.trim());
    await _users.saveProfile(
      AppUserModel(
        uid: user.uid,
        fullName: fullName.trim(),
        email: user.email ?? email.trim(),
        role: 'student',
        isActive: true,
      ),
    );
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}