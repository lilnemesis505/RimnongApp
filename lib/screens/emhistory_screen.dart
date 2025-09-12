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

  Future<void> fetchHistoryOrders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    if (widget.emId == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }

    // ✅ 1. แก้ไข URL ให้ชี้ไปที่ API ใหม่ของ Laravel
    final url = Uri.parse('http://10.0.2.2:8000/api/employees/${widget.emId}/history');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          historyOrders = data.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load history orders');
      }
    } catch (e) {
      print('Error fetching history orders: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showOrderDetails(Order order) {
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
                _buildDetailRow('ลูกค้า:', order.customerName ?? 'N/A'),
                _buildDetailRow('วันที่สั่ง:', order.orderDate),
                _buildDetailRow('ราคารวม:', '฿${order.totalPrice.toStringAsFixed(2)}'),
                if (order.promoCode != null) _buildDetailRow('โค้ดโปรโมชัน:', order.promoCode!),
                if (order.remarks != null && order.remarks!.isNotEmpty) _buildDetailRow('หมายเหตุ:', order.remarks!),
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
                 _buildDetailRow('วันที่รับออเดอร์:', order.receiveDate ?? 'N/A'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Sarabun'),
          ),
          const SizedBox(width: 8),
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
    // ✅ 2. ปรับปรุง UI ทั้งหมด
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ประวัติการทำรายการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.teal[700], // สีสำหรับพนักงาน
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : historyOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีประวัติการทำรายการ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontFamily: 'Sarabun',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: historyOrders.length,
                  itemBuilder: (context, index) {
                    final order = historyOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: ListTile(
                        onTap: () => _showOrderDetails(order),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
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
                          'ลูกค้า: ${order.customerName ?? "N/A"}',
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
                              '฿${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sarabun',
                                color: Colors.teal
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