import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUserModel> ensureProfile(User user) async {
    final profile = await _users.doc(user.uid).get();
    if (profile.exists) {
      return AppUserModel.fromMap(profile.data()!, id: profile.id);
    }

    final legacyProfile = await _users
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (legacyProfile.docs.isNotEmpty) {
      final data = legacyProfile.docs.first.data();
      return AppUserModel.fromMap(data, id: user.uid);
    }

    final created = AppUserModel(
      uid: user.uid,
      fullName: user.displayName ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      role: 'student',
      isActive: true,
    );
    await saveProfile(created);
    return created;
  }

  Stream<AppUserModel?> watchProfile(User user) async* {
    await ensureProfile(user);
    yield* watchUser(user.uid);
  }

  Future<AppUserModel?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (snapshot.exists) {
      return AppUserModel.fromMap(snapshot.data()!, id: snapshot.id);
    }
    final legacy = await _users.where('uid', isEqualTo: uid).limit(1).get();
    if (legacy.docs.isEmpty) return null;
    return AppUserModel.fromMap(legacy.docs.first.data(), id: uid);
  }

  Stream<AppUserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().asyncMap((snapshot) async {
      if (snapshot.exists) {
        return AppUserModel.fromMap(snapshot.data()!, id: snapshot.id);
      }
      final legacy = await _users.where('uid', isEqualTo: uid).limit(1).get();
      if (legacy.docs.isEmpty) return null;
      return AppUserModel.fromMap(legacy.docs.first.data(), id: uid);
    });
  }

  Stream<List<AppUserModel>> watchUsers() {
    return _mapUsers(_users.snapshots());
  }

  Stream<List<AppUserModel>> watchUsersByRole(String role) {
    _validateRole(role);
    final titleCaseRole =
        '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}';
    return _mapUsers(
      _users
          .where(
            'role',
            whereIn: [role.toLowerCase(), titleCaseRole, role.toUpperCase()],
          )
          .snapshots(),
    );
  }

  Stream<List<AppUserModel>> _mapUsers(
    Stream<QuerySnapshot<Map<String, dynamic>>> source,
  ) {
    return source.map((snapshot) {
      final users =
          snapshot.docs
              .map((doc) => AppUserModel.fromMap(doc.data(), id: doc.id))
              .toList()
            ..sort(
              (a, b) =>
                  a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
            );
      return users;
    });
  }

  Future<void> saveProfile(AppUserModel user) {
    return _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateAccountAccess({
    required String uid,
    required String role,
    required bool isActive,
  }) {
    _validateRole(role);
    return _users.doc(uid).update({'role': role, 'isActive': isActive});
  }

  void _validateRole(String role) {
    if (!{'student', 'staff', 'admin'}.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Unsupported account role.');
    }
  }
}
