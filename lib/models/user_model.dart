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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['additionalRoles'];
    List<UserRole> additionalRoles = [];
    if (rolesRaw is List && rolesRaw.isNotEmpty) {
      additionalRoles = rolesRaw
          .map((e) => UserRole.values.firstWhere(
                (r) => r.name == e.toString(),
                orElse: () => UserRole.teacher,
              ))
          .toList();
    } else if (rolesRaw is String && rolesRaw.isNotEmpty) {
      // backward-compat: old comma-separated format
      additionalRoles = rolesRaw
          .split(',')
          .map((r) => UserRole.values.firstWhere(
                (role) => role.name == r.trim(),
                orElse: () => UserRole.teacher,
              ))
          .toList();
    }
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      primaryRole: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.teacher,
      ),
      additionalRoles: additionalRoles,
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] == true || json['isActive'] == 1),
      phone: json['phone'],
      address: json['address'],
      profileImageUrl: json['profileImageUrl'],
      className: json['className'],
      subject: json['subject'],
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
