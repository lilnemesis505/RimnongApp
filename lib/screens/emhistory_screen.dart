import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/models/order.dart';
import 'package:rimnongapp/config/api_config.dart';

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
    if (widget.emId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/api/employees/${widget.emId}/history');
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

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('รายละเอียดคำสั่งซื้อ #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('ลูกค้า:', order.customerName),
                _buildDetailRow('วันที่สั่ง:', order.orderDate),
                if (order.remarks != null && order.remarks!.isNotEmpty) _buildDetailRow('หมายเหตุ:', order.remarks!),
                const Divider(height: 20, color: Colors.brown),
                const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
                ...order.orderDetails.map((detail) => Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('- ${detail.proName} x${detail.amount}', style: const TextStyle(fontFamily: 'Sarabun')),
                    )),
                 const Divider(height: 20, color: Colors.brown),
                _buildDetailRow('วันที่ทำเสร็จ:', order.receiveDate ?? 'N/A'),
              ],
            ),
          ),
          actions: <Widget>[
            if (order.slipUrl != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.teal[700]),
                child: const Text('ดูสลิป', style: TextStyle(fontFamily: 'Sarabun', fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSlipDialog(order.slipUrl!);
                },
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.brown),
              child: const Text('ปิด', style: TextStyle(fontFamily: 'Sarabun')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showSlipDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("รูปภาพสลิป", style: TextStyle(fontFamily: 'Sarabun', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.teal)),
                errorBuilder: (context, error, stack) => const Icon(Icons.error, color: Colors.red, size: 50),
              ),
            ),
          ],
        ),
        actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ปิด', style: TextStyle(fontFamily: 'Sarabun', color: Colors.teal)))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Sarabun')),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ประวัติการทำรายการ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
        backgroundColor: Colors.teal[700],
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
                      Text('ไม่มีประวัติการทำรายการ', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Sarabun')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: historyOrders.length,
                  itemBuilder: (context, index) {
                    return _HistoryCard(
                      order: historyOrders[index],
                      onTap: () => _showOrderDetails(historyOrders[index]),
                    );
                  },
                ),
    );
  }
}

// --- Reusable Widget for History Card ---

class _HistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _HistoryCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(Icons.check_circle, color: Colors.green[700], size: 36),
        title: Text('คำสั่งซื้อ #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sarabun')),
        subtitle: Text('ลูกค้า: ${order.customerName}', style: TextStyle(color: Colors.grey[600], fontFamily: 'Sarabun')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('฿${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun', color: Colors.teal)),
            const SizedBox(height: 4),
            Text(order.orderDate.split(' ')[0], style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Sarabun')),
          ],
        ),
      ),
    );
  }
}