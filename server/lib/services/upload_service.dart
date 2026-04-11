import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class UploadService {
  static const _uploadDir = 'public/uploads';
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const _allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

  static Future<String?> saveImage({
    required List<int> bytes,
    required String originalFilename,
  }) async {
    final mimeType = lookupMimeType(originalFilename, headerBytes: bytes);
    if (mimeType == null || !_allowedTypes.contains(mimeType)) {
      throw Exception('Tipe file tidak didukung. Gunakan JPEG, PNG, WebP, atau GIF.');
    }
    if (bytes.length > _maxFileSizeBytes) {
      throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
    }

    // Ensure upload directory exists
    final dir = Directory(_uploadDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Generate unique filename
    final ext = p.extension(originalFilename).isNotEmpty
        ? p.extension(originalFilename)
        : _extForMime(mimeType);
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}$ext';
    final filePath = p.join(_uploadDir, uniqueName);

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Return relative URL path (without 'public/')
    return '/uploads/$uniqueName';
  }

  static String _extForMime(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }

  static String _randomSuffix() {
    final now = DateTime.now().microsecond;
    return now.toRadixString(16);
  }
}
