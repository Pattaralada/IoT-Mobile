import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DashboardService {
  // ===============================
  // Mobile Device (ใช้ส่งคำสั่ง)
  // ===============================
  static const String controlClientId = 'my-dashboard-app';

  static const String controlToken = 'my-dashboard-token';
  // ===============================
  // ESP32 Device (ใช้ดึง sensor)
  // ===============================
  static const String espClientId = 'my-esp32-device';

  static const String espToken = 'my-esp32-token';

  // ===============================
  // API URL
  // ===============================
  static const String shadowURL = 'https://api.netpie.io/v2/device/shadow/data';

  static const String controlURL =
      'https://api.netpie.io/v2/device/message/lab_ict_kps/dashboard_control';

  // ===============================
  // Header อ่าน sensor
  // ===============================
  static Map<String, String> get _shadowHeaders => {
    'Authorization': 'Device $espClientId:$espToken',
    'Content-Type': 'application/json',
  };

  // ===============================
  // Header ส่งคำสั่ง
  // ===============================
  static Map<String, String> get _controlHeaders => {
    'Authorization': 'Device $controlClientId:$controlToken',
    'Content-Type': 'text/plain',
  };
  // ===============================
  // อ่าน Sensor จาก Shadow
  // ===============================
  static Future<Map<String, dynamic>?> getShadowData() async {
    try {
      final res = await http.get(Uri.parse(shadowURL), headers: _shadowHeaders);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (e) {
      print("Shadow error: $e");
    }

    return null;
  }

  // ===============================
  // เปิดระบบ
  // ===============================
  static Future<bool> systemOn() async {
    return _sendCommand("SYSTEM_ON");
  }

  // ===============================
  // ปิดระบบ
  // ===============================
  static Future<bool> systemOff() async {
    return _sendCommand("SYSTEM_OFF");
  }

  // ===============================
  // ส่งคำสั่งไป ESP32
  // ===============================
  static Future<bool> _sendCommand(String command) async {
    try {
      final res = await http.post(
        Uri.parse(controlURL),
        headers: _controlHeaders,
        body: command,
      );

      print("SEND COMMAND: $command");
      print("STATUS: ${res.statusCode}");

      return res.statusCode == 200;
    } catch (e) {
      print("Control error: $e");
      return false;
    }
  }

  // ===============================
  // Compatibility Method (ใช้กับ dashboard.dart)
  // ===============================
  static Future<bool> sendControl(String command) async {
    if (command == "ON") {
      return systemOn();
    }

    if (command == "OFF") {
      return systemOff();
    }

    return false;
  }
}
