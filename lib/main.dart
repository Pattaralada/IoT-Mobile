import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const FireApp());
}

class FireApp extends StatelessWidget {
  const FireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Detection System',

      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF0B0B12),
        fontFamily: 'Roboto',
      ),

      // หน้าแรก
      home: const HomeScreen(),

      // routing สำหรับ navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}