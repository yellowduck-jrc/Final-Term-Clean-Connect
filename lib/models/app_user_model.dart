class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;

  factory AppUserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final activeValue = data['isActive'];
    final status = (data['status'] as String?)?.toLowerCase();
    return AppUserModel(
      uid: (data['uid'] as String?) ?? id ?? '',
      fullName:
          (data['fullName'] as String?) ?? (data['name'] as String?) ?? 'User',
      email: (data['email'] as String?) ?? '',
      role: ((data['role'] as String?) ?? 'student').toLowerCase(),
      isActive: activeValue is bool ? activeValue : status != 'inactive',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'role': role,
    'isActive': isActive,
  };
}
