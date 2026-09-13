/// Backend public user shape (`toPublicUser`).
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
    required this.isActive,
  });

  final String id;
  final String email;
  final String role;
  final String name;
  final String? phone;
  final bool isActive;

  bool get isAdmin => role == "ADMIN";

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json["id"] as String,
      email: json["email"] as String,
      role: json["role"] as String,
      name: json["name"] as String,
      phone: json["phone"] as String?,
      isActive: json["isActive"] as bool? ?? true,
    );
  }
}

/// Backend `{ user, accessToken, refreshToken }` payload.
class AuthPayload {
  const AuthPayload({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      user: AppUser.fromJson(json["user"] as Map<String, dynamic>),
      accessToken: json["accessToken"] as String,
      refreshToken: json["refreshToken"] as String,
    );
  }
}

