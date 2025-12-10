import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Users 컬렉션 모델
///
/// 사용자 프로필 정보를 저장합니다.
class UserModel {
  // 기본 프로필 정보
  final String uid;
  final String email;
  final String username;
  final String profileImageUrl;
  final List<String> favoriteTeams; // 응원하는 팀 목록 (복수 선택 가능)
  final String bio; // 자기소개
  final DateTime createdAt;
  final bool showProfile; // 프로필 공개 여부
  final bool allowFriendRequests; // 친구 요청 허용 여부

  // 비즈니스 모델 관련 필드 (v3.1)
  final bool isPremium; // 프리미엄 사용자 여부
  final String? subscriptionType; // 구독 유형: 'premium' | 'extra_photo' | 'family' | null
  final DateTime? subscriptionStartDate; // 구독 시작일
  final DateTime? subscriptionEndDate; // 구독 만료일
  final int maxPhotosPerPost; // 게시물당 사진 제한 (무료: 3, 프리미엄: 20)
  final int maxSharedArchives; // 공동 아카이브 제한 (무료: 2, 프리미엄: -1 무제한)
  final bool showBannerAds; // 배너 광고 표시 여부
  final int dailyRewardedAdCount; // 금일 리워드 광고 시청 횟수
  final DateTime? lastRewardedAdDate; // 마지막 리워드 광고 시청일
  final List<String> ownedThemes; // 구매한 테마 ID 목록
  final List<String> purchaseHistory; // 구매 이력 (productId 목록)

  // FCM 관련 필드 (v3.2)
  final String? fcmToken; // FCM 토큰 (푸시 알림용)

  UserModel({
    // 기본 프로필 정보
    required this.uid,
    required this.email,
    required this.username,
    required this.profileImageUrl,
    required this.favoriteTeams,
    required this.bio,
    required this.createdAt,
    this.showProfile = true,
    this.allowFriendRequests = true,
    // 비즈니스 모델 관련 필드 (기본값: 무료 사용자)
    this.isPremium = false,
    this.subscriptionType,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.maxPhotosPerPost = 3, // 무료 사용자 기본값
    this.maxSharedArchives = 2, // 무료 사용자 기본값
    this.showBannerAds = true, // 무료 사용자는 광고 표시
    this.dailyRewardedAdCount = 0,
    this.lastRewardedAdDate,
    this.ownedThemes = const [],
    this.purchaseHistory = const [],
    // FCM 관련 필드
    this.fcmToken,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toJson() {
    return {
      // 기본 프로필 정보
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'favoriteTeams': favoriteTeams,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'showProfile': showProfile,
      'allowFriendRequests': allowFriendRequests,
      // 비즈니스 모델 관련 필드
      'isPremium': isPremium,
      'subscriptionType': subscriptionType,
      'subscriptionStartDate': subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'maxPhotosPerPost': maxPhotosPerPost,
      'maxSharedArchives': maxSharedArchives,
      'showBannerAds': showBannerAds,
      'dailyRewardedAdCount': dailyRewardedAdCount,
      'lastRewardedAdDate': lastRewardedAdDate != null
          ? Timestamp.fromDate(lastRewardedAdDate!)
          : null,
      'ownedThemes': ownedThemes,
      'purchaseHistory': purchaseHistory,
      // FCM 관련 필드
      'fcmToken': fcmToken,
    };
  }

  /// Firestore 문서에서 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // 기본 프로필 정보
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      favoriteTeams: List<String>.from(json['favoriteTeams'] as List? ?? []),
      bio: json['bio'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      showProfile: json['showProfile'] as bool? ?? true,
      allowFriendRequests: json['allowFriendRequests'] as bool? ?? true,
      // 비즈니스 모델 관련 필드 (기존 사용자 마이그레이션 지원)
      isPremium: json['isPremium'] as bool? ?? false,
      subscriptionType: json['subscriptionType'] as String?,
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? (json['subscriptionStartDate'] as Timestamp).toDate()
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? (json['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      maxPhotosPerPost: json['maxPhotosPerPost'] as int? ?? 3,
      maxSharedArchives: json['maxSharedArchives'] as int? ?? 2,
      showBannerAds: json['showBannerAds'] as bool? ?? true,
      dailyRewardedAdCount: json['dailyRewardedAdCount'] as int? ?? 0,
      lastRewardedAdDate: json['lastRewardedAdDate'] != null
          ? (json['lastRewardedAdDate'] as Timestamp).toDate()
          : null,
      ownedThemes: List<String>.from(json['ownedThemes'] as List? ?? []),
      purchaseHistory: List<String>.from(json['purchaseHistory'] as List? ?? []),
      // FCM 관련 필드
      fcmToken: json['fcmToken'] as String?,
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
    bool? isPremium,
    String? subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    int? maxPhotosPerPost,
    int? maxSharedArchives,
    bool? showBannerAds,
    int? dailyRewardedAdCount,
    DateTime? lastRewardedAdDate,
    List<String>? ownedThemes,
    List<String>? purchaseHistory,
    String? fcmToken,
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
      isPremium: isPremium ?? this.isPremium,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      maxPhotosPerPost: maxPhotosPerPost ?? this.maxPhotosPerPost,
      maxSharedArchives: maxSharedArchives ?? this.maxSharedArchives,
      showBannerAds: showBannerAds ?? this.showBannerAds,
      dailyRewardedAdCount: dailyRewardedAdCount ?? this.dailyRewardedAdCount,
      lastRewardedAdDate: lastRewardedAdDate ?? this.lastRewardedAdDate,
      ownedThemes: ownedThemes ?? this.ownedThemes,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      fcmToken: fcmToken ?? this.fcmToken,
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
