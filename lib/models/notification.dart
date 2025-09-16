// models/notification.dart

// Enum เพื่อแยกประเภทของการแจ้งเตือน
enum NotificationType {
  newOrder,
  upcomingPreorder,
  promotion,
  expiringStock,
  readyForPickup, // <--- เพิ่มบรรทัดนี้
  unknown,
}

class AppNotification {
  final String title;
  final String subtitle;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType notificationType;
    // ✅ 2. เพิ่ม case สำหรับแปลง String 'ready_for_pickup' เป็น enum
    switch (json['type'] as String) {
      case 'new_order':
        notificationType = NotificationType.newOrder;
        break;
      case 'upcoming_preorder':
        notificationType = NotificationType.upcomingPreorder;
        break;
      case 'promotion':
        notificationType = NotificationType.promotion;
        break;
      case 'expiring_stock':
        notificationType = NotificationType.expiringStock;
        break;
      case 'ready_for_pickup': // <--- เพิ่ม case นี้
        notificationType = NotificationType.readyForPickup;
        break;
      default:
        notificationType = NotificationType.unknown;
    }

    return AppNotification(
      title: json['title'] ?? 'ไม่มีหัวข้อ',
      subtitle: json['subtitle'] ?? '',
      type: notificationType,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}