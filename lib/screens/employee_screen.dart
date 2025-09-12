import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/models/order.dart';
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:rimnongapp/screens/emhistory_screen.dart';

// --- Main Screen Widget ---

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
  String _emEmail = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emId = ModalRoute.of(context)?.settings.arguments as int?;
      if (_emId != null) {
        _fetchEmployeeData(_emId!);
        fetchPendingOrders(); // Fetch initially
        _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          fetchPendingOrders(); // Refresh every 10 seconds
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Data Fetching & Logic Methods ---

  Future<void> _fetchEmployeeData(int emId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/employees/$emId');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
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
    final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/pending');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pendingOrders = data.map((json) => Order.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching pending orders: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String action) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/update-status');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'order_id': orderId, 'action': action, 'em_id': _emId}),
      );
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'accept' ? 'รับออเดอร์สำเร็จ' : 'ทำรายการเสร็จสิ้น'),
              backgroundColor: Colors.green,
            ),
          );
          fetchPendingOrders();
        }
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // --- UI Helper Methods (Dialogs) ---

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
    showDialog(context: context, builder: (context) => AlertDialog(
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
        ));
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

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final newOrders = pendingOrders.where((o) => o.emId == null).toList();
    final myOrders = pendingOrders.where((o) => o.emId == _emId).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _EmployeeDrawer(emName: _emName, emEmail: _emEmail, emId: _emId),
      appBar: AppBar(
        title: const Text('รายการออเดอร์', style: TextStyle(color: Colors.white, fontFamily: 'Sarabun')),
        backgroundColor: Colors.teal[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: fetchPendingOrders,
              child: (newOrders.isEmpty && myOrders.isEmpty)
                  ? const Center(child: Text('ไม่มีรายการที่กำลังรอ...', style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        _OrderSection(
                          title: 'ออเดอร์ใหม่',
                          orders: newOrders,
                          onActionPressed: (orderId) => _updateOrderStatus(orderId, 'accept'),
                          onDetailsPressed: _showOrderDetails,
                        ),
                        const SizedBox(height: 16),
                        _OrderSection(
                          title: 'ออเดอร์ของฉัน',
                          orders: myOrders,
                          onActionPressed: (orderId) => _updateOrderStatus(orderId, 'complete'),
                          onDetailsPressed: _showOrderDetails,
                        ),
                      ],
                    ),
            ),
    );
  }
}

// --- Reusable Widget for the Drawer ---

class _EmployeeDrawer extends StatelessWidget {
  const _EmployeeDrawer({required this.emName, required this.emEmail, this.emId});

  final String emName;
  final String emEmail;
  final int? emId;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(emName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
            accountEmail: Text(emEmail, style: const TextStyle(fontFamily: 'Sarabun')),
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmHistoryScreen(emId: emId)));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.teal[700]),
            title: const Text('ออกจากระบบ', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Widget for an Order Section ---

class _OrderSection extends StatelessWidget {
  final String title;
  final List<Order> orders;
  final Function(int) onActionPressed;
  final Function(Order) onDetailsPressed;
  
  const _OrderSection({
    required this.title,
    required this.orders,
    required this.onActionPressed,
    required this.onDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String action = title == 'ออเดอร์ใหม่' ? 'accept' : 'complete';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('$title (${orders.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800])),
        ),
        if (orders.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 16), child: Text('ไม่มีรายการ', style: TextStyle(color: Colors.grey)))
        else
          ...orders.map((order) => _OrderCard(
            order: order,
            action: action,
            onActionPressed: () => onActionPressed(order.orderId),
            onDetailsPressed: () => onDetailsPressed(order),
          )).toList(),
      ],
    );
  }
}

// --- Reusable Widget for an Order Card ---

class _OrderCard extends StatelessWidget {
  final Order order;
  final String action;
  final VoidCallback onActionPressed;
  final VoidCallback onDetailsPressed;

  const _OrderCard({
    required this.order,
    required this.action,
    required this.onActionPressed,
    required this.onDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('คำสั่งซื้อ #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('฿${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 4),
            Text('ลูกค้า: ${order.customerName}', style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            ...order.orderDetails.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('- ${detail.proName} x${detail.amount}'),
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('ดูรายละเอียด'),
                  onPressed: onDetailsPressed,
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(action == 'accept' ? Icons.check_circle_outline : Icons.done_all, size: 20),
                  label: Text(action == 'accept' ? 'รับออเดอร์' : 'ทำเสร็จแล้ว'),
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'accept' ? Colors.amber[700] : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}