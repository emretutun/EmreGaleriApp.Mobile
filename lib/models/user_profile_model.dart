// lib/models/user_model.dart

class UserLicenseType {
  final int id;
  final String name;

  UserLicenseType({required this.id, required this.name});

  factory UserLicenseType.fromJson(Map<String, dynamic> json) {
    return UserLicenseType(
      id: json['id'],
      name: json['name'],
    );
  }
}

class UserProfile {
  final String id;
  final String userName;
  final String email;
  final String? nationalId;
  final String? gender;
  final String? pictureUrl;
  final DateTime? birthDate;
  final int? drivingExperienceYears;
  final List<UserLicenseType> licenseTypes;

  UserProfile({
    required this.id,
    required this.userName,
    required this.email,
    this.nationalId,
    this.gender,
    this.pictureUrl,
    this.birthDate,
    this.drivingExperienceYears,
    required this.licenseTypes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      nationalId: json['nationalId'],
      gender: json['gender'],
      pictureUrl: json['pictureUrl'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      drivingExperienceYears: json['drivingExperienceYears'],
      licenseTypes: (json['licenseTypes'] as List<dynamic>)
          .map((e) => UserLicenseType.fromJson(e))
          .toList(),
    );
  }
}
