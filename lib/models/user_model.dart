class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> gems; // IDs of gems (videos) created by the user
  final List<String> likedGems; // IDs of gems liked by the user
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    List<String>? gems,
    List<String>? likedGems,
    List<String>? followers,
    List<String>? following,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.gems = gems ?? [],
    this.likedGems = likedGems ?? [],
    this.followers = followers ?? [],
    this.following = following ?? [];

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'gems': gems,
      'likedGems': likedGems,
      'followers': followers,
      'following': following,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      gems: List<String>.from(map['gems'] ?? []),
      likedGems: List<String>.from(map['likedGems'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? gems,
    List<String>? likedGems,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      gems: gems ?? this.gems,
      likedGems: likedGems ?? this.likedGems,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
} 