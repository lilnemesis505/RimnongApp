import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:rimnongapp/screens/customer_screen.dart';
import 'package:rimnongapp/config/api_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rimnongapp/service/permission_service.dart'; // เพิ่ม package นี้

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PaymentScreen({super.key, required this.orderData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _slipImage;
  bool _isUploading = false;
  String _promptPayId = '0984873750';
  String _bankName = 'ธนาคารกรุงไทย';
  String _accountName = 'นายพงศกร มณีสาย';

  // ขอสิทธิ์จากผู้ใช้
  Future<bool> _requestPermissions() async {
    // ขอสิทธิ์เข้าถึง Storage (สำหรับ Android) และ Photos (สำหรับ iOS)
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // ผู้ใช้ปฏิเสธแบบถาวร
      openAppSettings();
      return false;
    } else {
      // ผู้ใช้ปฏิเสธชั่วคราว
      return false;
    }
  }

  // เลือกรูปภาพสลิปจากแกลเลอรี
 Future<void> _pickSlipImage() async {
  // เรียกใช้ฟังก์ชันขอสิทธิ์จากไฟล์ PermissionService.dart
  final permissionGranted = await PermissionService.requestPhotosPermission();

  if (!permissionGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ไม่ได้รับอนุญาตให้เข้าถึงรูปภาพ โปรดลองอีกครั้ง'),
      ),
    );
    return;
  }

  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _slipImage = File(pickedFile.path);
    });
  }
}
  
  // โค้ดส่วนที่เหลือเหมือนเดิม
  // ... (ฟังก์ชัน CRC, get_promptPayPayload, และ _submitOrderWithSlip)
  // ... (build method)

  // คุณสามารถคัดลอกฟังก์ชัน crc16(), _promptPayPayload, _submitOrderWithSlip และ build method จากโค้ดเดิมได้เลย
  
  // (ฟังก์ชัน crc16 ที่มีอยู่แล้ว)
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

  // (get _promptPayPayload)
  String get _promptPayPayload {
    double amount = widget.orderData['price_total'];
    String payload = '000201';
    payload += '010212';
    payload += '2937';
    payload += '0016A000000677010111';
    payload += '01';
    payload += '13' + _promptPayId.padLeft(13, '0');
    payload += '5802TH';
    payload += '54' + amount.toStringAsFixed(2).length.toString().padLeft(2, '0') + amount.toStringAsFixed(2);
    payload += '5303764';
    String crcHex = crc16(payload).toRadixString(16).toUpperCase().padLeft(4, '0');
    payload += '6304' + crcHex;
    return payload;
  }

  // (ฟังก์ชัน _submitOrderWithSlip)
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

    final url = Uri.parse('${ApiConfig.baseUrl}/api/orders');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Accept'] = 'application/json';

      request.fields['cus_id'] = widget.orderData['cus_id'].toString();
      request.fields['price_total'] = widget.orderData['price_total'].toString();
      request.fields['remarks'] = widget.orderData['remarks'].toString();
      request.fields['order_items'] = json.encode(widget.orderData['order_items']);
      if (widget.orderData['promo_id'] != null) {
        request.fields['promo_id'] = widget.orderData['promo_id'].toString();
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'slip_image',
          _slipImage!.path,
          filename: path.basename(_slipImage!.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สั่งซื้อสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เกิดข้อผิดพลาดในการสั่งซื้อ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error submitting order with slip: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('การเชื่อมต่อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // (build method)
  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.orderData['price_total'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'หน้าชำระเงิน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                color: Colors.brown,
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
                  size: 180.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.brown,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.brown[200]!, width: 1),
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
                height: 120,
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