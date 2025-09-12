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
  int? _promoId; // เปลี่ยนเป็น int? เพื่อให้สอดคล้องกับ database

  @override
  void dispose() {
    _promoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double get _subtotal {
    if (widget.cart.isEmpty) {
      return 0.0;
    }
    return widget.cart.entries
        .map((entry) => entry.key.price * entry.value)
        .reduce((value, element) => value + element);
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

    // ✅ 1. แก้ไข IP Address ให้ถูกต้องสำหรับ Android Emulator
    final url = Uri.parse('http://10.0.2.2:8000/api/promotions/check');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'promo_name': promoCode}),
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _discount = double.parse(data['promo_discount'].toString());
          _promoId = int.parse(data['promo_id'].toString());
          _promoMessage =
              'ใช้โค้ดส่วนลดสำเร็จ! ส่วนลด: ฿${_discount.toStringAsFixed(2)}';
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

  void _updateQuantity(Product product, int quantity) {
    setState(() {
      if (quantity > 0) {
        widget.cart[product] = quantity;
      } else {
        _removeProduct(product);
      }
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      widget.cart.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ตะกร้าสินค้า',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sarabun'),
        ),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[400]),
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
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final product = widget.cart.keys.elementAt(index);
                      final quantity = widget.cart[product]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
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
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.brown),
                                    onPressed: () =>
                                        _updateQuantity(product, quantity - 1),
                                  ),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Sarabun'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.brown),
                                    onPressed: () =>
                                        _updateQuantity(product, quantity + 1),
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
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _removeProduct(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPromoField(),
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
                      _buildRemarksField(),
                      const SizedBox(height: 24),
                      _buildPriceSummary(),
                      const SizedBox(height: 24),
                      _buildCheckoutButton(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPromoField() {
    return TextField(
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
          icon: const Icon(Icons.check_circle, color: Colors.brown),
          onPressed: _checkPromoCode,
        ),
      ),
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      style: const TextStyle(fontFamily: 'Sarabun'),
      decoration: InputDecoration(
        labelText: 'หมายเหตุถึงร้านค้า',
        labelStyle: TextStyle(color: Colors.brown[400], fontFamily: 'Sarabun'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.brown[50],
      ),
      maxLines: 2,
    );
  }

  Widget _buildPriceSummary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ราคารวม:',
                style: TextStyle(fontSize: 16, fontFamily: 'Sarabun')),
            Text('฿${_subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontFamily: 'Sarabun')),
          ],
        ),
        if (_discount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ส่วนลด:',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontFamily: 'Sarabun')),
                Text('-฿${_discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontFamily: 'Sarabun')),
              ],
            ),
          ),
        const Divider(color: Colors.grey, height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ยอดชำระ:',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sarabun'),
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
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        if (widget.cart.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('กรุณาเพิ่มสินค้าลงในตะกร้าก่อน',
                    style: TextStyle(fontFamily: 'Sarabun'))),
          );
          return;
        }

        // ✅ 2. ปรับปรุงการส่งข้อมูล promo_id
        final orderData = {
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
          if (_promoId != null) 'promo_id': _promoId,
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(orderData: orderData),
          ),
        );
      },
      icon: const Icon(Icons.payment, color: Colors.white),
      label: const Text(
        'ยืนยันและชำระเงิน',
        style: TextStyle(
            fontSize: 18, fontFamily: 'Sarabun', fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}