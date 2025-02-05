class GemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String cloudinaryUrl;
  final String cloudinaryPublicId;
  final DateTime createdAt;
  final int bytes;
  final List<String> likes;
  final List<String> tags;
  final bool isPublic;

  GemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.cloudinaryUrl,
    required this.cloudinaryPublicId,
    DateTime? createdAt,
    required this.bytes,
    List<String>? likes,
    List<String>? tags,
    this.isPublic = true,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.likes = likes ?? [],
    this.tags = tags ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'cloudinaryUrl': cloudinaryUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'createdAt': createdAt.toIso8601String(),
      'bytes': bytes,
      'likes': likes,
      'tags': tags,
      'isPublic': isPublic,
    };
  }

  factory GemModel.fromMap(Map<String, dynamic> map) {
    return GemModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      cloudinaryUrl: map['cloudinaryUrl'] as String,
      cloudinaryPublicId: map['cloudinaryPublicId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      bytes: map['bytes'] as int,
      likes: List<String>.from(map['likes'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      isPublic: map['isPublic'] as bool? ?? true,
    );
  }

  GemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? cloudinaryUrl,
    String? cloudinaryPublicId,
    DateTime? createdAt,
    int? bytes,
    List<String>? likes,
    List<String>? tags,
    bool? isPublic,
  }) {
    return GemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      createdAt: createdAt ?? this.createdAt,
      bytes: bytes ?? this.bytes,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
    );
  }
} 