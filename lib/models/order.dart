// models/order.dart

import 'dart:convert';
import 'order_detail.dart';

// Class สำหรับเก็บข้อมูลคำสั่งซื้อหลัก
//... import และ class OrderDetail ...

class Order {
  final int orderId;
  final int? cusId;
  final String customerName;
  final String orderDate;
  final String? receiveDate;
  final int? emId;
  final String? emName; // ✅ [ADD] เพิ่มชื่อพนักงาน
  final double totalPrice;
  final List<String> promotions; // ✅ [CHANGE] เปลี่ยนจาก promoCode เป็น List<String>
  final String? remarks;
  final String? slipUrl; 
  final List<OrderDetail> orderDetails;
  final String? grabDate;

  Order({
    required this.orderId,
    this.cusId,
    required this.customerName,
    required this.orderDate,
    required this.totalPrice,
    this.receiveDate,
    this.emId,
    this.emName, // ✅ [ADD]
    required this.promotions, // ✅ [CHANGE]
    this.remarks,
    this.slipUrl,
    required this.orderDetails,
    this.grabDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var detailsList = json['details'] as List? ?? [];
    List<OrderDetail> details = detailsList.map((i) => OrderDetail.fromJson(i)).toList();

    final customerData = json['customer'];
    final customerName = customerData?['fullname'] ?? 'ลูกค้าไม่ระบุชื่อ';

    // ✅ [RE-LOGIC] ดึงโปรโมชั่นทั้งหมด
    var promoList = json['promotions'] as List? ?? [];
    List<String> promoNames = promoList.map((p) => p['promo_name'] as String).toList();

    final employeeData = json['employee'];
    final employeeName = employeeData?['em_name'];

    return Order(
      orderId: int.parse(json['order_id'].toString()),
      cusId: json['cus_id'] != null ? int.parse(json['cus_id'].toString()) : null,
      customerName: customerName,
      orderDate: json['order_date'],
      emId: json['em_id'] != null ? int.parse(json['em_id'].toString()) : null,
      emName: employeeName, // ✅ [ADD]
      totalPrice: double.parse(json['price_total'].toString()),
      receiveDate: json['receive_date'],
      promotions: promoNames, // ✅ [CHANGE]
      remarks: json['remarks'],
      slipUrl: json['slips_url'],
      orderDetails: details,
      grabDate: json['grab_date'],
    );
  }
}