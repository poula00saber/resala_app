// ============================================
// FILE: lib/core/services/image_upload_service.dart
// ============================================

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce quality to save space
        maxWidth: 800, // Limit width
        maxHeight: 800, // Limit height
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage with optimal compression
  Future<String?> uploadImage({
    required File imageFile,
    required String volunteerId,
    String? oldImageUrl, // For deleting old image
  }) async {
    try {
      print('🚀 Starting image upload for volunteer: $volunteerId');

      // Verify file exists before uploading
      if (!await imageFile.exists()) {
        print('❌ Error: Image file does not exist at path: ${imageFile.path}');
        throw Exception('Image file not found at ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      print('📏 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('📁 File path: ${imageFile.path}');

      // Read file bytes directly to avoid file handle issues
      final bytes = await imageFile.readAsBytes();
      print('📦 Read ${bytes.length} bytes from file');

      // Generate unique filename with safe characters only
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeVolunteerId = volunteerId.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '',
      );
      final filename = 'profile_${safeVolunteerId}_$timestamp.jpg';

      print('📝 Uploading as: $filename');

      // Delete old image FIRST (before uploading new one)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        print('🗑️ Attempting to delete old image...');
        await _deleteOldImage(oldImageUrl);
      }

      // Upload to Firebase Storage using putData instead of putFile
      // putData is more reliable as it doesn't depend on the file system
      final ref = _storage.ref().child('volunteer_profile_images/$filename');
      print('📤 Storage path: volunteer_profile_images/$filename');

      // Set metadata for optimal storage
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_at': timestamp.toString(),
          'volunteer_id': volunteerId,
        },
      );

      print('⏳ Uploading ${(bytes.length / 1024).toStringAsFixed(1)} KB...');
      await ref.putData(bytes, metadata);
      print('✅ File uploaded successfully');

      // Get download URL
      print('🔗 Getting download URL...');
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      print('📋 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Delete old image - handles cases where image doesn't exist
  Future<void> _deleteOldImage(String imageUrl) async {
    if (imageUrl.isEmpty) {
      return; // No image to delete
    }

    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Old image deleted successfully');
    } catch (e) {
      // Silently ignore "no object exists" errors for non-existent images
      if (e.toString().contains('not found') ||
          e.toString().contains('no object exists')) {
        print('⚠️ Old image not found (expected if first upload): $e');
        return; // Don't rethrow - this is expected for first uploads
      }
      // For other errors, still print but don't rethrow
      print('⚠️ Error deleting old image (non-critical): $e');
    }
  }
}
