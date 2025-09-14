import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _remarksController = TextEditingController();
  TimeOfDay? _selectedPickupTime;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // --- Functions to calculate prices ---

  double get _subtotal {
    if (widget.cart.isEmpty) return 0.0;
    return widget.cart.entries
        .map((entry) => entry.key.price * entry.value)
        .reduce((a, b) => a + b);
  }

  double get _totalDiscount {
    if (widget.cart.isEmpty) return 0.0;
    return widget.cart.entries
        .map((entry) {
          final product = entry.key;
          final quantity = entry.value;
          if (product.specialPrice != null) {
            return (product.price - product.specialPrice!) * quantity;
          }
          return 0.0;
        })
        .reduce((a, b) => a + b);
  }

  double get _totalPrice {
    return _subtotal - _totalDiscount;
  }

  // --- Cart and Time Picker Logic ---

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ลบสินค้า', style: TextStyle(fontFamily: 'Sarabun')),
          content: Text('คุณต้องการลบ "${product.proName}" ออกจากตะกร้าใช่หรือไม่?', style: const TextStyle(fontFamily: 'Sarabun')),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก', style: TextStyle(fontFamily: 'Sarabun', color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('ยืนยัน', style: TextStyle(fontFamily: 'Sarabun', color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => widget.cart.remove(product));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectPickupTime(BuildContext context) async {
    final now = TimeOfDay.now();
    const closingTime = TimeOfDay(hour: 18, minute: 0);

    if (now.hour > closingTime.hour || (now.hour == closingTime.hour && now.minute >= closingTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปิดรับออเดอร์ล่วงหน้าสำหรับวันนี้แล้ว (หลัง 18:00 น.)', style: TextStyle(fontFamily: 'Sarabun'))),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour + 1, minute: 0),
      helpText: 'เลือกเวลารับสินค้า',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final pickedDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, picked.hour, picked.minute);
      final nowDateTime = DateTime.now();
      final closingDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, closingTime.hour, closingTime.minute);

      if (pickedDateTime.isBefore(nowDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเลือกเวลาที่ผ่านมาแล้วได้', style: TextStyle(fontFamily: 'Sarabun'))),
        );
        return;
      }

      if (pickedDateTime.isAfter(closingDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกเวลาก่อน 18:00 น.', style: TextStyle(fontFamily: 'Sarabun'))),
        );
        return;
      }

      setState(() {
        _selectedPickupTime = picked;
      });
      _navigateToPayment();
    }
  }

  void _navigateToPayment() {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มสินค้าลงในตะกร้าก่อน', style: TextStyle(fontFamily: 'Sarabun'))),
      );
      return;
    }

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
          'price_list': product.specialPrice ?? product.price, // Send special price if available
          'pay_total': (product.specialPrice ?? product.price) * quantity,
        };
      }).toList(),
      if (_selectedPickupTime != null)
        'pickup_time': '${_selectedPickupTime!.hour.toString().padLeft(2, '0')}:${_selectedPickupTime!.minute.toString().padLeft(2, '0')}',
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(orderData: orderData)),
    );
  }

  // --- UI Widgets ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีสินค้าในตะกร้า', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Sarabun')),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(child: _buildCartList()),
                _buildSummaryAndActions(),
              ],
            ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      itemCount: widget.cart.length,
      itemBuilder: (context, index) {
        final product = widget.cart.keys.elementAt(index);
        final quantity = widget.cart[product]!;
        final hasPromo = product.specialPrice != null;
        final priceToShow = hasPromo ? product.specialPrice! : product.price;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.proName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Sarabun')),
                    if (hasPromo)
                      Text(
                        'ราคาปกติ: ฿${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12, fontFamily: 'Sarabun'),
                      ),
                  ],
                ),
              ),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.brown), onPressed: () => _updateQuantity(product, quantity - 1)),
                Text(quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.brown), onPressed: () => _updateQuantity(product, quantity + 1)),
              ]),
              const SizedBox(width: 8),
              Text('฿${(priceToShow * quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown, fontFamily: 'Sarabun')),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeProduct(product)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildSummaryAndActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRemarksField(),
          const SizedBox(height: 24),
          _buildPriceSummary(),
          const SizedBox(height: 24),
          _buildCheckoutButtons(context),
        ],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            const Text('ราคารวม:', style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Sarabun')),
            Text('฿${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Sarabun')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ส่วนลดโปรโมชั่น:', style: TextStyle(fontSize: 16, color: Colors.green, fontFamily: 'Sarabun')),
            Text('- ฿${_totalDiscount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontFamily: 'Sarabun')),
          ],
        ),
        const Divider(height: 24, thickness: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ยอดชำระสุทธิ:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Sarabun')),
            Text('฿${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown, fontFamily: 'Sarabun')),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _selectedPickupTime = null;
            });
            _navigateToPayment();
          },
          icon: const Icon(Icons.payment, color: Colors.white),
          label: const Text('ยืนยันและชำระเงิน', style: TextStyle(fontSize: 18, fontFamily: 'Sarabun', fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[600],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _selectPickupTime(context),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('สั่งล่วงหน้า (Pre-order)', style: TextStyle(fontSize: 16, fontFamily: 'Sarabun')),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.brown[700],
            side: BorderSide(color: Colors.brown[700]!),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

