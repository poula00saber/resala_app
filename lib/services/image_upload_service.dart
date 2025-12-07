// ============================================
// FILE: lib/core/services/image_upload_service.dart
// ============================================

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

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
      // Compress image further if needed
      final compressedFile = await _compressImage(imageFile);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'profile_${volunteerId}_$timestamp.jpg';

      // Upload to Firebase Storage
      final ref = _storage.ref().child('volunteer_profile_images/$filename');

      // Set metadata for optimal storage
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_at': timestamp.toString(),
          'volunteer_id': volunteerId,
          'optimized': 'true',
        },
      );

      await ref.putFile(compressedFile, metadata);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _deleteOldImage(oldImageUrl);
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete old image
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  // Compress image further
  Future<File> _compressImage(File imageFile) async {
    // You could use flutter_image_compress package for better compression
    // For now, return original file
    return imageFile;
  }
}
