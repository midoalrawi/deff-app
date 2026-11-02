import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class Palette {
  final Color bg, card, chip, text, sub;
  final Color greenPanel, greenBtn, greenAccent;
  final Color redPanel, redBtn, redAccent;

  const Palette({
    required this.bg,
    required this.card,
    required this.chip,
    required this.text,
    required this.sub,
    required this.greenPanel,
    required this.greenBtn,
    required this.greenAccent,
    required this.redPanel,
    required this.redBtn,
    required this.redAccent,
  });

  static const dark = Palette(
    bg: Color(0xFF0F1318),
    card: Color(0xFF181E26),
    chip: Color(0xFF242C37),
    text: Color(0xFFEAF0F6),
    sub: Color(0xFF8B97A6),
    greenPanel: Color(0xFF13241D),
    greenBtn: Color(0xFF1D3A2E),
    greenAccent: Color(0xFF6FD6A8),
    redPanel: Color(0xFF2A171B),
    redBtn: Color(0xFF47232A),
    redAccent: Color(0xFFFF9A9A),
  );

  static const light = Palette(
    bg: Color(0xFFF3F5F8),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFE9EEF3),
    text: Color(0xFF1B2430),
    sub: Color(0xFF6B7788),
    greenPanel: Color(0xFFDDF3E8),
    greenBtn: Color(0xFFF5FCF8),
    greenAccent: Color(0xFF1E8A5C),
    redPanel: Color(0xFFFAE3E5),
    redBtn: Color(0xFFFFF6F6),
    redAccent: Color(0xFFC0444F),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int total = 0;
  List<int> history = [];
  bool dark = true;
  SharedPreferences? prefs;

  Palette get p => dark ? Palette.dark : Palette.light;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    prefs = sp;
    if (!mounted) return;
    setState(() {
      total = sp.getInt('total') ?? 0;
      dark = sp.getBool('dark') ?? true;
      history = (sp.getStringList('history') ?? [])
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toList();
    });
  }

  void _save() {
    prefs?.setInt('total', total);
    prefs?.setStringList('history', history.map((e) => e.toString()).toList());
  }

  void _change(int value) {
    HapticFeedback.lightImpact();
    setState(() {
      total += value;
      history.add(value);
      if (history.length > 50) history.removeAt(0);
    });
    _save();
  }

  void _undo() {
    if (history.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      total -= history.removeLast();
    });
    _save();
  }

  void _toggleTheme() {
    HapticFeedback.selectionClick();
    setState(() => dark = !dark);
    prefs?.setBool('dark', dark);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'تصفير المجموع؟',
            style: TextStyle(color: p.text, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'سيتم مسح المجموع وسجل الحركات.',
            style: TextStyle(color: p.sub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: TextStyle(color: p.sub)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'تصفير',
                style: TextStyle(
                  color: p.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      setState(() {
        total = 0;
        history = [];
      });
      _save();
    }
  }

  String _format(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return (n < 0 ? '-' : '') + buf.toString();
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: p.chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: 24,
            color: onTap == null ? p.sub.withAlpha(90) : p.text,
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'لا توجد حركات بعد',
          style: TextStyle(color: p.sub, fontSize: 14),
        ),
      );
    }
    final last = history.reversed.take(5).toList();
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: last.map((v) {
            final accent = v > 0 ? p.greenAccent : p.redAccent;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withAlpha(36),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${v > 0 ? '+' : ''}$v',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _header() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _iconBtn(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                _toggleTheme,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'المجموع',
                    style: TextStyle(
                      color: p.sub,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _iconBtn(
                Icons.undo_rounded,
                history.isEmpty ? null : _undo,
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.restart_alt_rounded, _reset),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: total.toDouble()),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _format(v.round()),
                    style: TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(height: 36, child: _chips()),
        ],
      ),
    );
  }

  Widget _panel(Color color, Widget a, Widget b) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _panel(
                p.greenPanel,
                PressButton(
                  label: '+250',
                  icon: Icons.trending_up_rounded,
                  fill: p.greenBtn,
                  accent: p.greenAccent,
                  onTap: () => _change(250),
                ),
                PressButton(
                  label: '+500',
                  icon: Icons.trending_up_rounded,
                  fill: p.greenBtn,
                  accent: p.greenAccent,
                  onTap: () => _change(500),
                ),
              ),
              const SizedBox(height: 12),
              _panel(
                p.redPanel,
                PressButton(
                  label: '-250',
                  icon: Icons.trending_down_rounded,
                  fill: p.redBtn,
                  accent: p.redAccent,
                  onTap: () => _change(-250),
                ),
                PressButton(
                  label: '-500',
                  icon: Icons.trending_down_rounded,
                  fill: p.redBtn,
                  accent: p.redAccent,
                  onTap: () => _change(-500),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class PressButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color fill;
  final Color accent;
  final VoidCallback onTap;

  const PressButton({
    super.key,
    required this.label,
    required this.icon,
    required this.fill,
    required this.accent,
    required this.onTap,
  });

  @override
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapUp: (_) => setState(() => down = false),
      onTapCancel: () => setState(() => down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.fill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: widget.accent.withAlpha(70), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.accent.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.accent, size: 30),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: widget.accent,
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
}
