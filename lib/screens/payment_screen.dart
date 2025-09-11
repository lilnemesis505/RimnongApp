import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:rimnongapp/screens/customer_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PaymentScreen({super.key, required this.orderData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _slipImage;
  bool _isUploading = false;
  String _promptPayId = '0984873750'; // เลข PromptPay ของร้าน (ใส่ข้อมูลจริง)
  String _bankName = 'ธนาคารกรุงไทย'; // ชื่อธนาคาร
  String _accountName = 'นายพงศกร มณีสาย';

  // ฟังก์ชันคำนวณ CRC (Cyclic Redundancy Check) สำหรับ PromptPay
  int crc16(String data) {
    const int polynomial = 0x1021;
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ polynomial;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  // สร้างข้อมูล QR Code สำหรับ PromptPay
  String get _promptPayPayload {
    double amount = widget.orderData['price_total'];

    // โครงสร้างของ PromptPay QR Code ตามมาตรฐาน EMVCo
    String payload = '000201'; // Payload Format Indicator
    payload += '010212'; // Point of Initiation Method: 12 = Dynamic
    payload += '2937'; // Merchant Account Information: PromptPay
    payload += '0016A000000677010111'; // Application ID
    payload += '01'; // ID Type
    payload += '13' + _promptPayId.padLeft(13, '0'); // PromptPay ID (Phone number)
    payload += '5802TH'; // Country Code: Thailand
    payload += '54' + amount.toStringAsFixed(2).length.toString().padLeft(2, '0') + amount.toStringAsFixed(2); // Amount
    payload += '5303764'; // Currency: THB

    // ส่วน CRC จะถูกเพิ่มเป็นส่วนสุดท้าย
    String crcHex = crc16(payload).toRadixString(16).toUpperCase().padLeft(4, '0');
    payload += '6304' + crcHex;

    return payload;
  }

  Future<void> _pickSlipImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _slipImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrderWithSlip() async {
    if (_slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดรูปภาพสลิปก่อน')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final url = Uri.parse('http://10.0.2.2/api/order.php');

    try {
      var request = http.MultipartRequest('POST', url);

      // เพิ่มข้อมูลคำสั่งซื้อ
      request.fields['cus_id'] = widget.orderData['cus_id'].toString();
      request.fields['price_total'] = widget.orderData['price_total'].toString();
      request.fields['remarks'] = widget.orderData['remarks'].toString();
      request.fields['order_items'] = json.encode(widget.orderData['order_items']);
      if (widget.orderData['promo_id'] != null) {
        request.fields['promo_id'] = widget.orderData['promo_id'].toString();
      }

      // เพิ่มรูปภาพสลิป
      request.files.add(
        http.MultipartFile.fromBytes(
          'slip_image',
          _slipImage!.readAsBytesSync(),
          filename: path.basename(_slipImage!.path),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สั่งซื้อสำเร็จ!')),
        );
       Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerScreen()),
            (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'เกิดข้อผิดพลาดในการสั่งซื้อ')),
        );
      }
    } catch (e) {
      print('Error submitting order with slip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.orderData['price_total'];

    return Scaffold(
      backgroundColor: Colors.grey[50], // เพิ่มพื้นหลังสีอ่อน
      appBar: AppBar(
        title: const Text(
          'หน้าชำระเงิน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[700], // เปลี่ยนเป็นสีน้ำตาลเข้ม
        elevation: 0, // เอาเงาออกเพื่อให้ดูมินิมอล
        iconTheme: const IconThemeData(color: Colors.white), // เปลี่ยนสีไอคอนย้อนกลับ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'สแกนเพื่อชำระเงินด้วย PromptPay',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown, // สีตัวอักษรให้เข้ากับธีม
                fontFamily: 'Sarabun',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _promptPayPayload,
                  version: QrVersions.auto,
                  size: 180.0, // ปรับขนาด QR Code ให้เหมาะสม
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.brown, // สีตา QR ให้เข้ากับธีม
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.brown, // สีข้อมูล QR ให้เข้ากับธีม
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0, // เอาเงาออก
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.brown[200]!, width: 1), // เพิ่มขอบบางๆ
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'ยอดที่ต้องชำระ',
                      style: TextStyle(fontSize: 18, color: Colors.brown, fontFamily: 'Sarabun'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                        fontFamily: 'Sarabun',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 16),
                    _buildPaymentDetailRow('ชื่อบัญชี:', _accountName),
                    _buildPaymentDetailRow('ธนาคาร:', _bankName),
                    _buildPaymentDetailRow('พร้อมเพย์:', _promptPayId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'อัปโหลดสลิปโอนเงิน',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                fontFamily: 'Sarabun',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickSlipImage,
              child: Container(
                height: 120, // Reduced height for the placeholder
                decoration: BoxDecoration(
                  color: _slipImage == null ? Colors.brown[50] : Colors.transparent,
                  border: Border.all(color: Colors.brown[200]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  image: _slipImage != null
                      ? DecorationImage(
                          image: FileImage(_slipImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _slipImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Colors.brown[300]),
                            const SizedBox(height: 8),
                            Text(
                              'แตะเพื่อเลือกสลิป',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.brown[400],
                                fontFamily: 'Sarabun',
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _isUploading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.brown)))
                : ElevatedButton.icon(
                    onPressed: _submitOrderWithSlip,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('ยืนยันและส่งสลิป'),
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
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Sarabun'),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.brown, fontFamily: 'Sarabun'),
          ),
        ],
      ),
    );
  }
}