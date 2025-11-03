import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/screens/auth/verify_otp_screen.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  // [ลบ] 1. ลบ userType ออก
  bool isLoading = false;

  Future<void> requestOtp() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/request-otp'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
            'email': emailCtrl.text, 
            // [ลบ] 2. ลบ user_type ออก
        },
      );

      setState(() => isLoading = false);
      final data = json.decode(response.body.trim());

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              email: emailCtrl.text,
              // [ลบ] 3. ลบ user_type ออก
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("ลืมรหัสผ่าน", style: TextStyle(fontFamily: 'Sarabun')),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "กรุณากรอกอีเมลที่ลงทะเบียนไว้\nระบบจะส่ง OTP ไปยังอีเมลของคุณ", // 👈 [แก้ไข] 4. เปลี่ยนข้อความ
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // [ลบ] 5. ลบ DropdownButtonFormField ของ userType
            
            // 2. ช่องกรอกอีเมล
            TextFormField(
              controller: emailCtrl,
              style: const TextStyle(fontFamily: 'Sarabun'),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "อีเมล",
                labelStyle: TextStyle(color: Colors.brown[400]),
                prefixIcon: Icon(Icons.email, color: Colors.brown[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
            ),
            const SizedBox(height: 32),
            
            // 3. ปุ่มส่ง
            ElevatedButton(
              onPressed: isLoading ? null : requestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ขอรหัส OTP", style: TextStyle(fontFamily: 'Sarabun', fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}