import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/models/order.dart';
import 'package:rimnongapp/config/api_config.dart';

class CusHistoryScreen extends StatefulWidget {
  final int? cusId;

  const CusHistoryScreen({Key? key, this.cusId}) : super(key: key);

  @override
  State<CusHistoryScreen> createState() => _CusHistoryScreenState();
}

// ✅ [ADD] สร้าง Class สำหรับเก็บสถานะเพื่อความสะอาดของโค้ด
class OrderStatus {
  final String text;
  final Color color;
  final IconData icon;

  OrderStatus(this.text, this.color, this.icon);
}

class _CusHistoryScreenState extends State<CusHistoryScreen> {
  List<Order> historyOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistoryOrders();
  }

  Future<void> fetchHistoryOrders() async {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
     if (widget.cusId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/api/customers/${widget.cusId}/history');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          historyOrders = data.map((json) => Order.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load history orders');
      }
    } catch (e) {
      print('Error fetching history orders: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ [RE-LOGIC] อัปเดตฟังก์ชันแสดงสถานะให้ถูกต้องตาม Workflow ล่าสุด
  OrderStatus _getOrderStatus(Order order) {
    if (order.grabDate != null) {
      return OrderStatus('รายการเสร็จสิ้น', Colors.green[700]!, Icons.check_circle);
    } else if (order.receiveDate != null) {
      return OrderStatus('กรุณาไปรับสินค้า', Colors.blue[700]!, Icons.inventory_2);
    } else if (order.emId != null) {
      return OrderStatus('กำลังดำเนินการ', Colors.teal[700]!, Icons.hourglass_bottom);
    } else {
      return OrderStatus('รอรับรายการ', Colors.grey[700]!, Icons.watch_later);
    }
  }

  void _showOrderDetails(Order order) {
    final orderStatus = _getOrderStatus(order);
    final orderDateTime = DateTime.tryParse(order.orderDate);
    final bool isPreOrder = orderDateTime != null && orderDateTime.isAfter(DateTime.now());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'รายละเอียดคำสั่งซื้อ #${order.orderId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('สถานะ:', orderStatus.text),
                // ✅ [RE-LOGIC] แสดงวันที่จอง/สั่ง
                _buildDetailRow(isPreOrder ? 'วันที่จอง:' : 'วันที่สั่ง:', order.orderDate),
                _buildDetailRow('ราคารวม:', '฿${order.totalPrice.toStringAsFixed(2)}'),
                
                // ✅ [RE-LOGIC] แสดงโปรโมชั่นทั้งหมด
                if (order.promotions.isNotEmpty)
                  _buildDetailRow('โปรโมชั่น:', order.promotions.join(', ')),

                if (order.remarks != null && order.remarks!.isNotEmpty)
                  _buildDetailRow('หมายเหตุ:', order.remarks!),

                const Divider(height: 20, color: Colors.brown),
                const Text(
                  'รายการสินค้า:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
                ),
                ...order.orderDetails.map((detail) => Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '- ${detail.proName} x${detail.amount} (฿${detail.payTotal.toStringAsFixed(2)})',
                    style: const TextStyle(fontFamily: 'Sarabun'),
                  ),
                )),
                const Divider(height: 20, color: Colors.brown),

                // ✅ [RE-LOGIC] แสดง Timeline ของออเดอร์
                if (order.emName != null) _buildDetailRow('พนักงาน:', order.emName!),
                if (order.receiveDate != null) _buildDetailRow('วันที่ทำเสร็จ:', order.receiveDate!),
                if (order.grabDate != null) _buildDetailRow('วันที่รับสินค้า:', order.grabDate!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown,
              ),
              child: const Text('ปิด', style: TextStyle(fontFamily: 'Sarabun')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Sarabun'),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'คำสั่งซื้อของฉัน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : historyOrders.isEmpty
              ? Center( /* ... โค้ดส่วนนี้เหมือนเดิม ... */ )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: historyOrders.length,
                  itemBuilder: (context, index) {
                    final order = historyOrders[index];
                    // ✅ [RE-LOGIC] เรียกใช้ฟังก์ชันสถานะใหม่
                    final status = _getOrderStatus(order);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: ListTile(
                        onTap: () => _showOrderDetails(order),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          status.icon,
                          color: status.color,
                          size: 36,
                        ),
                        title: Text(
                          'คำสั่งซื้อ #${order.orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Sarabun',
                          ),
                        ),
                        subtitle: Text(
                          'รวมทั้งหมด: ฿${order.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'Sarabun',
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              status.text,
                              style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sarabun',
                              ),
                            ),
                            Text(
                              '${order.orderDate.split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontFamily: 'Sarabun',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}