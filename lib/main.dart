import 'package:flutter/material.dart';
import 'screens/customer_screen.dart';
import 'screens/employee_screen.dart';
import 'screens/auth/login_screen.dart'; 


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Ordering',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/customer': (context) => const CustomerScreen(),
        '/employee': (context) => const EmployeeScreen(),
      },
    );
  }
}

