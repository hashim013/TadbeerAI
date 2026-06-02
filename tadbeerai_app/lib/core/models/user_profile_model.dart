class UserProfileModel {
  final String mode; // guest/account
  final String category; // shop/business/employee/student
  final String name;
  final String email;
  final String phone;
  final Map<String, dynamic> profileData;
  final String fcmToken;

  UserProfileModel({
    required this.mode,
    required this.category,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileData,
    required this.fcmToken,
  });

  UserProfileModel copyWith({
    String? mode,
    String? category,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? profileData,
    String? fcmToken,
  }) {
    return UserProfileModel(
      mode: mode ?? this.mode,
      category: category ?? this.category,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileData: profileData ?? this.profileData,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'category': category,
        'name': name,
        'email': email,
        'phone': phone,
        'profileData': profileData,
        'fcmToken': fcmToken,
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        mode: json['mode'] as String? ?? 'guest',
        category: json['category'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        profileData: Map<String, dynamic>.from(json['profileData'] ?? {}),
        fcmToken: json['fcmToken'] as String? ?? '',
      );

  factory UserProfileModel.empty() => UserProfileModel(
        mode: 'guest',
        category: '',
        name: '',
        email: '',
        phone: '',
        profileData: {},
        fcmToken: '',
      );
}
