/// 공유 아카이브 모델
///
/// 친구들과 함께 경기 기록을 모아두는 공동 앨범입니다.
/// 여러 사용자가 게시물을 추가하고 함께 추억을 공유할 수 있습니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedArchive {
  final String id;
  final String name;                // 아카이브 이름
  final String description;         // 설명
  final String createdBy;           // 생성자 userId
  final List<String> members;       // 멤버 userId 목록
  final List<String> posts;         // 게시물 ID 목록
  final String? coverImage;         // 커버 이미지 URL
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // 추가 메타데이터

  SharedArchive({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.members,
    required this.posts,
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': members,
      'posts': posts,
      'coverImage': coverImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Firestore 문서에서 생성
  factory SharedArchive.fromMap(String id, Map<String, dynamic> map) {
    return SharedArchive(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdBy: map['createdBy'] as String,
      members: List<String>.from(map['members'] as List? ?? []),
      posts: List<String>.from(map['posts'] as List? ?? []),
      coverImage: map['coverImage'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Firestore 문서 스냅샷에서 생성
  factory SharedArchive.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedArchive.fromMap(doc.id, data);
  }

  /// 복사본 생성
  SharedArchive copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? members,
    List<String>? posts,
    String? coverImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SharedArchive(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      posts: posts ?? this.posts,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 멤버 수
  int get memberCount => members.length;

  /// 게시물 수
  int get postCount => posts.length;

  /// 현재 사용자가 생성자인지 확인
  bool isCreator(String userId) => createdBy == userId;

  /// 현재 사용자가 멤버인지 확인
  bool isMember(String userId) => members.contains(userId);

  /// 비어있는 아카이브인지 확인
  bool get isEmpty => posts.isEmpty;

  @override
  String toString() {
    return 'SharedArchive(id: $id, name: $name, members: ${members.length}, posts: ${posts.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SharedArchive && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
