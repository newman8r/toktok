class GemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String cloudinaryUrl;
  final String? cloudinaryPublicId;
  final int bytes;
  final List<String> tags;
  final List<String> likes;
  final DateTime createdAt;
  final String? sourceGemId;
  final String? lyrics;
  final String? style_preset;

  GemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.cloudinaryUrl,
    this.cloudinaryPublicId,
    required this.bytes,
    this.tags = const [],
    this.likes = const [],
    required this.createdAt,
    this.sourceGemId,
    this.lyrics,
    this.style_preset,
  });

  String get thumbnailUrl => cloudinaryUrl.replaceAll(
    RegExp(r'\/upload\/'),
    '/upload/w_400,h_400,c_fill,g_auto/'
  ).replaceAll(RegExp(r'\.[^.]+$'), '.jpg');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'cloudinaryUrl': cloudinaryUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'bytes': bytes,
      'tags': tags,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'sourceGemId': sourceGemId,
      'lyrics': lyrics,
      'style_preset': style_preset,
    };
  }

  factory GemModel.fromMap(Map<String, dynamic> map) {
    return GemModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      cloudinaryUrl: map['cloudinaryUrl'] as String,
      cloudinaryPublicId: map['cloudinaryPublicId'] as String?,
      bytes: map['bytes'] as int,
      tags: List<String>.from(map['tags'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      sourceGemId: map['sourceGemId'] as String?,
      lyrics: map['lyrics'] as String?,
      style_preset: map['style_preset'] as String?,
    );
  }

  GemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? cloudinaryUrl,
    String? cloudinaryPublicId,
    int? bytes,
    List<String>? tags,
    List<String>? likes,
    DateTime? createdAt,
    String? sourceGemId,
    String? lyrics,
    String? style_preset,
  }) {
    return GemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      bytes: bytes ?? this.bytes,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      sourceGemId: sourceGemId ?? this.sourceGemId,
      lyrics: lyrics ?? this.lyrics,
      style_preset: style_preset ?? this.style_preset,
    );
  }
} 