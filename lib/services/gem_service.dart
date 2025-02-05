import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gem_model.dart';
import 'cloudinary_service.dart';

class GemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final String _collection = 'gems';

  // Create new gem
  Future<GemModel> createGem({
    required String userId,
    required String title,
    required String description,
    required String cloudinaryUrl,
    required String cloudinaryPublicId,
    required int bytes,
    List<String>? tags,
  }) async {
    try {
      print('🔍 Creating gem with userId: $userId');
      print('🔍 Cloudinary URL: $cloudinaryUrl');
      
      final docRef = _firestore.collection(_collection).doc();
      
      final gem = GemModel(
        id: docRef.id,
        userId: userId,
        title: title,
        description: description,
        cloudinaryUrl: cloudinaryUrl,
        cloudinaryPublicId: cloudinaryPublicId,
        bytes: bytes,
        tags: tags,
      );

      print('🔍 Gem data before saving: ${gem.toMap()}');
      await docRef.set(gem.toMap());
      print('✨ Gem created successfully with ID: ${gem.id}');
      return gem;
    } catch (e) {
      print('❌ Error creating gem: $e');
      rethrow;
    }
  }

  // Get gem by ID
  Future<GemModel?> getGem(String gemId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(gemId).get();
      if (doc.exists) {
        return GemModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting gem: $e');
      return null;
    }
  }

  // Get user's gems
  Future<List<GemModel>> getUserGems(String userId) async {
    try {
      print('🔍 Fetching gems for userId: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('🔍 Found ${querySnapshot.docs.length} gems in Firestore');
      
      final gems = querySnapshot.docs.map((doc) {
        print('📄 Document ID: ${doc.id}');
        print('📄 Raw Data: ${doc.data()}');
        try {
          final gem = GemModel.fromMap(doc.data());
          print('💎 Successfully parsed gem: ${gem.title}');
          return gem;
        } catch (e) {
          print('❌ Error parsing gem document: $e');
          rethrow;
        }
      }).toList();
      
      print('✨ Successfully loaded ${gems.length} gems');
      return gems;
    } catch (e) {
      print('❌ Error getting user gems: $e');
      rethrow;
    }
  }

  // Update gem
  Future<void> updateGem(String gemId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(gemId).update(data);
    } catch (e) {
      print('❌ Error updating gem: $e');
      rethrow;
    }
  }

  // Delete gem
  Future<void> deleteGem(String gemId) async {
    try {
      final gem = await getGem(gemId);
      if (gem != null) {
        // Delete from Cloudinary first
        final cloudinaryDeleted = await _cloudinaryService.deleteVideo(
          gem.cloudinaryPublicId
        );
        
        if (cloudinaryDeleted) {
          // Then delete from Firestore
          await _firestore.collection(_collection).doc(gemId).delete();
          print('✨ Gem deleted successfully');
        } else {
          throw Exception('Failed to delete video from Cloudinary');
        }
      }
    } catch (e) {
      print('❌ Error deleting gem: $e');
      rethrow;
    }
  }

  // Toggle like on a gem
  Future<void> toggleLike(String gemId, String userId) async {
    try {
      final gemRef = _firestore.collection(_collection).doc(gemId);
      final gem = await gemRef.get();
      
      if (gem.exists) {
        final likes = List<String>.from(gem.data()!['likes'] ?? []);
        
        if (likes.contains(userId)) {
          // Unlike
          likes.remove(userId);
        } else {
          // Like
          likes.add(userId);
        }
        
        await gemRef.update({'likes': likes});
      }
    } catch (e) {
      print('❌ Error toggling gem like: $e');
      rethrow;
    }
  }

  // Get trending gems
  Future<List<GemModel>> getTrendingGems({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => GemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting trending gems: $e');
      return [];
    }
  }

  // Search gems by tags
  Future<List<GemModel>> searchGemsByTags(List<String> tags) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tags', arrayContainsAny: tags)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error searching gems: $e');
      return [];
    }
  }
} 