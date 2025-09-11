import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<Product, int> cart;
  final int? cusId;

  const CartScreen({Key? key, required this.cart, this.cusId}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  double _discount = 0.0;
  String? _promoMessage;
  String? _promoId;

  @override
  void dispose() {
    _promoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cart.keys.fold(0.0, (sum, product) {
      return sum + (product.price * widget.cart[product]!);
    });
  }

  double get _totalPrice {
    double total = _subtotal - _discount;
    return total > 0 ? total : 0.0;
  }

  Future<void> _checkPromoCode() async {
    final promoCode = _promoController.text.trim();
    if (promoCode.isEmpty) {
      setState(() {
        _discount = 0.0;
        _promoMessage = null;
        _promoId = null;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2/api/check_promo.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'promo_name': promoCode}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _discount = double.parse(data['promo_discount'].toString());
          _promoId = data['promo_id'].toString();
          _promoMessage = 'ใช้โค้ดส่วนลดสำเร็จ! ส่วนลด: ฿${_discount.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _discount = 0.0;
          _promoId = null;
          _promoMessage = data['message'] ?? 'โค้ดโปรโมชันไม่ถูกต้อง';
        });
      }
    } catch (e) {
      setState(() {
        _discount = 0.0;
        _promoId = null;
        _promoMessage = 'เกิดข้อผิดพลาดในการตรวจสอบโค้ด';
      });
    }
  }

  // ฟังก์ชันสำหรับเพิ่มหรือลดจำนวนสินค้า
  void _updateQuantity(Product product, int quantity) {
    setState(() {
      if (quantity > 0) {
        widget.cart.update(product, (value) => quantity);
      } else {
        _removeProduct(product);
      }
    });
  }

  // ฟังก์ชันสำหรับลบสินค้าออกจากตะกร้า
  void _removeProduct(Product product) {
    setState(() {
      widget.cart.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // เพิ่มพื้นหลังสีอ่อน
      appBar: AppBar(
        title: const Text(
          'ตะกร้าสินค้า',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.brown[700], // เปลี่ยนสีเป็นสีน้ำตาลเข้ม
        iconTheme: const IconThemeData(color: Colors.white), // เปลี่ยนสีไอคอนย้อนกลับ
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีสินค้าในตะกร้า',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Sarabun',
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final product = widget.cart.keys.elementAt(index);
                      final quantity = widget.cart[product]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.proName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Sarabun',
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.brown),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        _updateQuantity(product, quantity - 1);
                                      } else {
                                        _removeProduct(product);
                                      }
                                    },
                                  ),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.brown),
                                    onPressed: () {
                                      _updateQuantity(product, quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '฿${(product.price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.brown,
                                  fontFamily: 'Sarabun',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _removeProduct(product);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Summary Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _promoController,
                        style: const TextStyle(fontFamily: 'Sarabun'),
                        decoration: InputDecoration(
                          labelText: 'โค้ดโปรโมชัน',
                          labelStyle: TextStyle(color: Colors.brown[400], fontFamily: 'Sarabun'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.brown[50],
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check, color: Colors.brown),
                            onPressed: _checkPromoCode,
                          ),
                        ),
                      ),
                      if (_promoMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _promoMessage!,
                            style: TextStyle(
                              color: _discount > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarksController,
                        style: const TextStyle(fontFamily: 'Sarabun'),
                        decoration: InputDecoration(
                          labelText: 'หมายเหตุ',
                          labelStyle: TextStyle(color: Colors.brown[400], fontFamily: 'Sarabun'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.brown[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ราคาย่อย:', style: TextStyle(fontSize: 16, fontFamily: 'Sarabun')),
                          Text('฿${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontFamily: 'Sarabun')),
                        ],
                      ),
                      if (_discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ส่วนลด:', style: TextStyle(fontSize: 16, color: Colors.green, fontFamily: 'Sarabun')),
                            Text('-฿${_discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontFamily: 'Sarabun')),
                          ],
                        ),
                      const Divider(color: Colors.grey, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'รวมทั้งหมด:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
                          ),
                          Text(
                            '฿${_totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                              fontFamily: 'Sarabun',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.cart.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณาเพิ่มสินค้าลงในตะกร้าก่อน', style: TextStyle(fontFamily: 'Sarabun'))),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                orderData: {
                                  'cus_id': widget.cusId ?? 0,
                                  'price_total': _totalPrice,
                                  'remarks': _remarksController.text.trim(),
                                  'order_items': widget.cart.entries.map((entry) {
                                    final product = entry.key;
                                    final quantity = entry.value;
                                    return {
                                      'pro_id': product.proId,
                                      'amount': quantity,
                                      'price_list': product.price,
                                      'pay_total': product.price * quantity,
                                    };
                                  }).toList(),
                                  'promo_id': _promoId,
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('ยืนยันและชำระเงิน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[600],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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