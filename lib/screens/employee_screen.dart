import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/models/order.dart';
import 'package:rimnongapp/models/notification.dart'; // ✅ [ADD] Import a promotion model
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:rimnongapp/screens/emhistory_screen.dart';

// ... Main Screen Widget ...
class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<Order> pendingOrders = [];
  List<AppNotification> _notifications = [];
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
        fetchPendingOrders();
        _fetchNotifications(); // ✅ [ADD] Fetch promotions on init
        _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          fetchPendingOrders();
        });
      }
    });
  }

  // ... dispose() ...
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Data Fetching & Logic Methods ---

  // ... _fetchEmployeeData() ...
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

  // ... fetchPendingOrders() ...
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

  // ✅ [ADD] New function to fetch active promotions
   Future<void> _fetchNotifications() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }
  // ... _updateOrderStatus() ...
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
              content: Text(data['message'] ?? 'อัปเดตสถานะสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          fetchPendingOrders();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // --- UI Helper Methods (Dialogs) ---

  // ... _showOrderDetails() ...
  void _showOrderDetails(Order order) {
    // ✅ [ADD] ตรรกะสำหรับเช็คว่าเป็น Pre-order หรือไม่
    final orderDateTime = DateTime.tryParse(order.orderDate);
    final bool isPreOrder = orderDateTime != null && orderDateTime.isAfter(DateTime.now());

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
                // ✅ [RE-LOGIC] เปลี่ยนข้อความตามเงื่อนไข Pre-order
                _buildDetailRow(isPreOrder ? 'วันที่จอง:' : 'วันที่สั่ง:', order.orderDate),
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

  // ✅ [ADD] New dialog to show promotions
 void _showNotificationsDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('การแจ้งเตือน', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
            content: SizedBox(
              width: double.maxFinite,
              child: _notifications.isEmpty
                  ? const Text('ไม่มีการแจ้งเตือนใหม่', style: TextStyle(fontFamily: 'Sarabun'))
                  : ListView.builder( // ใช้ ListView.separated เพื่อเพิ่มเส้นคั่น
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationTile(notification); // เรียกใช้ Widget แยก
                      },
                    ),
            ),
             actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด', style: TextStyle(fontFamily: 'Sarabun', color: Colors.teal)),
              )
            ],
          );
        });
  }

  // ✅ [ADD] สร้าง Widget แยกสำหรับแสดงผลแต่ละประเภทการแจ้งเตือน
  Widget _buildNotificationTile(AppNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.newOrder:
        icon = Icons.fiber_new_rounded;
        color = Colors.amber.shade700;
        break;
      case NotificationType.upcomingPreorder:
        icon = Icons.timer_outlined;
        color = Colors.blue.shade700;
        break;
      case NotificationType.promotion:
        icon = Icons.campaign_rounded;
        color = Colors.green.shade600;
        break;
      case NotificationType.expiringStock: 
      icon = Icons.warning_amber_rounded;
      color = Colors.orange.shade800;
      break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
      subtitle: Text(notification.subtitle, style: const TextStyle(fontFamily: 'Sarabun')),
      dense: true,
    );
  }

  // ... _showSlipDialog() ...
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
  // ... _buildDetailRow() ...
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
    final myMakingOrders = pendingOrders.where((o) => o.emId == _emId && o.receiveDate == null).toList();
    final myAwaitingPickupOrders = pendingOrders.where((o) => o.emId == _emId && o.receiveDate != null && o.grabDate == null).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _EmployeeDrawer(emName: _emName, emEmail: _emEmail, emId: _emId),
      appBar: AppBar(
        title: const Text('รายการออเดอร์', style: TextStyle(color: Colors.white, fontFamily: 'Sarabun')),
        backgroundColor: Colors.teal[700],
        iconTheme: const IconThemeData(color: Colors.white),
        // ✅ [ADD] Add notification bell icon here
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            onPressed: _showNotificationsDialog,
            tooltip: 'การแจ้งเตือน',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: fetchPendingOrders,
              child: (newOrders.isEmpty && myMakingOrders.isEmpty && myAwaitingPickupOrders.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('ไม่มีรายการที่กำลังรอ...', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        _OrderSection(
                          title: 'ออเดอร์ใหม่',
                          orders: newOrders,
                          action: 'accept',
                          onActionPressed: (orderId) => _updateOrderStatus(orderId, 'accept'),
                          onDetailsPressed: _showOrderDetails,
                        ),
                        const SizedBox(height: 16),
                        _OrderSection(
                          title: 'กำลังดำเนินการ',
                          orders: myMakingOrders,
                          action: 'complete',
                          onActionPressed: (orderId) => _updateOrderStatus(orderId, 'complete'),
                          onDetailsPressed: _showOrderDetails,
                        ),
                        const SizedBox(height: 16),
                        _OrderSection(
                          title: 'รอรับสินค้า',
                          orders: myAwaitingPickupOrders,
                          action: 'pickup',
                          onActionPressed: (orderId) => _updateOrderStatus(orderId, 'pickup'),
                          onDetailsPressed: _showOrderDetails,
                        ),
                      ],
                    ),
            ),
    );
  }
}

// --- Reusable Widgets ---

// ... _EmployeeDrawer() ...
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
// ... _OrderSection() ...
class _OrderSection extends StatelessWidget {
  final String title;
  final List<Order> orders;
  final String action;
  final Function(int) onActionPressed;
  final Function(Order) onDetailsPressed;

  const _OrderSection({
    required this.title,
    required this.orders,
    required this.action,
    required this.onActionPressed,
    required this.onDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('$title (${orders.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800])),
        ),
        if (orders.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 12, 16), child: Text('ไม่มีรายการ', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
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
// ... _OrderCard() ...
class _ButtonConfig {
  final String text;
  final IconData icon;
  final Color color;
  _ButtonConfig(this.text, this.icon, this.color);
}

class _OrderCard extends StatefulWidget {
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
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.action == 'complete') {
      _isButtonDisabled = true;
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isButtonDisabled = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ButtonConfig buttonConfig;
    switch (widget.action) {
      case 'accept':
        buttonConfig = _ButtonConfig('รับออเดอร์', Icons.check_circle_outline, Colors.amber[700]!);
        break;
      case 'complete':
        buttonConfig = _ButtonConfig('ทำรายการเสร็จสิ้น', Icons.done_all, Colors.green);
        break;
      case 'pickup':
         buttonConfig = _ButtonConfig('ลูกค้ารับแล้ว', Icons.check_circle, Colors.blue[700]!);
        break;
      default:
        buttonConfig = _ButtonConfig('Error', Icons.error, Colors.red);
    }

    final orderDateTime = DateTime.tryParse(widget.order.orderDate);
    final bool isPreOrder = orderDateTime != null && orderDateTime.isAfter(DateTime.now());

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('คำสั่งซื้อ #${widget.order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    if(isPreOrder)
                      const Text(
                        '(pre-order)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color.fromARGB(255, 243, 33, 33),
                        ),
                      ),
                  ],
                ),
                Text('฿${widget.order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('ลูกค้า: ${widget.order.customerName}', style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('ดูรายละเอียด'),
                  onPressed: widget.onDetailsPressed,
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (widget.action == 'complete' && _isButtonDisabled) ? null : widget.onActionPressed,
                  icon: Icon(buttonConfig.icon, size: 20),
                  label: Text(buttonConfig.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonConfig.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
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