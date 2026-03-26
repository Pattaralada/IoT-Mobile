import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sound_generator/sound_generator.dart';
import 'dashboard_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double temperature = 0;
  double humidity = 0;
  int smoke = 0;

  bool flame = false;
  bool alarm = false;

  bool _loading = true;
  bool _dialogShowing = false;
  bool _sirenRunning = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    stopSiren();
    super.dispose();
  }

  Future<void> _init() async {
    await SoundGenerator.init(440);
    await _fetchShadow();
    _startPolling();
  }

  // ===============================
  // POLLING
  // ===============================

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchShadow(),
    );
  }

  // ===============================
  // FETCH SHADOW
  // ===============================

  Future<void> _fetchShadow() async {
    try {
      setState(() => _loading = true);

      final data = await DashboardService.getShadowData();

      if (data != null && mounted) {
        setState(() {
          temperature = double.tryParse(data['temperature'].toString()) ?? 0;
          humidity = double.tryParse(data['humidity'].toString()) ?? 0;
          smoke = int.tryParse(data['gas'].toString()) ?? 0;

          flame = data['fire'].toString() == "true";
          alarm = data['alarm'].toString() == "true";
        });

        if (flame) {
          startSiren();

          if (!_dialogShowing) {
            _showFirePopup();
          }
        } else {
          stopSiren();
        }
      }
    } catch (e) {
      print("Shadow error: $e");
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // ===============================
  // SIREN GENERATOR
  // ===============================

  Future<void> startSiren() async {
    if (_sirenRunning) return;

    _sirenRunning = true;

    while (_sirenRunning) {
      for (int f = 800; f < 2000; f += 100) {
        if (!_sirenRunning) return;

        SoundGenerator.setFrequency(f.toDouble());
        SoundGenerator.play();

        await Future.delayed(const Duration(milliseconds: 20));
      }

      for (int f = 2000; f > 800; f -= 100) {
        if (!_sirenRunning) return;

        SoundGenerator.setFrequency(f.toDouble());
        SoundGenerator.play();

        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  Future<void> stopSiren() async {
    if (!_sirenRunning) return;

    _sirenRunning = false;
    SoundGenerator.stop();
  }

  // ===============================
  // FIRE POPUP
  // ===============================

  void _showFirePopup() {
    _dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _FireAlertDialog(
            onDismiss: () async {
              await stopSiren();
              await _toggleBuzzer(false);

              Navigator.pop(context);
              _dialogShowing = false;
            },
          ),
    );
  }

  // ===============================
  // BUZZER CONTROL
  // ===============================

  Future<void> _toggleBuzzer(bool on) async {
    if (on) {
      await DashboardService.systemOn();
      startSiren();
    } else {
      await DashboardService.systemOff();
      stopSiren();
    }
  }

  // ===============================
  // UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),

      appBar: AppBar(
        title: const Text("Fire Detector"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchShadow,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStatusCard(),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _SensorCard(
                            label: "Temperature",
                            value: temperature.toStringAsFixed(1),
                            unit: "°C",
                            emoji: "🌡️",
                            color: Colors.orange,
                            progress: (temperature / 100).clamp(0.0, 1.0),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _SensorCard(
                            label: "Humidity",
                            value: humidity.toStringAsFixed(1),
                            unit: "%",
                            emoji: "💧",
                            color: Colors.blue,
                            progress: (humidity / 100).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _SmokeCard(smoke: smoke),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        _toggleBuzzer(!alarm);
                      },
                      child: Text(alarm ? "ปิด Buzzer" : "เปิด Buzzer"),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: _fetchShadow,
                      child: const Text("Refresh"),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusCard() {
    final color = flame ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Text(flame ? "🔥" : "✅", style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flame ? "FIRE DETECTED" : "ALL CLEAR",
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                flame ? "ตรวจพบไฟไหม้!" : "ระบบปกติ",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String emoji;
  final Color color;
  final double progress;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 4),

              Text(unit, style: TextStyle(color: color)),
            ],
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }
}

class _SmokeCard extends StatelessWidget {
  final int smoke;

  const _SmokeCard({required this.smoke});

  @override
  Widget build(BuildContext context) {
    Color color;
    String status;

    if (smoke > 400) {
      color = Colors.red;
      status = "อันตราย";
    } else if (smoke > 200) {
      color = Colors.orange;
      status = "ระวัง";
    } else {
      color = Colors.green;
      status = "ปกติ";
    }

    final progress = (smoke / 600).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF151520),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("💨"),
              const SizedBox(width: 8),
              const Text(
                "Smoke / Gas",
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(status, style: TextStyle(color: color)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$smoke",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(width: 6),

              const Text("ppm", style: TextStyle(color: Colors.white54)),
            ],
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }
}

class _FireAlertDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const _FireAlertDialog({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF200000),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🔥", style: TextStyle(fontSize: 50)),

            const SizedBox(height: 10),

            const Text(
              "FIRE DETECTED!",
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "กรุณาอพยพทันที",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: onDismiss, child: const Text("ปิดระบบ")),
          ],
        ),
      ),
    );
  }
}
