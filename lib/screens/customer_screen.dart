import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/screens/auth/login_screen.dart';
import 'package:rimnongapp/screens/cart_screen.dart';
import 'package:rimnongapp/screens/cushistory_screen.dart';
import 'package:rimnongapp/models/product.dart';
import 'dart:async';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<Product> products = [];
  Map<Product, int> cart = {};
  bool isLoading = true;
  int? _cusId;
  String _cusName = 'ลูกค้า';
  String _cusEmail = 'customer@example.com';

  int _completedOrdersCount = 0;
  Timer? _timer;

  void addToCart(Product product) {
    setState(() {
      cart.update(product, (value) => value + 1, ifAbsent: () => 1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.proName} ถูกเพิ่มในตะกร้า'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/api.php'));
    print('API Response: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> _checkOrderStatus() async {
    if (_cusId == null) return;
    final url = Uri.parse('http://10.0.2.2/api/fetch_cushistory.php?cus_id=$_cusId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final int completedCount = data.where((order) => order['receive_date'] != null).length;
        
        if (completedCount > _completedOrdersCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ คำสั่งซื้อเสร็จสิ้น กรุณามารับเครื่องดื่มที่เคาน์เตอร์'),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() {
          _completedOrdersCount = completedCount;
        });
      }
    } catch (e) {
      print('Error checking order status: $e');
    }
  }

  Future<void> _fetchCustomerData(int cusId) async {
    final url = Uri.parse('http://10.0.2.2/api/customer.php?cus_id=$cusId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cusId = ModalRoute.of(context)?.settings.arguments as int?;
      fetchProducts();
      if (_cusId != null) {
        _fetchCustomerData(_cusId!);
        // ตั้งเวลาเช็คสถานะคำสั่งซื้อทุก 5 วินาที
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _checkOrderStatus();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer เมื่อออกจากหน้าจอ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _cusName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
              ),
              accountEmail: Text(
                _cusEmail,
                style: const TextStyle(fontFamily: 'Sarabun'),
              ),
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
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(cart: cart, cusId: _cusId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt, color: Colors.brown[700]),
              title: const Text('ประวัติคำสั่งซื้อ', style: TextStyle(fontFamily: 'Sarabun')),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CusHistoryScreen(cusId: _cusId)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.brown[700]),
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
      ),
      appBar: AppBar(
        title: const Text(
          'เมนูเครื่องดื่ม',
          style: TextStyle(color: Colors.white, fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                   builder: (_) => CartScreen(cart: cart, cusId: _cusId),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7, // เพิ่มความสูงของ Card
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Image load error: $error');
                              return Image.network(
                                'http://10.0.2.2/storage/products/no-image.png',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              product.proName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Sarabun',
                                color: Colors.brown,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sarabun',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => addToCart(product),
                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('สั่งซื้อ'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                                backgroundColor: Colors.brown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}