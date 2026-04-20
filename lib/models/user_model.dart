import 'user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole primaryRole;
  final List<UserRole> additionalRoles;
  final bool isActive;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final String? className;
  final String? subject;

  UserRole get role => primaryRole;
  List<UserRole> get allRoles => [primaryRole, ...additionalRoles];

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.primaryRole,
    this.additionalRoles = const [],
    this.isActive = true,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.className,
    this.subject,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? primaryRole,
    List<UserRole>? additionalRoles,
    bool? isActive,
    String? phone,
    String? address,
    String? profileImageUrl,
    String? className,
    String? subject,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      primaryRole: primaryRole ?? this.primaryRole,
      additionalRoles: additionalRoles ?? this.additionalRoles,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      className: className ?? this.className,
      subject: subject ?? this.subject,
    );
  }

  /// Parses a role name to UserRole. Unknown names default to the least
  /// privileged role (student) to avoid accidental privilege escalation.
  static UserRole _parseRole(Object? raw) {
    if (raw == null) return UserRole.student;
    final name = raw.toString();
    for (final r in UserRole.values) {
      if (r.name == name) return r;
    }
    return UserRole.student;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['additionalRoles'];
    List<UserRole> additionalRoles = [];
    if (rolesRaw is List && rolesRaw.isNotEmpty) {
      additionalRoles = rolesRaw.map(_parseRole).toList();
    } else if (rolesRaw is String && rolesRaw.isNotEmpty) {
      // backward-compat: old comma-separated format
      additionalRoles =
          rolesRaw.split(',').map((r) => _parseRole(r.trim())).toList();
    }
    return UserModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      primaryRole: _parseRole(json['role']),
      additionalRoles: additionalRoles,
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] == true || json['isActive'] == 1),
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      className: json['className'] as String?,
      subject: json['subject'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': primaryRole.name,
      'additionalRoles': additionalRoles.map((r) => r.name).toList(),
      'isActive': isActive,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'className': className,
      'subject': subject,
    };
  }
}
