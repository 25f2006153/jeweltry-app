import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApiService {
  final String baseUrl;
  final String authToken;

  BackendApiService({
    required this.baseUrl,
    required this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<Map<String, dynamic>?> fetchCredits() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/credits'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> fetchPlans() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/plans'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> fetchSubscription() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/subscription'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchHistory({int page = 1, int limit = 20}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/history?page=$page&limit=$limit'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteHistoryItem(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/history/$id'), headers: _headers);
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> verifyGooglePlayPurchase({
    required String planId,
    required String purchaseToken,
    required String orderId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/payments/verify-google-play'),
        headers: _headers,
        body: jsonEncode({
          'plan_id': planId,
          'purchase_token': purchaseToken,
          'order_id': orderId,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
