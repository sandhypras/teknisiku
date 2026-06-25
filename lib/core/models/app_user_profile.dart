class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final bool isActive;

  factory AppUserProfile.fromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: AppRole.fromValue(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

enum AppRole {
  customer,
  technician,
  admin;

  static AppRole fromValue(String? value) {
    return switch (value) {
      'technician' => AppRole.technician,
      'admin' => AppRole.admin,
      _ => AppRole.customer,
    };
  }

  String get label {
    return switch (this) {
      AppRole.customer => 'Customer',
      AppRole.technician => 'Teknisi',
      AppRole.admin => 'Admin',
    };
  }
}
