import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) => value is Timestamp ? value.toDate() : null;

class ChatUser {
  final String id;
  final String displayName;
  final String phone;
  final String? photoUrl;
  final DateTime? lastSeen;

  const ChatUser({required this.id, required this.displayName, this.phone = '', this.photoUrl, this.lastSeen});

  factory ChatUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatUser(
      id: doc.id,
      displayName: (d['displayName'] as String?)?.trim().isNotEmpty == true ? d['displayName'] as String : 'ChatCart User',
      phone: d['phone'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      lastSeen: _date(d['lastSeen']),
    );
  }
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageType;
  final String? lastSenderId;
  final DateTime? updatedAt;

  const ChatConversation({required this.id, required this.participants, required this.lastMessage, required this.lastMessageType, this.lastSenderId, this.updatedAt});

  factory ChatConversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? const []),
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageType: d['lastMessageType'] as String? ?? 'text',
      lastSenderId: d['lastSenderId'] as String?,
      updatedAt: _date(d['updatedAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String type;
  final String text;
  final String? mediaUrl;
  final String? productId;
  final DateTime? createdAt;
  final List<String> readBy;

  const ChatMessage({required this.id, required this.senderId, required this.type, required this.text, this.mediaUrl, this.productId, this.createdAt, this.readBy = const []});

  bool readByUser(String uid) => readBy.contains(uid);

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      type: d['type'] as String? ?? 'text',
      text: d['text'] as String? ?? '',
      mediaUrl: d['mediaUrl'] as String?,
      productId: d['productId'] as String?,
      createdAt: _date(d['createdAt']),
      readBy: List<String>.from(d['readBy'] ?? const []),
    );
  }
}

class MarketplaceProduct {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final int price;
  final int? compareAtPrice;
  final String currency;
  final List<String> imageUrls;
  final String category;
  final double rating;
  final bool active;

  const MarketplaceProduct({required this.id, required this.sellerId, required this.title, required this.description, required this.price, this.compareAtPrice, this.currency = 'NGN', this.imageUrls = const [], this.category = 'Other', this.rating = 0, this.active = true});

  String get formattedPrice => currency == 'NGN' ? '₦${_comma(price)}' : '$currency ${_comma(price)}';


  factory MarketplaceProduct.fromJson(Map<String, dynamic> d) {
    return MarketplaceProduct(
      id: d['id']?.toString() ?? '',
      sellerId: d['sellerId']?.toString() ?? d['seller_id']?.toString() ?? '',
      title: d['title'] as String? ?? 'Untitled product',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.round() ?? int.tryParse(d['price']?.toString() ?? '') ?? 0,
      compareAtPrice: (d['compareAtPrice'] as num?)?.round(),
      currency: d['currency'] as String? ?? 'NGN',
      imageUrls: List<String>.from(d['imageUrls'] ?? d['image_urls'] ?? const []),
      category: d['category']?.toString() ?? 'Other',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      active: d['active'] as bool? ?? d['status'] == 'active',
    );
  }

  factory MarketplaceProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MarketplaceProduct(
      id: doc.id,
      sellerId: d['sellerId'] as String? ?? '',
      title: d['title'] as String? ?? 'Untitled product',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.round() ?? 0,
      compareAtPrice: (d['compareAtPrice'] as num?)?.round(),
      currency: d['currency'] as String? ?? 'NGN',
      imageUrls: List<String>.from(d['imageUrls'] ?? const []),
      category: d['category'] as String? ?? 'Other',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      active: d['active'] as bool? ?? true,
    );
  }
}

String _comma(int value) {
  final s = value.toString();
  return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
