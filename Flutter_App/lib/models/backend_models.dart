class ChatCartOrder {
  final int id;
  final String orderNo;
  final String currency;
  final double total;
  final String paymentStatus;
  final String orderStatus;
  final String paymentMethod;
  final DateTime? placedAt;

  const ChatCartOrder({required this.id, required this.orderNo, required this.currency, required this.total, required this.paymentStatus, required this.orderStatus, required this.paymentMethod, this.placedAt});

  factory ChatCartOrder.fromJson(Map<String, dynamic> json) => ChatCartOrder(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderNo: json['order_no'] as String? ?? '',
        currency: json['currency'] as String? ?? 'NGN',
        total: double.tryParse('${json['total'] ?? 0}') ?? 0,
        paymentStatus: json['payment_status'] as String? ?? 'unpaid',
        orderStatus: json['order_status'] as String? ?? json['status'] as String? ?? 'pending',
        paymentMethod: json['payment_method'] as String? ?? 'bank_transfer',
        placedAt: DateTime.tryParse((json['placed_at'] ?? json['created_at'] ?? '').toString()),
      );

  String get formattedTotal => currency == 'NGN' ? '₦${total.toStringAsFixed(2)}' : '$currency ${total.toStringAsFixed(2)}';
}

class ChatCartAnnouncement {
  final int id;
  final String title;
  final String body;
  final String placement;
  final DateTime? createdAt;
  const ChatCartAnnouncement({required this.id, required this.title, required this.body, required this.placement, this.createdAt});

  factory ChatCartAnnouncement.fromJson(Map<String, dynamic> json) => ChatCartAnnouncement(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        placement: json['placement'] as String? ?? 'global',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class SupportTicketSummary {
  final int id;
  final String ticketNo;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final DateTime? updatedAt;
  const SupportTicketSummary({required this.id, required this.ticketNo, required this.subject, required this.category, required this.priority, required this.status, this.updatedAt});

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) => SupportTicketSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        ticketNo: json['ticket_no'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        priority: json['priority'] as String? ?? 'normal',
        status: json['status'] as String? ?? 'open',
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );
}

class SellerKycStatus {
  final String status;
  final String? rejectionReason;
  final String? legalName;
  final String? businessName;
  const SellerKycStatus({required this.status, this.rejectionReason, this.legalName, this.businessName});

  factory SellerKycStatus.fromJson(Map<String, dynamic> json) => SellerKycStatus(
        status: json['status'] as String? ?? 'pending',
        rejectionReason: json['rejection_reason'] as String? ?? json['review_notes'] as String?,
        legalName: json['legal_name'] as String?,
        businessName: json['business_name'] as String?,
      );
}
