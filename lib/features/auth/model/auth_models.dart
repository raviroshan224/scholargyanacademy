class UserModel {
  final String id;
  final String email;
  final String? provider;
  final String? socialId;
  final String? fullName;
  final String? mobileNumber;
  final bool? hasConfirmedToTerms;
  final bool? isVerified;
  final Map<String, dynamic>? photo;
  final Map<String, dynamic>? role;
  final Map<String, dynamic>? status;
  final List<String>? favoriteCategories;
  final bool? hasSelectedCategories;
  final List<String>? savedCourses;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.email,
    this.provider,
    this.socialId,
    this.fullName,
    this.mobileNumber,
    this.hasConfirmedToTerms,
    this.isVerified,
    this.photo,
    this.role,
    this.status,
    this.favoriteCategories,
    this.hasSelectedCategories,
    this.savedCourses,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) =>
        date == null ? null : DateTime.tryParse(date);

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      provider: json['provider'],
      socialId: json['socialId'],
      fullName: json['fullName'],
      mobileNumber: json['mobileNumber'],
      hasConfirmedToTerms: json['hasConfirmedToTerms'],
      isVerified: json['isVerified'],
      photo: json['photo'] is Map
          ? Map<String, dynamic>.from(json['photo'])
          : null,
      role:
          json['role'] is Map ? Map<String, dynamic>.from(json['role']) : null,
      status: json['status'] is Map
          ? Map<String, dynamic>.from(json['status'])
          : null,
      favoriteCategories: (json['favoriteCategories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      hasSelectedCategories: json['hasSelectedCategories'],
      savedCourses:
          (json['savedCourses'] as List?)?.map((e) => e.toString()).toList(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      deletedAt: parseDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'provider': provider,
      'socialId': socialId,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'hasConfirmedToTerms': hasConfirmedToTerms,
      'isVerified': isVerified,
      'photo': photo,
      'role': role,
      'status': status,
      'favoriteCategories': favoriteCategories,
      'hasSelectedCategories': hasSelectedCategories,
      'savedCourses': savedCourses,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

class AuthTokensModel {
  final String token;
  final String refreshToken;
  final int tokenExpires;

  AuthTokensModel({
    required this.token,
    required this.refreshToken,
    required this.tokenExpires,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenExpires: json['tokenExpires'] is int ? json['tokenExpires'] : 0,
    );
  }
}

class AuthResponseModel {
  final String token;
  final String refreshToken;
  final int tokenExpires;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.refreshToken,
    required this.tokenExpires,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenExpires: json['tokenExpires'] is int ? json['tokenExpires'] : 0,
      user: UserModel.fromJson(json['user']),
    );
  }
}

class ProfileUpdateModel {
  final String? fullName;
  final String? email;
  final String? mobileNumber;

  ProfileUpdateModel({
    this.fullName,
    this.email,
    this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    if (mobileNumber != null) data['mobileNumber'] = mobileNumber;
    return data;
  }
}

class PasswordUpdateModel {
  final String oldPassword;
  final String newPassword;

  PasswordUpdateModel({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
