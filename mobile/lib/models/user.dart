import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('teacher')
  teacher,
  @JsonValue('admin')
  admin,
}

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? pushToken;
  final String? telegramChatId;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.pushToken,
    this.telegramChatId,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get displayRole {
    switch (role) {
      case UserRole.student:
        return 'Ученик';
      case UserRole.teacher:
        return 'Преподаватель';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
