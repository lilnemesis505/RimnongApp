import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rimnongapp/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/api/auth.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': usernameCtrl.text,
          'password': passwordCtrl.text,
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Raw Body: ${response.body}');
      print('Body Type: ${response.body.runtimeType}');

      setState(() => isLoading = false);

      // Try decoding JSON safely
      final data = json.decode(response.body.trim());
      print('Decoded JSON: $data');

      if (data['status'] == 'success') {
        final role = data['role'];
        final id = data['id']; // ได้รับ ID จากการล็อกอิน

        if (role == 'customer') {
          Navigator.pushReplacementNamed(context, '/customer', arguments: id); // ส่ง ID ไปยัง CustomerScreen
        } else if (role == 'employee') {
          Navigator.pushReplacementNamed(context, '/employee', arguments: id); // ส่ง ID ไปยัง EmployeeScreen
        }
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("เข้าสู่ระบบไม่สำเร็จ", style: TextStyle(fontFamily: 'Sarabun')),
            content: Text(data['message'], style: const TextStyle(fontFamily: 'Sarabun')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Login Error: $e');

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ข้อผิดพลาด", style: TextStyle(fontFamily: 'Sarabun')),
          content: const Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", style: TextStyle(fontFamily: 'Sarabun')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // พื้นหลังสีอ่อน
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Rimnong Coffee",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800], // สีชื่อร้าน
                  fontFamily: 'Sarabun',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "ยินดีต้อนรับ",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Sarabun',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Username Field
              TextFormField(
                controller: usernameCtrl,
                style: const TextStyle(fontFamily: 'Sarabun'),
                decoration: InputDecoration(
                  labelText: "ชื่อผู้ใช้",
                  labelStyle: TextStyle(color: Colors.brown[400]),
                  prefixIcon: Icon(Icons.person, color: Colors.brown[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.brown[50],
                ),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextFormField(
                controller: passwordCtrl,
                style: const TextStyle(fontFamily: 'Sarabun'),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  labelStyle: TextStyle(color: Colors.brown[400]),
                  prefixIcon: Icon(Icons.lock, color: Colors.brown[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.brown[50],
                ),
              ),
              const SizedBox(height: 32),
              // Login Button
              ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Sarabun',
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Register Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  "ยังไม่มีบัญชี? สมัครสมาชิก",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown[400],
                    fontFamily: 'Sarabun',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}