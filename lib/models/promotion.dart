// models/promotion.dart

class Promotion {
  final int promoId;
  final String promoName;
  final double promoDiscount;
  final String promoStart;
  final String promoEnd;

  Promotion({
    required this.promoId,
    required this.promoName,
    required this.promoDiscount,
    required this.promoStart,
    required this.promoEnd,
  });

  // ✅ [ADD] เพิ่ม Getter สำหรับคำนวณวันที่เหลือ
  int get remainingDays {
    final endDate = DateTime.tryParse(promoEnd);
    if (endDate == null) return 0;

    // ตั้งค่าเวลาของวันปัจจุบันเป็นเที่ยงคืนเพื่อการคำนวณที่แม่นยำ
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final difference = endDate.difference(today).inDays;

    // ถ้าโปรโมชั่นหมดอายุแล้ว ให้คืนค่า 0
    return difference < 0 ? 0 : difference;
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      promoId: json['promo_id'],
      promoName: json['promo_name'],
      promoDiscount: double.parse(json['promo_discount'].toString()),
      promoStart: json['promo_start'],
      promoEnd: json['promo_end'],
    );
  }
}