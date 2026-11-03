import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
    final FirebaseAuth authie = FirebaseAuth.instance;

    User? get currentUser => authie.currentUser;

    Stream<User?> get authStateChanges => authie.authStateChanges();

    Future<UserCredential> registerUser(
        String email,
        String password,
    ) async {
        return await authie.createUserWithEmailAndPassword(
            email: email.trim(), 
            password: password
        );
    }

    Future<UserCredential> loginUser(
        String email,
        String password,
    ) async {
        return await authie.signInWithEmailAndPassword(
            email: email.trim(), 
            password: password,
        );
    }

    Future<void> resetPassword(String email) async {
        await authie.sendPasswordResetEmail(
            email: email.trim(),
        );
    }

    Future<void> logoutUser() async {
        await authie.signOut();
    }


}