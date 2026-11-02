import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int total = 0;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();
    setState(() => total = prefs?.getInt('total') ?? 0);
  }

  void _change(int value) {
    setState(() => total += value);
    prefs?.setInt('total', total);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير المجموع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => total = 0);
      prefs?.setInt('total', 0);
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

  Widget _btn(String label, int value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox.expand(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _change(value),
            child: Text(
              label,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      _format(total),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, size: 30),
                        onPressed: _reset,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFB9F6CA),
                  child: Row(
                    children: [
                      _btn('+250', 250, const Color(0xFF2E7D32)),
                      _btn('+500', 500, const Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFFFCDD2),
                  child: Row(
                    children: [
                      _btn('-250', -250, const Color(0xFFC62828)),
                      _btn('-500', -500, const Color(0xFFC62828)),
                    ],
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
