import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petualang_server/utils/env_config.dart';

class XenditService {
  static String get _secretKey => EnvConfig.xenditSecretKey;

  static Future<Map<String, dynamic>?> createInvoice({
    required String externalId,
    required double amount,
    required String payerEmail,
    required String description,
  }) async {
    if (_secretKey.isEmpty) {
      print('⚠️ XENDIT_SECRET_KEY is not set in environment variables.');
      return null;
    }

    final url = Uri.parse('https://api.xendit.co/v2/invoices');
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}';

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id': externalId,
          'amount': amount,
          'payer_email': payerEmail,
          'description': description,
          'should_send_email': true,
          'success_redirect_url': 'https://petualang.app/payment/success',
          'failure_redirect_url': 'https://petualang.app/payment/failure',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Xendit Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Xendit Exception: $e');
      return null;
    }
  }
}
