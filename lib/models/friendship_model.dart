import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 관계 상태
class FriendshipStatus {
  static const String pending = 'pending'; // 대기 중
  static const String accepted = 'accepted'; // 수락됨
  static const String rejected = 'rejected'; // 거절됨
  static const String blocked = 'blocked'; // 차단됨
}

/// 친구 관계 모델
class Friendship {
  final String id; // Firestore 문서 ID
  final String requesterId; // 친구 요청을 보낸 사용자 ID
  final String receiverId; // 친구 요청을 받은 사용자 ID
  final String status; // 친구 관계 상태
  final DateTime createdAt; // 생성일
  final DateTime? updatedAt; // 수정일

  Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Firestore 문서로부터 Friendship 객체 생성
  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      requesterId: data['requesterId'] as String,
      receiverId: data['receiverId'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Friendship 객체를 Firestore 문서로 변환
  Map<String, dynamic> toJson() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// fromJson 생성자
  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String? ?? '',
      requesterId: json['requesterId'] as String,
      receiverId: json['receiverId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'] as String))
          : null,
    );
  }

  /// copyWith 메서드
  Friendship copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 친구 관계가 수락되었는지 확인
  bool get isAccepted => status == FriendshipStatus.accepted;

  /// 친구 관계가 대기 중인지 확인
  bool get isPending => status == FriendshipStatus.pending;

  /// 친구 관계가 차단되었는지 확인
  bool get isBlocked => status == FriendshipStatus.blocked;

  /// 상대방 사용자 ID 가져오기
  String getOtherUserId(String myUserId) {
    return requesterId == myUserId ? receiverId : requesterId;
  }

  /// 내가 요청자인지 확인
  bool isRequester(String myUserId) {
    return requesterId == myUserId;
  }
}
