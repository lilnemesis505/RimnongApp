import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rimnongapp/screens/auth/register_screen.dart';
import 'package:rimnongapp/config/api_config.dart';
import 'package:rimnongapp/screens/auth/forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool isLoading = false;

  // ⬇️ [เพิ่ม] 2. เพิ่มตัวแปร
  bool _rememberMe = false;
  final _storage = const FlutterSecureStorage();

  // ⬇️ [เพิ่ม] 3. เพิ่ม initState
  @override
  void initState() {
    super.initState();
    // เมื่อหน้าจอนี้โหลด ให้พยายามดึงข้อมูลที่เคยบันทึกไว้
    _tryAutoLogin();
  }

  // ฟังก์ชันสำหรับพยายาม auto-login
  Future<void> _tryAutoLogin() async {
    // อ่านค่า username และ password จาก storage
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');

    // ถ้ามีข้อมูลอยู่ (เคยติ๊ก Remember Me)
    if (username != null && password != null) {
      setState(() {
        usernameCtrl.text = username;
        passwordCtrl.text = password;
        _rememberMe = true;
        isLoading = true; // แสดงตัวหมุน
      });
      // สั่ง login อัตโนมัติ
      login();
    }
  }

  Future<void> login() async {
    // ถ้าไม่ได้มาจาก auto-login ให้ set isLoading เอง
    if (!isLoading) {
      setState(() => isLoading = true);
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': usernameCtrl.text, 'password': passwordCtrl.text},
      );

      // (print logs เหมือนเดิม)

      if (!mounted) return; // เช็คเผื่อผู้ใช้ปิดหน้าไปก่อน

      final data = json.decode(response.body.trim());

      if (data['status'] == 'success') {
        
        // ⬇️ [แก้ไข] 5. ตรรกะการบันทึกข้อมูล
        if (_rememberMe) {
          // ถ้าติ๊ก "จดจำ" ให้บันทึก
          await _storage.write(key: 'username', value: usernameCtrl.text);
          await _storage.write(key: 'password', value: passwordCtrl.text);
        } else {
          // ถ้าไม่ติ๊ก "จดจำ" ให้ลบข้อมูลเก่าทิ้ง (สำคัญ)
          await _storage.delete(key: 'username');
          await _storage.delete(key: 'password');
        }

        final role = data['role'];
        final id = data['id']; 

        if (role == 'customer') {
          Navigator.pushReplacementNamed(context, '/customer', arguments: id); 
        } else if (role == 'employee') {
          Navigator.pushReplacementNamed(context, '/employee', arguments: id); 
        }
      } else {
        // (ส่วน showDialog Error เหมือนเดิม)
        setState(() => isLoading = false); // หยุดหมุนเมื่อ login ไม่ผ่าน
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("เข้าสู่ระบบไม่สำเร็จ", style: TextStyle(fontFamily: 'Sarabun')),
            content: Text(data['message'], style: const TextStyle(fontFamily: 'Sarabun')),
            actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("ตกลง", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown))), ],
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Login Error: $e');
      // (ส่วน showDialog Error เหมือนเดิม)
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ข้อผิดพลาด", style: TextStyle(fontFamily: 'Sarabun')),
          content: const Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", style: TextStyle(fontFamily: 'Sarabun')),
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("ตกลง", style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown))), ],
        ),
      );
    }
    // [ลบ] setState(() => isLoading = false); บรรทัดนี้ (ถ้ามี) เพราะเราย้ายไปจัดการใน if/else/catch แล้ว
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            // ... (โค้ด Text 'Rimnong Coffee' และ 'ยินดีต้อนรับ') ...
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ 
              Text(
                "Rimnong Coffee",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800], 
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

            // ... (TextFormField Username และ Password เหมือนเดิม) ...
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
            // --- ⬇️ [เพิ่ม] 4. เพิ่ม Checkbox ---
              CheckboxListTile(
                value: _rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                title: Text(
                  "จดจำการเข้าสู่ระบบ",
                  style: TextStyle(fontFamily: 'Sarabun', color: Colors.brown[700]),
                ),
                controlAffinity: ListTileControlAffinity.leading, // ให้ Checkbox อยู่ด้านซ้าย
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.brown,
              ),
            // --- จบส่วน Checkbox ---

              const SizedBox(height: 16), // [ปรับ] ลดระยะห่าง
              // Login Button (เหมือนเดิม)
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
              // ... (ปุ่ม Register และ Forgot Password เหมือนเดิม) ...
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

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: Text(
                  "ลืมรหัสผ่าน?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600], 
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