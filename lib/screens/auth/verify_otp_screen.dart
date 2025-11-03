import 'package:pinput/pinput.dart'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/screens/auth/reset_password_screen.dart'; 

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  // [ลบ] 1. ลบ userType ออก
  
  const VerifyOtpScreen({
    super.key, 
    required this.email, 
    // [ลบ] 2. ลบ userType ออก
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController otpCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOtp() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/verify-otp'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': widget.email,
          'otp': otpCtrl.text,
          // [ลบ] 3. ลบ user_type ออก
        },
      );

      setState(() => isLoading = false);
      final data = json.decode(response.body.trim());

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: widget.email,
              otp: otpCtrl.text,
              // [ลบ] 4. ลบ user_type ออก
            ),
          ),
        );
      } else {
        _showErrorDialog(data['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    }
  }

  void _showErrorDialog(String message) {
     // (โค้ด _showErrorDialog ... เหมือนเดิม)
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontFamily: 'Sarabun'),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        border: Border.all(color: Colors.brown[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("ยืนยัน OTP", style: TextStyle(fontFamily: 'Sarabun')),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "กรุณากรอกรหัส OTP 6 หลัก ที่ส่งไปยัง\n${widget.email}",
              style: const TextStyle(fontFamily: 'Sarabun', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // [แก้ไข] 5. ใช้ Pinput
            Pinput(
              controller: otpCtrl,
              length: 6,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.brown),
                ),
              ),
              submittedPinTheme: defaultPinTheme,
              onCompleted: (pin) => verifyOtp(),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: isLoading ? null : verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ยืนยัน", style: TextStyle(fontFamily: 'Sarabun', fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}