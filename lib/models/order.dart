import 'dart:convert';

// Class สำหรับเก็บข้อมูลสินค้าใน Order Detail
class OrderDetail {
  final int proId;
  final String proName;
  final int amount;
  final double priceList;
  final double payTotal;

  OrderDetail({
    required this.proId,
    required this.proName,
    required this.amount,
    required this.priceList,
    required this.payTotal,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // ดึงข้อมูล product ที่ซ้อนอยู่ข้างใน
    final productData = json['product'];

    return OrderDetail(
      proId: int.parse(json['pro_id'].toString()),
      proName: productData != null ? productData['pro_name'] : 'ไม่พบชื่อสินค้า',
      amount: int.parse(json['amount'].toString()),
      priceList: double.parse(json['price_list'].toString()),
      payTotal: double.parse(json['pay_total'].toString()),
    );
  }
}

// Class สำหรับเก็บข้อมูลคำสั่งซื้อหลัก
class Order {
  final int orderId;
  final int? cusId;
  final String customerName;
  final String orderDate;
  final String? receiveDate;
  final int? emId;
  final double totalPrice;
  final String? promoCode;
  final String? remarks;
  final String? slipUrl; // เปลี่ยนจาก slipPath เป็น slipUrl
  final List<OrderDetail> orderDetails;

  Order({
    required this.orderId,
    this.cusId,
    required this.customerName,
    required this.orderDate,
    required this.totalPrice,
    this.receiveDate,
    this.emId,
    this.promoCode,
    this.remarks,
    this.slipUrl,
    required this.orderDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // แปลง list ของ details ที่อยู่ใน json
    var detailsList = json['details'] as List? ?? [];
    List<OrderDetail> details = detailsList.map((i) => OrderDetail.fromJson(i)).toList();

    // ดึงข้อมูลจาก object 'customer' ที่ซ้อนอยู่
    final customerData = json['customer'];
    final customerName = (customerData != null && customerData['fullname'] != null)
        ? customerData['fullname'] as String
        : 'ลูกค้าไม่ระบุชื่อ';
    
    // ดึงข้อมูลจาก object 'promotion' ที่ซ้อนอยู่
    final promoData = json['promotion'];
    final promoName = (promoData != null && promoData['promo_name'] != null)
        ? promoData['promo_name'] as String
        : null;

    return Order(
      orderId: int.parse(json['order_id'].toString()),
      cusId: json['cus_id'] != null ? int.parse(json['cus_id'].toString()) : null,
      customerName: customerName,
      orderDate: json['order_date'],
      emId: json['em_id'] != null ? int.parse(json['em_id'].toString()) : null,
      totalPrice: double.parse(json['price_total'].toString()),
      receiveDate: json['receive_date'],
      promoCode: promoName,
      remarks: json['remarks'],
      slipUrl: json['slips_url'], // รับค่า slips_url จาก API
      orderDetails: details,
    );
  }
}