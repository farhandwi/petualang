class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
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

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profilePicture: json['profile_picture'] as String?,
      nik: json['nik'] as String?,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      gender: json['gender'] as String?,
      ktpAddress: json['ktp_address'] as String?,
      domicileAddress: json['domicile_address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      heightCm: json['height_cm'] as int?,
      weightKg: json['weight_kg'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
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
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePicture,
    String? nik,
    DateTime? dateOfBirth,
    String? gender,
    String? ktpAddress,
    String? domicileAddress,
    String? emergencyContactName,
    String? emergencyContactPhone,
    int? heightCm,
    int? weightKg,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
      nik: nik ?? this.nik,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      ktpAddress: ktpAddress ?? this.ktpAddress,
      domicileAddress: domicileAddress ?? this.domicileAddress,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  double get profileCompleteness {
    int filled = 0;
    if (name.isNotEmpty) filled++;
    if (email.isNotEmpty) filled++;
    if (phone != null && phone!.isNotEmpty) filled++;
    if (profilePicture != null && profilePicture!.isNotEmpty) filled++;
    if (nik != null && nik!.isNotEmpty) filled++;
    if (dateOfBirth != null) filled++;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (ktpAddress != null && ktpAddress!.isNotEmpty) filled++;
    if (domicileAddress != null && domicileAddress!.isNotEmpty) filled++;
    if (emergencyContactName != null && emergencyContactName!.isNotEmpty && emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty) filled++;
    if (heightCm != null) filled++;
    if (weightKg != null) filled++;

    return filled / 12.0;
  }
}
