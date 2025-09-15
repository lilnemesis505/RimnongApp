// models/notification.dart

// Enum เพื่อแยกประเภทของการแจ้งเตือน
enum NotificationType { newOrder, upcomingPreorder, promotion, expiringStock, unknown }

class AppNotification {
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  AppNotification({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'new_order':
        type = NotificationType.newOrder;
        break;
      case 'upcoming_preorder':
        type = NotificationType.upcomingPreorder;
        break;
      case 'promotion':
        type = NotificationType.promotion;
        break;
        case 'expiring_stock': // ✅ [ADD] เพิ่ม case สำหรับ expiring_stock
        type = NotificationType.expiringStock;
        break;
      default:
        type = NotificationType.unknown;
    }

    return AppNotification(
      type: type,
      title: json['title'] ?? 'N/A',
      subtitle: json['subtitle'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}