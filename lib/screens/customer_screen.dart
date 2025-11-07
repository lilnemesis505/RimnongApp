import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/models/product.dart';
import 'package:rimnongapp/models/notification.dart'; 
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      _initializeScreen(); // ✅ เรียกฟังก์ชันที่แก้ไขใหม่
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
  final _storage = const FlutterSecureStorage();

// 3. ค้นหาฟังก์ชัน/ปุ่ม Logout ของคุณ
void _handleLogout() async { // ทำให้เป็น async
  // ⬇️ 4. เพิ่มโค้ดลบข้อมูล
  await _storage.delete(key: 'username');
  await _storage.delete(key: 'password');

  // 5. ค่อย Navigate กลับไปหน้า Login
  // (ตรวจสอบให้แน่ใจว่าใช้ 'pushAndRemoveUntil' เพื่อล้างหน้าจอเก่าทั้งหมด)
  if (mounted) { // เช็คว่า context ยังอยู่
     Navigator.pushAndRemoveUntil(
       context, 
       MaterialPageRoute(builder: (_) => const LoginScreen()), 
       (route) => false
     );
  }
}

  // --- Data Fetching & Core Logic ---
  Future<void> _initializeScreen() async {
    
    // 2. สั่งให้ "รอ" จนกว่าจะดึงสินค้า (ตัวหลัก) เสร็จก่อน
    //    isLoading จะถูกตั้งเป็น false ภายใน fetchProducts()
    await fetchProducts();

    // 3. หลังจากโหลดสินค้าเสร็จแล้ว ค่อยไปดึงข้อมูลส่วนเสริม
    //    เช็คด้วยว่าหน้าจอยังไม่ถูกปิด (mounted)
    if (mounted && _cusId != null) {
      // 4. ดึงข้อมูลลูกค้าและการแจ้งเตือน (ตอนนี้เซิร์ฟเวอร์น่าจะว่างแล้ว)
      _fetchCustomerData(_cusId!);
      _fetchNotifications(); // 👈 ดึงครั้งแรก
      
      // 5. [ย้ายมาไว้ตรงนี้] เริ่มต้นตัวจับเวลาหลังจากดึงข้อมูลครั้งแรกสำเร็จ
      _notificationTimer?.cancel(); // ล้างของเก่า (ถ้ามี)
      _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_cusId != null) {
          _fetchNotifications();
        }
      });
    }
  }
Future<void> fetchProducts() async {
    // 💡 [เพิ่ม] หน่วงเวลาเล็กน้อย (0.3 วินาที)
    // เพื่อให้เซิร์ฟเวอร์ได้พักหายใจหลังจากทำงานหนัก (สั่งออเดอร์)
    await Future.delayed(const Duration(milliseconds: 300));

    final url = Uri.parse('${ApiConfig.baseUrl}/api/products');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        print('Error fetching products: Server returned status ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      // ⬇️ [แนะนำ] เพิ่ม else/catch ให้ครบเหมือน fetchProducts
      else if (mounted) {
         print('Error fetching customer data: Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        print('Error fetching customer data: $e');
      }
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
      // ⬇️ [แนะนำ] เพิ่ม else/catch ให้ครบเหมือน fetchProducts
      else if (mounted) {
        print('Error fetching notifications: Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        print('Error fetching customer notifications: $e');
      }
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
      // ⭐️ [FIX 1] ส่งฟังก์ชัน _handleLogout เข้าไป
      drawer: _CustomerDrawer(
        cusName: _cusName, 
        cusEmail: _cusEmail, 
        cusId: _cusId, 
        cart: cart, 
        onLogout: _handleLogout, // 👈 [แก้ไข] เพิ่มพารามิเตอร์นี้
      ),
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
    required this.onLogout, // 👈 [ถูกต้อง] ที่คุณเพิ่มไว้
  });

  final String cusName;
  final String cusEmail;
  final int? cusId;
  final Map<Product, int> cart;
  final VoidCallback onLogout; // 👈 [ถูกต้อง] ที่คุณเพิ่มไว้

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
            // ⭐️ [FIX 2] เปลี่ยนให้เรียกฟังก์ชัน onLogout
            onTap: onLogout, // 👈 [แก้ไข] เปลี่ยนจากโค้ด Navigator เก่า
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
          // ... (ส่วน Image) ...
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
                  // ⬇️ [FIX 1] ย้าย textAlign: ออกจาก style:
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sarabun', color: Colors.brown),
                  textAlign: TextAlign.center, // 👈 [FIX 2] ย้ายมาไว้ตรงนี้
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // ... (โค้ดส่วนที่เหลือ) ...
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