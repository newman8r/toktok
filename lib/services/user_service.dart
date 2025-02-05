import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Create new user
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(uid).update(data);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Add gem to user's gems list
  Future<void> addGem(String uid, String gemId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'gems': FieldValue.arrayUnion([gemId])
      });
    } catch (e) {
      print('Error adding gem: $e');
      rethrow;
    }
  }

  // Remove gem from user's gems list
  Future<void> removeGem(String uid, String gemId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'gems': FieldValue.arrayRemove([gemId])
      });
    } catch (e) {
      print('Error removing gem: $e');
      rethrow;
    }
  }

  // Toggle like on a gem
  Future<void> toggleLikeGem(String uid, String gemId) async {
    try {
      final user = await getUser(uid);
      if (user != null) {
        if (user.likedGems.contains(gemId)) {
          await _firestore.collection(_collection).doc(uid).update({
            'likedGems': FieldValue.arrayRemove([gemId])
          });
        } else {
          await _firestore.collection(_collection).doc(uid).update({
            'likedGems': FieldValue.arrayUnion([gemId])
          });
        }
      }
    } catch (e) {
      print('Error toggling gem like: $e');
      rethrow;
    }
  }

  // Toggle follow user
  Future<void> toggleFollowUser(String currentUserId, String targetUserId) async {
    try {
      final currentUser = await getUser(currentUserId);
      if (currentUser != null) {
        if (currentUser.following.contains(targetUserId)) {
          // Unfollow
          await _firestore.collection(_collection).doc(currentUserId).update({
            'following': FieldValue.arrayRemove([targetUserId])
          });
          await _firestore.collection(_collection).doc(targetUserId).update({
            'followers': FieldValue.arrayRemove([currentUserId])
          });
        } else {
          // Follow
          await _firestore.collection(_collection).doc(currentUserId).update({
            'following': FieldValue.arrayUnion([targetUserId])
          });
          await _firestore.collection(_collection).doc(targetUserId).update({
            'followers': FieldValue.arrayUnion([currentUserId])
          });
        }
      }
    } catch (e) {
      print('Error toggling follow: $e');
      rethrow;
    }
  }

  // Get user's followers
  Future<List<UserModel>> getFollowers(String uid) async {
    try {
      final user = await getUser(uid);
      if (user != null) {
        final followers = await Future.wait(
          user.followers.map((followerId) => getUser(followerId))
        );
        return followers.whereType<UserModel>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get user's following
  Future<List<UserModel>> getFollowing(String uid) async {
    try {
      final user = await getUser(uid);
      if (user != null) {
        final following = await Future.wait(
          user.following.map((followingId) => getUser(followingId))
        );
        return following.whereType<UserModel>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }
} 