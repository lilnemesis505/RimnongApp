import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/models/product.dart';
import 'package:rimnongapp/models/notification.dart'; 
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:rimnongapp/screens/cart_screen.dart';
import 'package:rimnongapp/screens/cushistory_screen.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  // --- State Variables ---
  List<Product> products = [];
  Map<Product, int> cart = {};
  List<AppNotification> _notifications = [];
  bool isLoading = true;
  int? _cusId;
  String _cusName = 'ลูกค้า';
  String _cusEmail = '';
  Timer? _notificationTimer;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cusId = ModalRoute.of(context)?.settings.arguments as int?;
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  // --- Data Fetching & Core Logic ---
  void _initializeScreen() {
    fetchProducts();
    if (_cusId != null) {
      _fetchCustomerData(_cusId!);
      _fetchNotifications();
      // ตั้งเวลาดึงข้อมูลแจ้งเตือนทุกๆ 30 วินาที
      _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _fetchNotifications();
      });
    }
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/products');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCustomerData(int cusId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/customers/$cusId');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _cusName = data['fullname'];
            _cusEmail = data['email'];
          });
        }
      }
    } catch (e) {
      print('Error fetching customer data: $e');
    }
  }

  // ✅ [NEW] ฟังก์ชันดึงข้อมูลการแจ้งเตือนสำหรับลูกค้า
  Future<void> _fetchNotifications() async {
    if (_cusId == null) return;
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications?cus_id=$_cusId');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching customer notifications: $e');
    }
  }

  void addToCart(Product product) {
    setState(() {
      cart.update(product, (value) => value + 1, ifAbsent: () => 1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.proName} ถูกเพิ่มในตะกร้า'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.brown[600],
      ),
    );
  }

  // ✅ [NEW] ฟังก์ชันสำหรับแสดง Dialog การแจ้งเตือน
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
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationTile(notification);
                      },
                    ),
            ),
             actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด', style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown)),
              )
            ],
          );
        });
  }

  // ✅ [NEW] Widget สำหรับสร้างรายการแจ้งเตือนแต่ละอัน
  Widget _buildNotificationTile(AppNotification notification) {
    IconData icon;
    Color color;
    switch (notification.type) {
      case NotificationType.promotion:
        icon = Icons.campaign_rounded;
        color = Colors.green.shade600;
        break;
      case NotificationType.readyForPickup:
        icon = Icons.inventory_2_rounded;
        color = Colors.blue.shade700;
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

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _CustomerDrawer(cusName: _cusName, cusEmail: _cusEmail, cusId: _cusId, cart: cart),
      appBar: AppBar(
        title: const Text('เมนูเครื่องดื่ม', style: TextStyle(color: Colors.white, fontFamily: 'Sarabun', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ [NEW] เพิ่มปุ่มแจ้งเตือนข้างๆ ตะกร้า
          IconButton(
            icon: Icon(
              _notifications.isEmpty 
                  ? Icons.notifications_none_outlined 
                  : Icons.notifications_active,
              color: Colors.white,
            ),
            onPressed: _showNotificationsDialog,
            tooltip: 'การแจ้งเตือน',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(cart: cart, cusId: _cusId))),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : RefreshIndicator(
            onRefresh: fetchProducts,
            child: _ProductGrid(products: products, onAddToCart: addToCart)
          ),
    );
  }
}
class _CustomerDrawer extends StatelessWidget {
  const _CustomerDrawer({
    required this.cusName,
    required this.cusEmail,
    required this.cusId,
    required this.cart,
  });

  final String cusName;
  final String cusEmail;
  final int? cusId;
  final Map<Product, int> cart;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(cusName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
            accountEmail: Text(cusEmail, style: const TextStyle(fontFamily: 'Sarabun')),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.brown[100],
              child: Icon(Icons.person, size: 40, color: Colors.brown[700]),
            ),
            decoration: BoxDecoration(color: Colors.brown[400]),
          ),
          ListTile(
            leading: Icon(Icons.local_drink, color: Colors.brown[700]),
            title: const Text('เมนูเครื่องดื่ม', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart, color: Colors.brown[700]),
            title: const Text('ตะกร้าสินค้า', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(cart: cart, cusId: cusId)));
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt, color: Colors.brown[700]),
            title: const Text('ประวัติคำสั่งซื้อ', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => CusHistoryScreen(cusId: cusId)));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.brown[700]),
            title: const Text('ออกจากระบบ', style: TextStyle(fontFamily: 'Sarabun')),
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onAddToCart});

  final List<Product> products;
  final Function(Product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('ไม่พบรายการสินค้า', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product, onAddToCart: () => onAddToCart(product));
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAddToCart});

  final Product product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final bool hasPromo = product.specialPrice != null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/no-image.png', fit: BoxFit.cover);
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.brown, strokeWidth: 2));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  product.proName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sarabun', color: Colors.brown),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // --- ส่วนแสดงราคาที่แก้ไขใหม่ ---
                if (hasPromo) ...[
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                  Text(
                    '฿${product.specialPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Sarabun',
                    ),
                  ),
                ] else ...[
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sarabun'
                    ),
                  ),
                ],
                // --- จบส่วนแสดงราคา ---
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('สั่งซื้อ'),
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
