import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/models/order.dart';

class EmHistoryScreen extends StatefulWidget {
  final int? emId;

  const EmHistoryScreen({Key? key, this.emId}) : super(key: key);

  @override
  State<EmHistoryScreen> createState() => _EmHistoryScreenState();
}

class _EmHistoryScreenState extends State<EmHistoryScreen> {
  List<Order> historyOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistoryOrders();
  }

  // ดึงประวัติคำสั่งซื้อที่เสร็จสิ้นแล้วจาก API
  Future<void> fetchHistoryOrders() async {
    setState(() {
      isLoading = true;
    });

    if (widget.emId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2/api/fetch_history_orders.php?em_id=${widget.emId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          historyOrders = data.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load history orders');
      }
    } catch (e) {
      print('Error fetching history orders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับแสดงรายละเอียดคำสั่งซื้อใน Dialog
  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('รายละเอียดคำสั่งซื้อ #${order.orderId}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('ลูกค้า: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('วันที่สั่ง: ${order.orderDate}'),
                Text('ราคารวม: ฿${order.totalPrice.toStringAsFixed(2)}'),
                if (order.promoCode != null) Text('โค้ดโปรโมชัน: ${order.promoCode}'),
                if (order.remarks != null && order.remarks!.isNotEmpty) Text('หมายเหตุ: ${order.remarks}'),
                const Divider(),
                const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                // เพิ่มส่วนแสดงรายการสินค้า
                ...order.orderDetails.map((detail) => Text('- ${detail.proName} x${detail.amount} (฿${detail.payTotal.toStringAsFixed(2)})')),
                const Divider(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการทำรายการ'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyOrders.isEmpty
              ? const Center(child: Text('ไม่มีประวัติการทำรายการ'))
              : ListView.builder(
                  itemCount: historyOrders.length,
                  itemBuilder: (context, index) {
                    final order = historyOrders[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () => _showOrderDetails(order),
                        ),
                        title: Text('คำสั่งซื้อ #${order.orderId}'),
                        subtitle: Text('ลูกค้า: ${order.customerName} | รวมทั้งหมด: ฿${order.totalPrice.toStringAsFixed(2)}'),
                        trailing: const Text('เสร็จสิ้นแล้ว', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}
