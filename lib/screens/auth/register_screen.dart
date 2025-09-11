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

  Future<void> register(BuildContext context) async {
    if (passwordCtrl.text != confirmCtrl.text) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Passwords do not match"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/api/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullname': fullnameCtrl.text,
          'username': usernameCtrl.text,
          'password': passwordCtrl.text,
          'email': emailCtrl.text,
          'cus_tel': telCtrl.text,
        }),
      );

      final data = json.decode(response.body);
     if (data['status'] == 'success') {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("สมัครสมาชิกสำเร็จ"),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );

  // รอ SnackBar แสดงก่อนกลับไปหน้า Login
  Future.delayed(const Duration(seconds: 2), () {
    Navigator.pop(context);
  });
} else {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Error"),
      content: Text(data['message']),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("เกิดข้อผิดพลาด: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: fullnameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            TextField(controller: confirmCtrl, decoration: const InputDecoration(labelText: "Confirm Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => register(context),
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
