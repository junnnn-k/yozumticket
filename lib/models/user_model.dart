import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Users 컬렉션 모델
///
/// 사용자 프로필 정보를 저장합니다.
class UserModel {
  final String uid;
  final String email;
  final String username;
  final String profileImageUrl;
  final List<String> favoriteTeams; // 응원하는 팀 목록 (복수 선택 가능)
  final String bio; // 자기소개
  final DateTime createdAt;
  final bool showProfile; // 프로필 공개 여부
  final bool allowFriendRequests; // 친구 요청 허용 여부

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.profileImageUrl,
    required this.favoriteTeams,
    required this.bio,
    required this.createdAt,
    this.showProfile = true,
    this.allowFriendRequests = true,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'favoriteTeams': favoriteTeams,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'showProfile': showProfile,
      'allowFriendRequests': allowFriendRequests,
    };
  }

  /// Firestore 문서에서 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      favoriteTeams: List<String>.from(json['favoriteTeams'] as List? ?? []),
      bio: json['bio'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      showProfile: json['showProfile'] as bool? ?? true,
      allowFriendRequests: json['allowFriendRequests'] as bool? ?? true,
    );
  }

  /// Firestore DocumentSnapshot에서 생성
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// 복사본 생성 (일부 필드 수정)
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    List<String>? favoriteTeams,
    String? bio,
    DateTime? createdAt,
    bool? showProfile,
    bool? allowFriendRequests,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      showProfile: showProfile ?? this.showProfile,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
    );
  }

  /// 유효성 검증
  bool get isValid {
    return uid.isNotEmpty && email.isNotEmpty && username.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, email: $email)';
  }
}
