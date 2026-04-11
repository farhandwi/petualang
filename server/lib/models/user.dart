class User {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? passwordHash;
  final String? passwordSalt;
  final String? profilePicture;
  final String? nik;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? ktpAddress;
  final String? domicileAddress;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final int? heightCm;
  final int? weightKg;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.passwordHash,
    this.passwordSalt,
    this.profilePicture,
    this.nik,
    this.dateOfBirth,
    this.gender,
    this.ktpAddress,
    this.domicileAddress,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.heightCm,
    this.weightKg,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      passwordHash: map['password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
      profilePicture: map['profile_picture'] as String?,
      nik: map['nik'] as String?,
      dateOfBirth: map['date_of_birth'] as DateTime?,
      gender: map['gender'] as String?,
      ktpAddress: map['ktp_address'] as String?,
      domicileAddress: map['domicile_address'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      heightCm: map['height_cm'] as int?,
      weightKg: map['weight_kg'] as int?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'nik': nik,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'ktp_address': ktpAddress,
      'domicile_address': domicileAddress,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
