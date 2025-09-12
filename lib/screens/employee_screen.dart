import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/models/order.dart';
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:rimnongapp/screens/emhistory_screen.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<Order> pendingOrders = [];
  bool isLoading = true;
  int? _emId;
  String _emName = 'พนักงาน';
  String _emEmail = 'employee@example.com';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emId = ModalRoute.of(context)?.settings.arguments as int?;
      if (_emId != null) {
        _fetchEmployeeData(_emId!);
        fetchPendingOrders(); // Fetch initially
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
          fetchPendingOrders(); // Refresh every 5 seconds
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEmployeeData(int emId) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/employees/$emId');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          setState(() {
            _emName = data['em_name'];
            _emEmail = data['em_email'];
          });
        }
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    }
  }

  Future<void> fetchPendingOrders() async {
    final url = Uri.parse('http://10.0.2.2:8000/api/orders/pending');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          pendingOrders = data.map((json) => Order.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching pending orders: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String action) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/orders/update-status');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'order_id': orderId,
          'action': action,
          'em_id': _emId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'accept' ? 'รับออเดอร์สำเร็จ' : 'ทำรายการเสร็จสิ้น'),
              backgroundColor: Colors.green,
            ),
          );
          fetchPendingOrders(); // Refresh the list
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      print('Error updating order status: $e');
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
              ],
            ),
          ),
          actions: <Widget>[
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
    // แยกรายการที่ยังไม่รับ กับรายการที่เรารับแล้ว
    final newOrders = pendingOrders.where((o) => o.emId == null).toList();
    final myOrders = pendingOrders.where((o) => o.emId == _emId).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text(
          'รายการออเดอร์',
          style: TextStyle(color: Colors.white, fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.teal[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: fetchPendingOrders,
              child: pendingOrders.isEmpty
                  ? const Center(child: Text('ไม่มีรายการที่กำลังรอ...'))
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        _buildOrderSection('ออเดอร์ใหม่', newOrders, 'accept'),
                        _buildOrderSection('ออเดอร์ของฉัน', myOrders, 'complete'),
                      ],
                    ),
            ),
    );
  }
  
  Widget _buildOrderSection(String title, List<Order> orders, String action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text(
            '$title (${orders.length})',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
        ),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('ไม่มีรายการ'),
          )
        else
          ...orders.map((order) => _buildOrderCard(order, action)).toList(),
      ],
    );
  }

  Widget _buildOrderCard(Order order, String action) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'คำสั่งซื้อ #${order.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '฿${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                ),
              ],
            ),
            Text('ลูกค้า: ${order.customerName ?? "N/A"}'),
            const Divider(height: 20),
            ...order.orderDetails.map((detail) => Text('- ${detail.proName} x${detail.amount}')),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('ดูรายละเอียด'),
                  onPressed: () => _showOrderDetails(order),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(action == 'accept' ? Icons.check : Icons.done_all),
                  label: Text(action == 'accept' ? 'รับออเดอร์' : 'ทำเสร็จแล้ว'),
                  onPressed: () => _updateOrderStatus(order.orderId, action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'accept' ? Colors.amber[700] : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_emName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
            accountEmail: Text(_emEmail, style: const TextStyle(fontFamily: 'Sarabun')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.person, size: 40, color: Colors.teal[800]),
            ),
            decoration: BoxDecoration(color: Colors.teal[400]),
          ),
          ListTile(
            leading: Icon(Icons.list_alt, color: Colors.teal[700]),
            title: const Text('รายการออเดอร์', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.teal[700]),
            title: const Text('ประวัติการทำรายการ', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EmHistoryScreen(emId: _emId)),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.teal[700]),
            title: const Text('ออกจากระบบ', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}