import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'online_game.dart';
import 'app_settings.dart';
import 'strings.dart';
import 'create_mode_screen.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) await MobileAds.instance.initialize();
  await AppSettings.instance.load();
  runApp(const SosuuSpeedApp());
}

class SosuuSpeedApp extends StatelessWidget {
  const SosuuSpeedApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '素数スピード',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a3a6e)),
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  Future<void> _setLang(bool english) async {
    await AppSettings.instance.setLanguage(english);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppSettings.instance.isEnglish;
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.appTitle,
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2)),
            Text(S.appSubtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 52),
            _MenuButton(
              label: S.btnCpu,
              color: const Color(0xFF00d4ff),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DifficultyScreen())),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              label: S.btnOnline,
              color: const Color(0xFF7c4dff),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OnlineMenuScreen())),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              label: S.btnCreate,
              color: const Color(0xFF00e676),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateModeScreen())),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              label: S.btnHowTo,
              color: Colors.white24,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HowToScreen())),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LangButton(label: '日本語', active: !isEn, onTap: () => _setLang(false)),
                const SizedBox(width: 12),
                _LangButton(label: 'English', active: isEn, onTap: () => _setLang(true)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFffd700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c : Colors.white24, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? c : Colors.white38,
                fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
