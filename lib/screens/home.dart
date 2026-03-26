import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard.dart';
import 'dashboard_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _gridController;
  late Animation<double> _fadeAnim;

  // ── Alert level: 0=none, 1=smoke, 2=fire ─────────────────────────────────
  int _alertLevel = 0;
  bool _alertVisible = false;
  late AnimationController _alertController;
  late Animation<double> _alertScale;
  late Animation<double> _alertFade;

  // ── Polling สำหรับรับค่า sensor บนหน้า Home ──────────────────────────────
  int _lastAlertLevel = 0;
  DateTime _lastAlertTime = DateTime(2000);

  void showAlert(int level) {
    if (!mounted) return;
    // cooldown: ถ้า level เดิมและยังไม่ครบ 3 วิ ไม่แสดงซ้ำ
    final now = DateTime.now();
    if (level == _lastAlertLevel &&
        now.difference(_lastAlertTime).inSeconds < 3)
      return;
    _lastAlertLevel = level;
    _lastAlertTime = now;
    setState(() {
      _alertLevel = level;
      _alertVisible = true;
    });
    _alertController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _dismissAlert() {
    _alertController.reverse().then((_) {
      if (mounted) setState(() => _alertVisible = false);
    });
  }

  void _startHomePolling() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;

      try {
        final data = await DashboardService.getShadowData();

        if (data != null && mounted) {
          final smoke = (data['gas'] ?? 0).toInt();

          final flame =
              data['fire'] == true ||
              data['fire'] == 1 ||
              data['fire'].toString().toLowerCase() == 'true';

          if (flame) {
            showAlert(2);
          } else if (smoke > 400) {
            showAlert(1);
          }
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      }

      if (mounted) {
        _startHomePolling();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _gridController, curve: Curves.easeOut);
    _gridController.forward();

    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _alertScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeOutBack),
    );
    _alertFade = CurvedAnimation(
      parent: _alertController,
      curve: Curves.easeOut,
    );

    _startHomePolling();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final alerts = [
      null,
      _AlertInfo(
        level: 1,
        emoji: '💨',
        title: 'ตรวจพบควัน',
        subtitle: 'ตรวจพบควันในพื้นที่\nกรุณาตรวจสอบบริเวณใกล้เคียง',
        color: const Color(0xFFFFCC00),
        bgColor: const Color(0xFF1A1500),
        tag: 'WARNING',
      ),
      _AlertInfo(
        level: 2,
        emoji: '🔥',
        title: 'ตรวจพบไฟไหม้!',
        subtitle: 'พบสัญญาณไฟไหม้ชัดเจน\nกรุณาอพยพและแจ้งเจ้าหน้าที่ทันที!',
        color: const Color(0xFFFF3B30),
        bgColor: const Color(0xFF1A0505),
        tag: 'FIRE',
      ),
    ];

    final alert = _alertLevel > 0 ? alerts[_alertLevel] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, -0.5),
                radius: 1.4,
                colors: [
                  Color(0xFF1B2A4A),
                  Color(0xFF0D1520),
                  Color(0xFF060810),
                ],
              ),
            ),
            child: Center(
              child: _IPhoneProFrame(
                child: _iOSScreen(
                  fadeAnim: _fadeAnim,
                  alertInfo: _alertVisible ? alert : null,
                  alertController: _alertController,
                  onDismissAlert: _dismissAlert,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  iPhone 15 Pro Frame
// ══════════════════════════════════════════════════════════════════════════════

class _IPhoneProFrame extends StatelessWidget {
  final Widget child;
  const _IPhoneProFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    const double r = 48.0;
    const double screenR = 40.0;
    const double inset = 9.0;

    return SizedBox(
      width: 300,
      height: 620,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 24,
            left: 8,
            right: 8,
            bottom: -20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _TitaniumPainter(radius: r)),
          ),
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r - 3),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A1C),
                    Color(0xFF0D0D0F),
                    Color(0xFF151517),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: inset,
            left: inset,
            right: inset,
            bottom: inset,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenR),
              child: child,
            ),
          ),
          Positioned(
            top: inset,
            left: inset,
            right: inset,
            height: 160,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(screenR),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -3.5,
            top: 108,
            child: _SideBtn(height: 26, isLeft: true),
          ),
          Positioned(
            left: -3.5,
            top: 150,
            child: _SideBtn(height: 56, isLeft: true),
          ),
          Positioned(
            left: -3.5,
            top: 218,
            child: _SideBtn(height: 56, isLeft: true),
          ),
          Positioned(
            right: -3.5,
            top: 158,
            child: _SideBtn(height: 80, isLeft: false),
          ),
          Positioned(
            top: 0,
            left: 40,
            right: 40,
            height: 1,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitaniumPainter extends CustomPainter {
  final double radius;
  const _TitaniumPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          colors: [
            Color(0xFF6E6E73),
            Color(0xFF3A3A3C),
            Color(0xFF5A5A5E),
            Color(0xFF2A2A2C),
            Color(0xFF4A4A4E),
          ],
        ).createShader(rect),
    );

    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.03)
          ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.transparent,
            Colors.white.withOpacity(0.08),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SideBtn extends StatelessWidget {
  final double height;
  final bool isLeft;
  const _SideBtn({required this.height, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [Color(0xFF5A5A5C), Color(0xFF2C2C2E)],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  iOS Screen
// ══════════════════════════════════════════════════════════════════════════════

class _iOSScreen extends StatelessWidget {
  final Animation<double> fadeAnim;
  final _AlertInfo? alertInfo;
  final AnimationController? alertController;
  final VoidCallback? onDismissAlert;
  const _iOSScreen({
    required this.fadeAnim,
    this.alertInfo,
    this.alertController,
    this.onDismissAlert,
  });

  static final _gridApps = [
    _AppData(
      emoji: '📷',
      label: 'Camera',
      c1: const Color(0xFF555555),
      c2: const Color(0xFF222222),
    ),
    _AppData(
      emoji: '🗺️',
      label: 'Maps',
      c1: const Color(0xFF34C759),
      c2: const Color(0xFF158A3E),
    ),
    _AppData(
      emoji: '🎵',
      label: 'Music',
      c1: const Color(0xFFFF2D55),
      c2: const Color(0xFFAA0033),
    ),
    _AppData(
      emoji: '📅',
      label: 'Calendar',
      c1: const Color(0xFFFF3B30),
      c2: const Color(0xFFCC1100),
    ),
    _AppData(
      emoji: '⏰',
      label: 'Clock',
      c1: const Color(0xFF1C1C1E),
      c2: const Color(0xFF000000),
    ),
    _AppData(
      emoji: '🌤️',
      label: 'Weather',
      c1: const Color(0xFF007AFF),
      c2: const Color(0xFF0040CC),
    ),
    _AppData(
      emoji: '📝',
      label: 'Notes',
      c1: const Color(0xFFFFCC00),
      c2: const Color(0xFFCC9900),
    ),
    _AppData(
      emoji: '💊',
      label: 'Health',
      c1: const Color(0xFFFF2D55),
      c2: const Color(0xFFCC0033),
    ),
    _AppData(
      emoji: '🔥',
      label: 'Fire Detector',
      c1: const Color(0xFFFF5555),
      c2: const Color(0xFF990000),
      badge: '1',
      isMain: true,
    ),
    _AppData(
      emoji: '🎮',
      label: 'Games',
      c1: const Color(0xFF5856D6),
      c2: const Color(0xFF3634A3),
    ),
    _AppData(
      emoji: '🛒',
      label: 'Store',
      c1: const Color(0xFF007AFF),
      c2: const Color(0xFF0055BB),
    ),
    _AppData(
      emoji: '📦',
      label: 'Files',
      c1: const Color(0xFF007AFF),
      c2: const Color(0xFF004FBB),
    ),
    _AppData(
      emoji: '📸',
      label: 'Photos',
      c1: const Color(0xFFFF9500),
      c2: const Color(0xFFCC6600),
    ),
    _AppData(
      emoji: '🔒',
      label: 'Wallet',
      c1: const Color(0xFF1C1C1E),
      c2: const Color(0xFF000000),
    ),
    _AppData(
      emoji: '⚙️',
      label: 'Settings',
      c1: const Color(0xFF636366),
      c2: const Color(0xFF3A3A3C),
    ),
    _AppData(
      emoji: '🎙️',
      label: 'Podcast',
      c1: const Color(0xFF9B59B6),
      c2: const Color(0xFF6C3483),
    ),
  ];

  static final _dockApps = [
    _DockData(
      icon: Icons.phone_rounded,
      c1: const Color(0xFF34C759),
      c2: const Color(0xFF25A244),
    ),
    _DockData(
      icon: Icons.language_rounded,
      c1: const Color(0xFF007AFF),
      c2: const Color(0xFF0055CC),
    ),
    _DockData(
      icon: Icons.message_rounded,
      c1: const Color(0xFF34C759),
      c2: const Color(0xFF21A048),
    ),
    _DockData(
      icon: Icons.music_note_rounded,
      c1: const Color(0xFFFF2D55),
      c2: const Color(0xFFCC0033),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: IgnorePointer(child: _Wallpaper())),
        GestureDetector(
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (_) {},
          onVerticalDragEnd: (_) {},
          onHorizontalDragStart: (_) {},
          onHorizontalDragUpdate: (_) {},
          onHorizontalDragEnd: (_) {},
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              _StatusBar(),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 14,
                        left: 14,
                        right: 14,
                        bottom: 104,
                      ),
                      child: FadeTransition(
                        opacity: fadeAnim,
                        child: _AppGrid(apps: _gridApps),
                      ),
                    ),
                    Positioned(
                      bottom: 98,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PageDot(active: true),
                          const SizedBox(width: 5),
                          _PageDot(active: false),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      left: 12,
                      right: 12,
                      child: _Dock(items: _dockApps),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (alertInfo != null && alertController != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: alertController!,
              builder:
                  (_, child) => Transform.translate(
                    offset: Offset(0, (alertController!.value - 1.0) * 120),
                    child: child,
                  ),
              child: _NotificationBanner(
                info: alertInfo!,
                onDismiss: onDismissAlert ?? () {},
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  App Grid
// ══════════════════════════════════════════════════════════════════════════════

class _AppData {
  final String emoji;
  final String label;
  final Color c1, c2;
  final String? badge;
  final bool isMain;
  const _AppData({
    required this.emoji,
    required this.label,
    required this.c1,
    required this.c2,
    this.badge,
    this.isMain = false,
  });
}

class _AppGrid extends StatelessWidget {
  final List<_AppData> apps;
  const _AppGrid({required this.apps});

  @override
  Widget build(BuildContext context) {
    const int cols = 4;
    final rows = (apps.length / cols).ceil();
    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(cols, (col) {
              final idx = row * cols + col;
              if (idx >= apps.length) return const SizedBox(width: 58);
              return _GridIcon(
                data: apps[idx],
                animDelay: Duration(milliseconds: 35 * idx),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _GridIcon extends StatefulWidget {
  final _AppData data;
  final Duration animDelay;
  const _GridIcon({required this.data, required this.animDelay});

  @override
  State<_GridIcon> createState() => _GridIconState();
}

class _GridIconState extends State<_GridIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _scale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    Future.delayed(widget.animDelay, () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  final GlobalKey _iconKey = GlobalKey();

  void _onTap(BuildContext context) {
    if (widget.data.isMain) {
      HapticFeedback.mediumImpact();
      final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
      final screenSize = MediaQuery.of(context).size;
      Alignment originAlign = Alignment.center;
      if (box != null) {
        final pos = box.localToGlobal(Offset.zero);
        final cx = pos.dx + box.size.width / 2;
        final cy = pos.dy + box.size.height / 2;
        originAlign = Alignment(
          (cx / screenSize.width) * 2 - 1,
          (cy / screenSize.height) * 2 - 1,
        );
      }
      Navigator.of(context, rootNavigator: true).push(
        _IosIconZoomRoute(page: const _AppLaunchWrapper(), origin: originAlign),
      );
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            _onTap(context);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: SizedBox(
            width: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _pressed ? 0.86 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        key: _iconKey,
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [widget.data.c1, widget.data.c2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.data.c2.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 27,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(13),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.22),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                widget.data.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.data.badge != null)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0F2645),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.data.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.data.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Dock
// ══════════════════════════════════════════════════════════════════════════════

class _DockData {
  final IconData icon;
  final Color c1, c2;
  const _DockData({required this.icon, required this.c1, required this.c2});
}

class _Dock extends StatelessWidget {
  final List<_DockData> items;
  const _Dock({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((d) => _DockIcon(data: d)).toList(),
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  final _DockData data;
  const _DockIcon({required this.data});

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.data.c1, widget.data.c2],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.data.c2.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(widget.data.icon, color: Colors.white, size: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Fire Detector Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _FireDetectorSheet extends StatefulWidget {
  const _FireDetectorSheet();

  @override
  State<_FireDetectorSheet> createState() => _FireDetectorSheetState();
}

class _FireDetectorSheetState extends State<_FireDetectorSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  bool _isMonitoring = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1010), Color(0xFF1C1C1E)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedBuilder(
            animation: _pulse,
            builder:
                (_, __) => Transform.scale(
                  scale: _pulse.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20 * _pulse.value,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fire Detector',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _isMonitoring
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _isMonitoring
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isMonitoring ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isMonitoring ? 'กำลังตรวจสอบ...' : 'หยุดทำงาน',
                  style: TextStyle(
                    color: _isMonitoring ? Colors.green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCard(
                label: 'อุณหภูมิ',
                value: '28°C',
                icon: '🌡️',
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'ควัน',
                value: 'ปกติ',
                icon: '💨',
                color: Colors.blue,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'แจ้งเตือน',
                value: '1',
                icon: '🔔',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isMonitoring = !_isMonitoring);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _isMonitoring ? '⏸ หยุด' : '▶ เริ่ม',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    Navigator.of(context, rootNavigator: true).push(
                      _IosIconZoomRoute(
                        page: const _AppLaunchWrapper(),
                        origin: Alignment.center,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'เปิดแอป',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ปิด',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _Wallpaper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4, 1.0],
          colors: [Color(0xFF0F2645), Color(0xFF1A3A6E), Color(0xFF0A0A1A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: _GlowOrb(
              size: 260,
              color: const Color(0xFF1B6CA8),
              opacity: 0.35,
            ),
          ),
          Positioned(
            bottom: -40,
            right: -60,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF0A4A8A),
              opacity: 0.3,
            ),
          ),
          const _StarField(),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _StarPainter(math.Random(42))),
    );
  }
}

class _StarPainter extends CustomPainter {
  final math.Random rng;
  _StarPainter(this.rng);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.75;
      final r = rng.nextDouble() * 1.2 + 0.2;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.55 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '9:41',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ),
            Container(
              width: 88,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SignalBars(),
                  const SizedBox(width: 5),
                  const Icon(Icons.wifi_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  _BatteryWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heights = [5.0, 7.0, 9.5, 12.0];
    return SizedBox(
      height: 13,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          4,
          (i) => Container(
            width: 2.5,
            height: heights[i],
            margin: const EdgeInsets.only(right: 1.2),
            decoration: BoxDecoration(
              color: i < 3 ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(2.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF30D158),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        Container(
          width: 1.5,
          height: 5,
          margin: const EdgeInsets.only(left: 0.5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 16 : 5,
      height: 5,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  iOS App Open Animation Route
// ══════════════════════════════════════════════════════════════════════════════

class _IosIconZoomRoute extends PageRouteBuilder {
  final Widget page;
  final Alignment origin;

  _IosIconZoomRoute({required this.page, required this.origin})
    : super(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          final scale = Tween<double>(begin: 0.05, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              alignment: origin,
              child: child,
            ),
          );
        },
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  App Launch Wrapper
// ══════════════════════════════════════════════════════════════════════════════

class _AppLaunchWrapper extends StatelessWidget {
  const _AppLaunchWrapper();

  @override
  Widget build(BuildContext context) {
    return const Dashboard();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Alert Info Model
// ══════════════════════════════════════════════════════════════════════════════

class _AlertInfo {
  final int level;
  final String emoji, title, subtitle, tag;
  final Color color, bgColor;
  const _AlertInfo({
    required this.level,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.bgColor,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  Alert Popup Widget
// ══════════════════════════════════════════════════════════════════════════════

class _AlertPopup extends StatefulWidget {
  final _AlertInfo info;
  final VoidCallback onDismiss;
  const _AlertPopup({required this.info, required this.onDismiss});

  @override
  State<_AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<_AlertPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: info.color.withOpacity(0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: info.color.withOpacity(0.35),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Level indicator (2 บาร์) ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => Container(
                width: i < info.level ? 28 : 8,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      i < info.level
                          ? info.color
                          : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder:
                (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info.color.withOpacity(0.12),
                      border: Border.all(
                        color: info.color.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: info.color.withOpacity(0.3 * _pulseAnim.value),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        info.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: info.color.withOpacity(0.4)),
            ),
            child: Text(
              'LEVEL ${info.level} — ${info.tag}',
              style: TextStyle(
                color: info.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            info.title,
            style: TextStyle(
              color: info.color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [info.color, info.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: info.color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'รับทราบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Test Button Widget
// ══════════════════════════════════════════════════════════════════════════════

class _TestBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TestBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  iOS Notification Banner
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationBanner extends StatelessWidget {
  final _AlertInfo info;
  final VoidCallback onDismiss;
  const _NotificationBanner({required this.info, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! < 0) onDismiss();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 52, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: info.color.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: info.color.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [info.color, info.color.withOpacity(0.6)],
                ),
              ),
              child: Center(
                child: Text(info.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Fire Detector',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ตอนนี้',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.title,
                    style: TextStyle(
                      color: info.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    info.subtitle.replaceAll('\\n', ' '),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
