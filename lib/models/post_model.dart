import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_info.dart';

/// 게시글 데이터 모델
class Post {
  final String id;
  final String userId;
  final String ticketImageUrl;
  final List<String> additionalPhotoUrls;
  final GameInfo gameInfo;
  final String title;
  final String content;
  final List<String> tags;
  final double rating;
  final String privacy; // 'private', 'friends', 'public'
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    required this.ticketImageUrl,
    this.additionalPhotoUrls = const [],
    required this.gameInfo,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.rating = 0.0,
    this.privacy = 'private',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ticketImageUrl': ticketImageUrl,
      'additionalPhotoUrls': additionalPhotoUrls,
      'gameInfo': {
        'date': gameInfo.date != null
            ? Timestamp.fromDate(gameInfo.date!)
            : null,
        'homeTeam': gameInfo.homeTeam,
        'awayTeam': gameInfo.awayTeam,
        'stadium': gameInfo.stadium,
        'seat': gameInfo.seat,
        'price': gameInfo.price,
      },
      'title': title,
      'content': content,
      'tags': tags,
      'rating': rating,
      'privacy': privacy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Firestore 문서에서 변환
  factory Post.fromJson(Map<String, dynamic> json) {
    final gameInfoData = json['gameInfo'] as Map<String, dynamic>?;

    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      ticketImageUrl: json['ticketImageUrl'] as String,
      additionalPhotoUrls: (json['additionalPhotoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      gameInfo: GameInfo(
        date: gameInfoData?['date'] != null
            ? (gameInfoData!['date'] as Timestamp).toDate()
            : null,
        homeTeam: gameInfoData?['homeTeam'] as String?,
        awayTeam: gameInfoData?['awayTeam'] as String?,
        stadium: gameInfoData?['stadium'] as String?,
        seat: gameInfoData?['seat'] as String?,
        price: gameInfoData?['price'] as int?,
        confidence: 1.0, // Firestore에서 불러올 때는 신뢰도 100%
      ),
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      privacy: json['privacy'] as String? ?? 'private',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore 문서 스냅샷에서 변환
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post.fromJson({...data, 'id': doc.id});
  }

  /// 복사본 생성 (일부 필드 수정)
  Post copyWith({
    String? id,
    String? userId,
    String? ticketImageUrl,
    List<String>? additionalPhotoUrls,
    GameInfo? gameInfo,
    String? title,
    String? content,
    List<String>? tags,
    double? rating,
    String? privacy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ticketImageUrl: ticketImageUrl ?? this.ticketImageUrl,
      additionalPhotoUrls: additionalPhotoUrls ?? this.additionalPhotoUrls,
      gameInfo: gameInfo ?? this.gameInfo,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      privacy: privacy ?? this.privacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 게시글 유효성 검증
  bool get isValid {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        ticketImageUrl.isNotEmpty &&
        title.isNotEmpty &&
        gameInfo.date != null;
  }

  /// 프라이버시 레벨
  bool get isPrivate => privacy == 'private';
  bool get isFriendsOnly => privacy == 'friends';
  bool get isPublic => privacy == 'public';
}

/// 프라이버시 옵션
class Privacy {
  static const String private = 'private';
  static const String friends = 'friends';
  static const String publicPost = 'public';

  static const Map<String, String> labels = {
    private: '나만 보기',
    friends: '친구 공개',
    publicPost: '전체 공개',
  };

  static const Map<String, String> descriptions = {
    private: '나만 볼 수 있습니다',
    friends: '친구들에게만 공개됩니다',
    publicPost: '모든 사용자에게 공개됩니다',
  };
}
