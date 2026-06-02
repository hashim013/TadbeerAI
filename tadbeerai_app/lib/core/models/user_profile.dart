class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.phone,
    this.displayName = '',
    this.notifySms = true,
    this.notifyEmail = true,
    this.notifyPush = true,
    this.fcmToken,
    this.profileComplete = false,
  });

  final String uid;
  final String email;
  final String phone;
  final String displayName;
  final bool notifySms;
  final bool notifyEmail;
  final bool notifyPush;
  final String? fcmToken;
  final bool profileComplete;

  bool get canReceiveNotifications =>
      (notifySms || notifyEmail || notifyPush) &&
      (phone.isNotEmpty || email.isNotEmpty);

  UserProfile copyWith({
    String? email,
    String? phone,
    String? displayName,
    bool? notifySms,
    bool? notifyEmail,
    bool? notifyPush,
    String? fcmToken,
    bool? profileComplete,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      notifySms: notifySms ?? this.notifySms,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      notifyPush: notifyPush ?? this.notifyPush,
      fcmToken: fcmToken ?? this.fcmToken,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'phone': phone,
        'display_name': displayName,
        'notify_sms': notifySms,
        'notify_email': notifyEmail,
        'notify_push': notifyPush,
        'fcm_token': fcmToken,
        'profile_complete': profileComplete,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        notifySms: json['notify_sms'] as bool? ?? true,
        notifyEmail: json['notify_email'] as bool? ?? true,
        notifyPush: json['notify_push'] as bool? ?? true,
        fcmToken: json['fcm_token'] as String?,
        profileComplete: json['profile_complete'] as bool? ?? false,
      );
}
