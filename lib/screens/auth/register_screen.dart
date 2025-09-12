import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullnameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telCtrl = TextEditingController();

  // 1. เพิ่มตัวแปรสำหรับจัดการ Loading State
  bool isLoading = false;

  Future<void> register() async {
    // 2. เพิ่มการตรวจสอบข้อมูลเบื้องต้น
    if (fullnameCtrl.text.isEmpty ||
        usernameCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        telCtrl.text.isEmpty) {
      _showErrorDialog("กรุณากรอกข้อมูลให้ครบถ้วน");
      return;
    }

    if (passwordCtrl.text != confirmCtrl.text) {
      _showErrorDialog("รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 3. แก้ไข URL ให้ถูกต้อง (เพิ่ม Port :8000) และเพิ่ม Header 'Accept'
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'fullname': fullnameCtrl.text,
          'username': usernameCtrl.text,
          'password': passwordCtrl.text,
          'email': emailCtrl.text,
          'cus_tel': telCtrl.text,
        }),
      );

      // ตรวจสอบ response ก่อน decode
      if (!mounted) return;

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("สมัครสมาชิกสำเร็จ กำลังกลับไปหน้าเข้าสู่ระบบ..."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showErrorDialog(data['message'] ?? "ข้อมูลบางอย่างไม่ถูกต้อง");
      }
    } catch (e) {
      _showErrorDialog("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e");
    } finally {
      // ไม่ว่าจะสำเร็จหรือล้มเหลว ให้หยุด loading
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ผิดพลาด", style: TextStyle(fontFamily: 'Sarabun')),
        content: Text(message, style: const TextStyle(fontFamily: 'Sarabun')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ตกลง", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullnameCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    super.dispose();
  }

  // 4. ปรับปรุง UI ทั้งหมด
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("สมัครสมาชิก", style: TextStyle(fontFamily: 'Sarabun')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.brown[800],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "สร้างบัญชีใหม่",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                  fontFamily: 'Sarabun',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTextField(controller: fullnameCtrl, label: "ชื่อ-นามสกุล", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: usernameCtrl, label: "ชื่อผู้ใช้", icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField(controller: emailCtrl, label: "อีเมล", icon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(controller: telCtrl, label: "เบอร์โทรศัพท์", icon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(controller: passwordCtrl, label: "รหัสผ่าน", icon: Icons.lock_outline, obscureText: true),
              const SizedBox(height: 16),
              _buildTextField(controller: confirmCtrl, label: "ยืนยันรหัสผ่าน", icon: Icons.lock, obscureText: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        "ลงทะเบียน",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Sarabun'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Sarabun'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown[400]),
        prefixIcon: Icon(icon, color: Colors.brown[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.brown[50],
      ),
    );
  }
}