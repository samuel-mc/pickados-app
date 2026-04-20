class AuthSession {
  AuthSession({
    required this.userId,
    required this.username,
    required this.role,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  final int userId;
  final String username;
  final String role;

  bool get isTipster => role == 'ROLE_TIPSTER';
}
