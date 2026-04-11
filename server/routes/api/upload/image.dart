import 'package:dart_frog/dart_frog.dart';
import 'package:petualang_server/services/upload_service.dart';
import 'package:petualang_server/utils/jwt_helper.dart';

/// POST /api/upload/image — upload gambar dari multipart/form-data
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) return Response(statusCode: 204);

  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  final authHeader = context.request.headers['Authorization'];
  final token = JwtHelper.extractToken(authHeader);
  final payload = token != null ? JwtHelper.verifyToken(token) : null;
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Autentikasi diperlukan'},
    );
  }

  try {
    // Menggunakan formData() bawaan dart_frog untuk menangani multipart secara otomatis
    final formData = await context.request.formData();
    final imageFile = formData.files['image'];
    
    if (imageFile == null) {
      print('DEBUG: No image file found in formData files: ${formData.files.keys}');
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Tidak ada file yang dikirim'},
      );
    }

    print('DEBUG: Found image file: ${imageFile.name}');
    final fileBytes = await imageFile.readAsBytes();
    print('DEBUG: File bytes size: ${fileBytes.length} bytes');

    final imageUrl = await UploadService.saveImage(
      bytes: fileBytes,
      originalFilename: imageFile.name,
    );

    return Response.json(
      body: {'success': true, 'url': imageUrl},
    );
  } catch (e) {
    print('DEBUG: Error processing upload: $e');
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Gagal memproses unggahan: $e'},
    );
  }
}
