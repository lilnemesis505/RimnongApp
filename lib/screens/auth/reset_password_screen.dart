import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/screens/auth/login_screen.dart'; 

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  // [ลบ] 1. ลบ userType ออก

  const ResetPasswordScreen({
    super.key, 
    required this.email, 
    required this.otp,
    // [ลบ] 2. ลบ userType ออก
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> resetPassword() async {
    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      _showErrorDialog("รหัสผ่านไม่ตรงกัน");
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/password/reset'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': widget.email,
          'otp': widget.otp,
          'password': passwordCtrl.text,
          'password_confirmation': confirmPasswordCtrl.text,
          // [ลบ] 3. ลบ user_type ออก
        },
      );

      setState(() => isLoading = false);
      final data = json.decode(response.body.trim());

      if (response.statusCode == 200) {
        // (Logic... เหมือนเดิม)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("สำเร็จ", style: TextStyle(fontFamily: 'Sarabun')),
            content: Text(data['message'], style: const TextStyle(fontFamily: 'Sarabun')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false
                  );
                },
                child: const Text("ไปหน้า Login", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown)),
              ),
            ],
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
    // (โค้ด Build ... เหมือนเดิม)
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งรหัสผ่านใหม่", style: TextStyle(fontFamily: 'Sarabun')),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "กรุณาตั้งรหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)",
              style: TextStyle(fontFamily: 'Sarabun', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              style: const TextStyle(fontFamily: 'Sarabun'),
              decoration: InputDecoration(
                labelText: "รหัสผ่านใหม่",
                labelStyle: TextStyle(color: Colors.brown[400]),
                prefixIcon: Icon(Icons.lock, color: Colors.brown[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              style: const TextStyle(fontFamily: 'Sarabun'),
              decoration: InputDecoration(
                labelText: "ยืนยันรหัสผ่านใหม่",
                labelStyle: TextStyle(color: Colors.brown[400]),
                prefixIcon: Icon(Icons.lock, color: Colors.brown[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("บันทึกรหัสผ่านใหม่", style: TextStyle(fontFamily: 'Sarabun', fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}