import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rimnongapp/config/api_config.dart';

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

  bool isLoading = false;

  // ✅ 2. เพิ่ม State สำหรับจัดการการตรวจสอบข้อมูลซ้ำ
  Timer? _debounce;
  bool _isUsernameChecking = false;
  bool _isEmailChecking = false;
  String? _usernameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // ✅ 3. เพิ่ม Listener เพื่อดักจับการพิมพ์
    usernameCtrl.addListener(_onUsernameChanged);
    emailCtrl.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    // ✅ 4. ยกเลิก Timer และ Listener เมื่อปิดหน้า
    _debounce?.cancel();
    usernameCtrl.removeListener(_onUsernameChanged);
    emailCtrl.removeListener(_onEmailChanged);
    fullnameCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    super.dispose();
  }

  // ✅ 5. ฟังก์ชันจัดการเมื่อมีการพิมพ์ Username (Debounce Logic)
  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (usernameCtrl.text.isNotEmpty) {
        _checkAvailability('username', usernameCtrl.text);
      }
    });
  }
  
  // ✅ 6. ฟังก์ชันจัดการเมื่อมีการพิมพ์ Email (Debounce Logic)
  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
       if (emailCtrl.text.isNotEmpty && emailCtrl.text.contains('@')) {
        _checkAvailability('email', emailCtrl.text);
      }
    });
  }
  
  // ✅ 7. ฟังก์ชันเรียก API ตรวจสอบข้อมูลซ้ำ
  Future<void> _checkAvailability(String field, String value) async {
    setState(() {
      if (field == 'username') {
        _isUsernameChecking = true;
        _usernameError = null;
      } else {
        _isEmailChecking = true;
        _emailError = null;
      }
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/check-availability'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'field': field, 'value': value}),
      );

      if (mounted) {
        final data = json.decode(response.body);
        setState(() {
          if (field == 'username') {
            _usernameError = (data['available'] == false) ? 'ชื่อผู้ใช้นี้มีคนใช้แล้ว' : null;
          } else {
            _emailError = (data['available'] == false) ? 'อีเมลนี้มีคนใช้แล้ว' : null;
          }
        });
      }
    } catch (e) {
      // Handle error silently or show a small indicator
      print('Check availability error: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (field == 'username') _isUsernameChecking = false;
          else _isEmailChecking = false;
        });
      }
    }
  }
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
    // ✅ 8. ตรวจสอบว่าไม่มี error จากการเช็ค real-time ค้างอยู่
    if (_usernameError != null || _emailError != null) {
      _showErrorDialog("กรุณาแก้ไขข้อมูลที่ซ้ำซ้อน");
      return;
    }

    if (passwordCtrl.text != confirmCtrl.text) {
      _showErrorDialog("รหัสผ่านไม่ตรงกัน");
      return;
    }
    // ... ส่วนที่เหลือของฟังก์ชัน register เหมือนเดิม ...
  

    setState(() => isLoading = true);

    try {
      // 3. แก้ไข URL ให้ถูกต้อง (เพิ่ม Port :8000) และเพิ่ม Header 'Accept'
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/register'),
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
            // ... โค้ดส่วน UI เหมือนเดิม แต่เราจะส่งค่า error และ state loading เข้าไปใน _buildTextField ...
            children: [
               Text(
                "สร้างบัญชีใหม่",
                //...
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: fullnameCtrl, 
                label: "ชื่อ-นามสกุล", 
                icon: Icons.person_outline
              ),
              const SizedBox(height: 16),
              // ✅ 9. ส่งค่า error และ loading state เข้าไปใน Widget
              _buildTextField(
                controller: usernameCtrl,
                label: "ชื่อผู้ใช้",
                icon: Icons.person,
                errorText: _usernameError,
                isChecking: _isUsernameChecking,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: emailCtrl,
                label: "อีเมล",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                isChecking: _isEmailChecking,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: telCtrl,
                label: "เบอร์โทรศัพท์", 
                icon: Icons.phone, 
                keyboardType: TextInputType.phone
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: passwordCtrl, 
                label: "รหัสผ่าน", 
                icon: Icons.lock_outline, 
                obscureText: true
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: confirmCtrl,
                label: "ยืนยันรหัสผ่าน", 
                icon: Icons.lock, 
                obscureText: true
              ),
               const SizedBox(height: 32),
              // ✅ [REBUILD] แก้ไข Widget `ElevatedButton` ให้สมบูรณ์
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "ลงทะเบียน",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Sarabun',
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ✅ 10. ปรับปรุง Widget ให้รับค่า error และ state loading
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    bool isChecking = false,
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
        errorText: errorText, // แสดงข้อความ error ใต้ช่องกรอก
        suffixIcon: isChecking // แสดง loading icon ขณะตรวจสอบ
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.brown)
                ),
              )
            : null,
      ),
    );
  }
}