import 'user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final String? className; // For students
  final String? subject; // For teachers

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
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
    UserRole? role,
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
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      className: className ?? this.className,
      subject: subject ?? this.subject,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString() == 'UserRole.${json['role']}'),
      isActive: json['isActive'] == null ? true : (json['isActive'] == 1 || json['isActive'] == true),
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
      'role': role.name,
      'isActive': isActive ? 1 : 0,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'className': className,
      'subject': subject,
    };
  }
}
