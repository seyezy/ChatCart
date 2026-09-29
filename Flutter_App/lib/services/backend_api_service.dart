import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/backend_models.dart';

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;
  const BackendApiException(this.message, [this.statusCode]);
  @override String toString() => message;
}

class BackendApiService {
  final FirebaseAuth auth;
  final http.Client client;
  String get baseUrl => AppConfig.apiBaseUrl;

  BackendApiService({FirebaseAuth? auth, http.Client? client})
      : auth = auth ?? FirebaseAuth.instance,
        client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    if (baseUrl.isEmpty) throw const BackendApiException('API_BASE_URL is not configured in the active flavor .env file.');
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$root/$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _request(String path, {String method = 'POST', Map<String, dynamic>? body, Map<String, String>? query}) async {
    final user = auth.currentUser;
    if (user == null) throw const BackendApiException('Sign in is required.', 401);
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw const BackendApiException('Could not obtain an authentication token.', 401);
    final headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'};
    late http.Response response;
    if (method == 'GET') {
      response = await client.get(_uri(path, query), headers: headers);
    } else {
      response = await client.post(_uri(path, query), headers: headers, body: jsonEncode(body ?? const {}));
    }
    Map<String, dynamic> data;
    try { data = jsonDecode(response.body) as Map<String, dynamic>; } catch (_) { throw BackendApiException('The ChatCart server returned an invalid response.', response.statusCode); }
    if (response.statusCode < 200 || response.statusCode >= 300 || data['ok'] != true) {
      throw BackendApiException(data['message'] as String? ?? 'Request failed.', response.statusCode);
    }
    return data;
  }

  Future<void> reportUser({required String reportedUid, required String category, String reason = ''}) => _request('reports/users', body: {'reported_uid': reportedUid, 'category': category, 'reason': reason}).then((_) {});
  Future<void> reportMessage({required String conversationId, required String messageId, required String category, String reason = ''}) => _request('reports/messages', body: {'conversation_id': conversationId, 'message_id': messageId, 'category': category, 'reason': reason}).then((_) {});

  Future<SellerKycStatus?> kycStatus() async {
    final data = await _request('seller/kyc', method: 'GET');
    final raw = data['kyc'];
    return raw is Map<String, dynamic> ? SellerKycStatus.fromJson(raw) : null;
  }

  Future<void> submitKyc({required String legalName, required String businessName, required String country, required String documentType, required String documentNumber, required List<String> documentUrls, required String selfieUrl}) => _request('seller/kyc', body: {
        'legal_name': legalName, 'business_name': businessName, 'country': country, 'document_type': documentType, 'document_number': documentNumber, 'document_urls': documentUrls, 'selfie_url': selfieUrl,
      }).then((_) {});

  Future<ChatCartOrder> createOrder({required String productId, required int quantity, required Map<String, String> deliveryAddress, required String paymentMethod}) async {
    final data = await _request('orders', body: {'product_id': productId, 'quantity': quantity, 'delivery_address': deliveryAddress, 'payment_method': paymentMethod});
    return ChatCartOrder.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<List<ChatCartOrder>> myOrders() async {
    final data = await _request('orders', method: 'GET');
    return ((data['orders'] as List?) ?? const []).map((e) => ChatCartOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<SupportTicketSummary> createSupportTicket({required String subject, required String message, String category = 'general', String priority = 'normal'}) async {
    final data = await _request('support/tickets', body: {'subject': subject, 'message': message, 'category': category, 'priority': priority});
    final raw = Map<String, dynamic>.from(data['ticket'] as Map);
    return SupportTicketSummary(id: (raw['id'] as num?)?.toInt() ?? 0, ticketNo: raw['ticket_no'] as String? ?? '', subject: subject, category: category, priority: priority, status: raw['status'] as String? ?? 'open');
  }

  Future<List<SupportTicketSummary>> myTickets() async {
    final data = await _request('support/tickets', method: 'GET');
    return ((data['tickets'] as List?) ?? const []).map((e) => SupportTicketSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ChatCartAnnouncement>> announcements({String placement = 'global'}) async {
    final data = await _request('announcements', method: 'GET', query: {'placement': placement});
    return ((data['announcements'] as List?) ?? const []).map((e) => ChatCartAnnouncement.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }


  Future<void> registerDevice({required String deviceId, required String platform, String? fcmToken}) =>
      _request('devices', body: {'device_id': deviceId, 'platform': platform, 'fcm_token': fcmToken}).then((_) {});

  Future<List<Map<String, dynamic>>> devices() async {
    final data = await _request('devices', method: 'GET');
    return ((data['devices'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> revokeDevice(String deviceId) => _request('devices/$deviceId/revoke', body: const {}).then((_) {});
}
