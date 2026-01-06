// lib/services/cloudinary_service.dart
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart'; // ← DIESE ZEILE HINZUFÜGEN!
import 'package:path_provider/path_provider.dart';

/// Service to upload images to Cloudinary.
/// IMPORTANT: create an *unsigned* upload preset in your Cloudinary dashboard
/// and replace the placeholder in the constructor below.
class CloudinaryService {
  // Using unsigned preset created in Cloudinary: 'flutter_profiles'
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dzbzjexd7',
    'flutter_profiles',
    cache: false,
  );

  /// Uploads a profile image for the given [userId].
  /// The image is compressed (JPEG) until <= 500KB (or quality floor reached).
  /// Returns the secure URL returned by Cloudinary on success.
  Future<String> uploadProfileImage(File file, {required String userId}) async {
    try {
      final compressed = await _compressToMax500KB(file);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(compressed.path, publicId: 'profile_$userId'),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      // Cloudinary SDK specific error
      throw Exception('Cloudinary Fehler: ${e.message}');
    } catch (e) {
      // Inspect dynamic response for HTTP status (works without importing dio)
      String message = e.toString();
      int? status;
      try {
        status = (e as dynamic).response?.statusCode as int?;
      } catch (_) {
        status = null;
      }

      if (status == 401) {
        message =
            '401 Unauthorized — Prüfe, ob das Upload Preset "flutter_profiles" als *Unsigned* angelegt ist und ob der Cloud-Name korrekt ist.';
      } else if (status != null) {
        message = 'Upload fehlgeschlagen (HTTP $status): ${e.toString()}';
      }

      throw Exception('Upload Fehler: $message');
    }
  }

  /// Compresses [file] to JPEG until under ~500KB or quality gets low.
  Future<File> _compressToMax500KB(File file) async {
    final int maxBytes = 500 * 1024; // 500KB
    int quality = 90;
    File? lastResult;

    final dir = await getTemporaryDirectory();

    while (quality >= 30) {
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$quality.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) break;

      // FlutterImageCompress may return an XFile or a File depending on platform/version.
      // Normalize result to a plain dart:io File via its path to avoid static type issues
      final resultFile = File((result as dynamic).path);

      lastResult = resultFile;
      final len = await resultFile.length();
      if (len <= maxBytes) return resultFile;
      quality -= 10;
    }

    // Fallback: return last compressed file or original
    return lastResult ?? file;
  }
}
