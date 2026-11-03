
class AppUserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;

  AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  // Convert user information into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  // Convert Firestore data into an AppUserModel
  factory AppUserModel.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return AppUserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      status: data['status'] ?? 'active',
    );
  }
}
