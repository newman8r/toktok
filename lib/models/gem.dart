class Gem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String cloudinaryUrl;
  final String cloudinaryPublicId;
  final int bytes;
  final List<String> tags;
  final DateTime createdAt;
  final String? sourceGemId;

  Gem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.cloudinaryUrl,
    required this.cloudinaryPublicId,
    required this.bytes,
    this.tags = const [],
    required this.createdAt,
    this.sourceGemId,
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
      'createdAt': createdAt.toIso8601String(),
      'sourceGemId': sourceGemId,
    };
  }

  factory Gem.fromMap(Map<String, dynamic> map, String id) {
    return Gem(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      cloudinaryUrl: map['cloudinaryUrl'] as String,
      cloudinaryPublicId: map['cloudinaryPublicId'] as String,
      bytes: map['bytes'] as int,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      sourceGemId: map['sourceGemId'] as String?,
    );
  }
} 