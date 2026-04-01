import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'online_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();
  runApp(const SosuuSpeedApp());
}

// ── 広告ユニットID ────────────────────────────
const String _interstitialAdUnitId = 'ca-app-pub-9623929703707876/3413193716';

// ── 素因数分解 ────────────────────────────────
Map<int, int> factorize(int n) {
  final result = <int, int>{};
  for (int d = 2; d * d <= n; d++) {
    while (n % d == 0) {
      result[d] = (result[d] ?? 0) + 1;
      n ~/= d;
    }
  }
  if (n > 1) result[n] = (result[n] ?? 0) + 1;
  return result;
}

// ── 合成数リスト ──────────────────────────────
const List<int> compositeNumbers = [
  8, 16, 14, 22,
  9, 27, 21, 33,
  25, 35, 55, 65, 50,
  49, 77, 98,
  121, 66, 99, 44,
  6, 10, 12, 15, 18, 20, 28, 45, 63,
];

const List<int> compositeNumbersNormal = [
  8, 16, 14, 22,
  9, 27, 21, 33,
  25, 35, 55, 65, 50,
  49, 77, 98,
  121, 66, 99, 44,
  6, 10, 12, 15, 18, 20, 28, 45, 63,
  539, 245, 605,
];

const List<int> compositeNumbersHard = [
  8, 16, 14, 22,
  9, 27, 21, 33,
  25, 35, 55, 65, 50,
  49, 77, 98,
  121, 66, 99, 44,
  6, 10, 12, 15, 18, 20, 28, 45, 63,
  26, 39, 52, 169,
  34, 51, 68, 289,
  221, 39, 51, 91, 119,
];

// ── アプリ ────────────────────────────────────
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

// ── タイトル ──────────────────────────────────
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('素数スピード',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2)),
            const Text('Prime Number Speed',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 60),
            _MenuButton(
              label: '🤖  CPU戦',
              color: const Color(0xFF00d4ff),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DifficultyScreen())),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: '👥  対人戦',
              color: const Color(0xFF7c4dff),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OnlineMenuScreen())),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: '📖  遊び方',
              color: Colors.white24,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HowToScreen())),
            ),
          ],
        ),
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
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── 難易度選択 ────────────────────────────────
enum CpuLevel { easy, normal, hard }

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('難易度選択')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CPUの強さを選んでください',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            _DiffButton(
                label: '😊  かんたん',
                sub: 'CPUがゆっくり・たまに間違える',
                color: const Color(0xFF00e676),
                onTap: () => _go(context, CpuLevel.easy)),
            const SizedBox(height: 16),
            _DiffButton(
                label: '😐  ふつう',
                sub: 'CPUがそこそこ速い',
                color: const Color(0xFFffd700),
                onTap: () => _go(context, CpuLevel.normal)),
            const SizedBox(height: 16),
            _DiffButton(
                label: '😈  むずかしい',
                sub: 'CPUが超高速・ほぼ完璧',
                color: const Color(0xFFff4444),
                onTap: () => _go(context, CpuLevel.hard)),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, CpuLevel level) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => GameScreen(cpuLevel: level)));
}

class _DiffButton extends StatelessWidget {
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _DiffButton(
      {required this.label,
      required this.sub,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onTap,
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub,
              style:
                  TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
        ]),
      ),
    );
  }
}

// ── ゲーム画面 ────────────────────────────────
class GameScreen extends StatefulWidget {
  final CpuLevel cpuLevel;
  const GameScreen({super.key, required this.cpuLevel});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Map<int, int> _cardCounts = {2: 5, 3: 4, 5: 3, 7: 3, 11: 3};
  static const Map<int, int> _cardCountsHard = {
    2: 5, 3: 4, 5: 3, 7: 3, 11: 3, 13: 3, 17: 3
  };

  Map<int, int> get _currentCardCounts =>
      widget.cpuLevel == CpuLevel.hard ? _cardCountsHard : _cardCounts;

  late List<int> _playerDeck;
  late List<int> _cpuDeck;
  late List<int> _playerSlots;
  late List<int> _cpuSlots;
  late List<int> _deck;
  int? _currentComposite;
  Map<int, int> _targetFactors = {};
  Map<int, Map<String, int>> _playZone = {};

  bool _gameOver = false;
  bool _playerWon = false;
  bool _penaltyPlayer = false;
  bool _acceptInput = false;

  String _readyGoText = '';
  String _penaltyMsg = '';

  Timer? _countTimer;
  int _countDown = -1;
  Timer? _cpuTimer;
  Timer? _autoFlushTimer;
  final _rng = Random();

  // 広告
  InterstitialAd? _interstitialAd;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    _initGame();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _cpuTimer?.cancel();
    _autoFlushTimer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // ── 広告読み込み ──────────────────────────
  void _loadAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _adLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _adLoaded = false;
        },
      ),
    );
  }

  // ── 広告表示してから結果画面へ ────────────
  void _showAdThenResult() {
    if (_adLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _navigateToResult();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _navigateToResult();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _adLoaded = false;
    } else {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultScreen(
          playerWon: _playerWon,
          onRetry: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(cpuLevel: widget.cpuLevel)),
          ),
          onTitle: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
    );
  }

  void _initGame() {
    _playerDeck = _buildDeck();
    _cpuDeck = _buildDeck();
    _playerSlots = [];
    _cpuSlots = [];
    _fillSlots(_playerSlots, _playerDeck);
    _fillSlots(_cpuSlots, _cpuDeck);

    final src = widget.cpuLevel == CpuLevel.hard
        ? compositeNumbersHard
        : widget.cpuLevel == CpuLevel.normal
            ? compositeNumbersNormal
            : compositeNumbers;
    _deck = List.from(src)..shuffle(_rng);

    _playZone = {};
    _gameOver = false;
    _playerWon = false;
    _penaltyPlayer = false;
    _acceptInput = false;
    _readyGoText = '';
    _penaltyMsg = '';
    _countDown = -1;

    _drawComposite();
  }

  List<int> _buildDeck() {
    final deck = <int>[];
    _currentCardCounts.forEach((prime, count) {
      for (int i = 0; i < count; i++) deck.add(prime);
    });
    deck.shuffle(_rng);
    return deck;
  }

  void _fillSlots(List<int> slots, List<int> deck) {
    while (slots.length < 5 && deck.isNotEmpty) {
      int? next = _pickNextCard(slots, deck);
      if (next == null) break;
      deck.remove(next);
      slots.add(next);
    }
  }

  int? _pickNextCard(List<int> slots, List<int> deck) {
    if (deck.isEmpty) return null;
    final Set<int> typesInSlot = slots.toSet();
    final int slotSize = slots.length;
    bool needDifferent = false;
    if (slotSize >= 3) {
      if (slots[slotSize - 1] == slots[slotSize - 2] &&
          slots[slotSize - 2] == slots[slotSize - 3]) {
        needDifferent = true;
      }
    }
    if (slotSize == 4 && typesInSlot.length <= 2) needDifferent = true;
    if (needDifferent) {
      final different =
          deck.firstWhere((c) => !typesInSlot.contains(c), orElse: () => -1);
      if (different != -1) return different;
    }
    return deck.first;
  }

  void _drawComposite() {
    if (_deck.isEmpty) {
      setState(() { _gameOver = true; _playerWon = false; });
      Future.delayed(const Duration(milliseconds: 300), _showAdThenResult);
      return;
    }
    final card = _deck.removeLast();
    _currentComposite = card;
    _targetFactors = factorize(card);
    _playZone = {};
    _penaltyPlayer = false;
    _acceptInput = false;
    _penaltyMsg = '';
    _countDown = -1;

    setState(() => _readyGoText = 'READY');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _readyGoText = 'GO!');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _readyGoText = '';
          _acceptInput = true;
          _countDown = 10;
        });
        _startAutoCount();
        _scheduleCpuMove();
      });
    });
  }

  void _startAutoCount() {
    _countTimer?.cancel();
    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countDown--);
      if (_countDown <= 0) {
        t.cancel();
        _flushZone();
      }
    });
  }

  void _flushZone() {
    _cpuTimer?.cancel();
    _countTimer?.cancel();
    _autoFlushTimer?.cancel();
    setState(() {
      _playZone = {};
      _countDown = -1;
      _acceptInput = false;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _drawComposite();
    });
  }

  bool _isComplete() {
    for (final e in _targetFactors.entries) {
      if (_playZoneTotal(e.key) < e.value) return false;
    }
    return true;
  }

  int _playZoneTotal(int prime) {
    final m = _playZone[prime];
    if (m == null) return 0;
    return (m['player'] ?? 0) + (m['cpu'] ?? 0);
  }

  bool _canPlay(int prime) {
    final needed = _targetFactors[prime] ?? 0;
    if (needed == 0) return false;
    return _playZoneTotal(prime) < needed;
  }

  bool _cpuHasPlayable() => _cpuSlots.any((p) => _canPlay(p));
  bool _playerHasPlayable() => _playerSlots.any((p) => _canPlay(p));

  void _checkAutoFlush() {
    if (_gameOver || !_acceptInput) return;
    if ((!_cpuHasPlayable() && !_playerHasPlayable()) ||
        (_penaltyPlayer && !_cpuHasPlayable())) {
      _autoFlushTimer?.cancel();
      _autoFlushTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted && !_gameOver) _flushZone();
      });
    }
  }

  void _playerPlayCard(int slotIndex) {
    if (_gameOver || !_acceptInput || _penaltyPlayer) return;
    final prime = _playerSlots[slotIndex];

    if (!_canPlay(prime)) {
      setState(() {
        _penaltyMsg = 'お手つき！ $prime は出せません';
        _penaltyPlayer = true;
      });
      _checkAutoFlush();
      return;
    }

    setState(() {
      _playZone[prime] ??= {};
      _playZone[prime]!['player'] = (_playZone[prime]!['player'] ?? 0) + 1;
      _penaltyMsg = '';
      if (_playerDeck.isNotEmpty) {
        _playerSlots[slotIndex] = _playerDeck.removeAt(0);
      } else {
        _playerSlots.removeAt(slotIndex);
      }
    });

    if (_playerSlots.isEmpty && _playerDeck.isEmpty) {
      _endGame(playerWon: true);
      return;
    }

    if (_isComplete()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _flushZone();
      });
    }
  }

  void _scheduleCpuMove() {
    _cpuTimer?.cancel();
    int delayMs;
    switch (widget.cpuLevel) {
      case CpuLevel.easy:   delayMs = 2500 + _rng.nextInt(2000); break;
      case CpuLevel.normal: delayMs = 1000 + _rng.nextInt(1000); break;
      case CpuLevel.hard:   delayMs = 300  + _rng.nextInt(400);  break;
    }
    _cpuTimer = Timer(Duration(milliseconds: delayMs), _cpuPlay);
  }

  void _cpuPlay() {
    if (_gameOver || !_acceptInput) return;
    if (widget.cpuLevel == CpuLevel.easy && _rng.nextDouble() < 0.25) {
      _scheduleCpuMove();
      return;
    }

    final playableIndices = <int>[];
    for (int i = 0; i < _cpuSlots.length; i++) {
      if (_canPlay(_cpuSlots[i])) playableIndices.add(i);
    }

    if (playableIndices.isEmpty) {
      _checkAutoFlush();
      return;
    }

    final idx = playableIndices[_rng.nextInt(playableIndices.length)];
    final prime = _cpuSlots[idx];

    setState(() {
      _playZone[prime] ??= {};
      _playZone[prime]!['cpu'] = (_playZone[prime]!['cpu'] ?? 0) + 1;
      _cpuSlots.removeAt(idx);
    });

    _fillSlots(_cpuSlots, _cpuDeck);

    if (_cpuSlots.isEmpty && _cpuDeck.isEmpty) {
      _endGame(playerWon: false);
      return;
    }

    if (_isComplete()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _flushZone();
      });
      return;
    }

    _scheduleCpuMove();
  }

  void _startCount() {
    if (_countDown <= 10) return;
    _countTimer?.cancel();
    setState(() {
      _countDown = 10;
      _penaltyPlayer = true;
    });
    _startAutoCount();
  }

  void _endGame({required bool playerWon}) {
    _cpuTimer?.cancel();
    _countTimer?.cancel();
    _autoFlushTimer?.cancel();
    setState(() {
      _gameOver = true;
      _playerWon = playerWon;
    });
    Future.delayed(const Duration(milliseconds: 300), _showAdThenResult);
  }

  String _cpuLevelName() {
    switch (widget.cpuLevel) {
      case CpuLevel.easy:   return 'かんたん';
      case CpuLevel.normal: return 'ふつう';
      case CpuLevel.hard:   return 'むずかしい';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return const Scaffold(backgroundColor: Color(0xFF0a1628),
      body: Center(child: CircularProgressIndicator(color: Colors.white)));
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a1628),
        foregroundColor: Colors.white,
        toolbarHeight: isSmall ? 40 : kToolbarHeight,
        title: Text('CPU戦', style: TextStyle(fontSize: isSmall ? 14 : 18)),
        actions: [
          TextButton.icon(
            onPressed: _startCount,
            icon: Icon(Icons.timer, color: Colors.orange, size: isSmall ? 16 : 24),
            label: Text(
              _countDown > 0 ? '$_countDown' : '10カウント',
              style: TextStyle(color: Colors.orange, fontSize: isSmall ? 12 : 14),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCpuArea(isSmall: isSmall),
          const Divider(color: Colors.white12, height: 1),
          Expanded(child: _buildCenterArea(isSmall: isSmall)),
          const Divider(color: Colors.white12, height: 1),
          _buildPlayerArea(isSmall: isSmall),
        ],
      ),
    );
  }

  Widget _buildCpuArea({bool isSmall = false}) {
    return Container(
      color: const Color(0xFF0d1f3c),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 4 : 8),
      child: Row(children: [
        Icon(Icons.smart_toy, color: Colors.redAccent, size: isSmall ? 14 : 18),
        const SizedBox(width: 6),
        Text('CPU（${_cpuLevelName()}）',
            style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
      ]),
    );
  }

  Widget _buildCenterArea({bool isSmall = false}) {
    final cardW = isSmall ? 90.0 : 120.0;
    final cardH = isSmall ? 100.0 : 140.0;
    final numSize = isSmall ? 34.0 : 44.0;
    final vGap = isSmall ? 4.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 4 : 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('題札', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 12)),
          SizedBox(height: isSmall ? 2 : 4),
          if (_countDown > 0) ...[
            Text('$_countDown',
                style: TextStyle(fontSize: isSmall ? 36 : 48,
                    fontWeight: FontWeight.w900, color: Colors.orange)),
            SizedBox(height: isSmall ? 2 : 4),
          ],
          SizedBox(
            width: cardW, height: cardH,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: cardW, height: cardH,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _readyGoText.isNotEmpty ? Colors.white24 : Colors.white54,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _readyGoText.isNotEmpty
                      ? const SizedBox.shrink()
                      : Text(_currentComposite != null ? '$_currentComposite' : '',
                          style: TextStyle(color: Colors.white, fontSize: numSize, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_readyGoText.isNotEmpty)
                SizedBox(
                  width: cardW - 10,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_readyGoText, maxLines: 1,
                      style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w900,
                        color: _readyGoText == 'GO!' ? const Color(0xFF00e676) : const Color(0xFFffd700),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          SizedBox(height: vGap),
          Row(children: [
            Icon(Icons.smart_toy, color: Colors.redAccent, size: isSmall ? 11 : 14),
            const SizedBox(width: 4),
            Text('CPU場札  山: ${_cpuDeck.length}枚',
                style: TextStyle(color: Colors.white38, fontSize: isSmall ? 9 : 11)),
          ]),
          SizedBox(height: isSmall ? 2 : 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_cpuSlots.length, (i) =>
                  _buildCard(_cpuSlots[i], owner: 'cpu', small: true, isSmall: isSmall)),
            ),
          ),
          SizedBox(height: vGap),
          Text('プレイゾーン', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 12)),
          SizedBox(height: isSmall ? 2 : 4),
          Container(
            constraints: BoxConstraints(minHeight: isSmall ? 52 : 72),
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _playZone.isEmpty
                ? Center(child: Text('カードを出す場所',
                    style: TextStyle(color: Colors.white24, fontSize: isSmall ? 10 : 12)))
                : Wrap(
                    spacing: 4, runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final e in _playZone.entries) ...[
                        for (int i = 0; i < (e.value['player'] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'player', isSmall: isSmall),
                        for (int i = 0; i < (e.value['cpu'] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'cpu', isSmall: isSmall),
                      ],
                    ],
                  ),
          ),
          if (_penaltyMsg.isNotEmpty) ...[
            SizedBox(height: isSmall ? 4 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_penaltyMsg,
                  style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 11 : 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerArea({bool isSmall = false}) {
    return Container(
      color: const Color(0xFF0d1f3c),
      padding: EdgeInsets.fromLTRB(16, isSmall ? 6 : 14, 16, isSmall ? 6 : 10),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.person, color: const Color(0xFF00d4ff), size: isSmall ? 14 : 18),
            const SizedBox(width: 6),
            Text('あなた  山: ${_playerDeck.length}枚',
                style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
            if (_penaltyPlayer)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('⚠ お手つき中',
                    style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 10 : 12)),
              ),
          ]),
          SizedBox(height: isSmall ? 4 : 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_playerSlots.length, (i) {
                final prime = _playerSlots[i];
                final tappable = !_penaltyPlayer && _acceptInput;
                return GestureDetector(
                  onTap: tappable ? () => _playerPlayCard(i) : null,
                  child: _buildCard(prime, owner: 'hand', isSmall: isSmall),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int? prime,
      {bool faceDown = false, bool small = false, String? owner, bool isSmall = false}) {
    final w = small ? (isSmall ? 34.0 : 44.0) : (isSmall ? 50.0 : 60.0);
    final h = small ? (isSmall ? 44.0 : 56.0) : (isSmall ? 64.0 : 76.0);
    final fontSize = small ? (isSmall ? 14.0 : 18.0) : (isSmall ? 20.0 : 24.0);
    Color borderColor, bgColor, textColor;
    if (faceDown) {
      borderColor = Colors.white24; bgColor = const Color(0xFF1a1a2e); textColor = Colors.white24;
    } else if (owner == 'player') {
      borderColor = const Color(0xFF00d4ff); bgColor = const Color(0xFF00d4ff).withOpacity(0.15); textColor = const Color(0xFF00d4ff);
    } else if (owner == 'cpu') {
      borderColor = const Color(0xFFff4444); bgColor = const Color(0xFFff4444).withOpacity(0.15); textColor = const Color(0xFFff4444);
    } else {
      borderColor = Colors.white38; bgColor = const Color(0xFF1a2a3a); textColor = Colors.white;
    }
    return Container(
      width: w, height: h,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: faceDown
            ? const Icon(Icons.question_mark, color: Colors.white24, size: 20)
            : Text('$prime',
                style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── 結果画面（独立Widget）────────────────────
class _ResultScreen extends StatelessWidget {
  final bool playerWon;
  final VoidCallback onRetry;
  final VoidCallback onTitle;
  const _ResultScreen({required this.playerWon, required this.onRetry, required this.onTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(playerWon ? '🏆' : '😢', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              playerWon ? 'あなたの勝ち！' : 'CPUの勝ち...',
              style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold,
                  color: playerWon ? const Color(0xFFffd700) : Colors.white54),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00d4ff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onRetry,
              child: const Text('もう一度', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTitle,
              child: const Text('タイトルへ', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 遊び方 ────────────────────────────────────
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('遊び方')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _RuleItem(num: '1', title: '目的',
              body: '場札の素数カードを使い切ること！先に使い切った人の勝ちです。'),
          _RuleItem(num: '2', title: '題札（合成数）',
              body: '中央に表示される合成数を素因数分解して、その素因数カードを場から出します。'),
          _RuleItem(num: '3', title: 'カードの出し方',
              body: '場札の素数カードをタップして出します。素因数として含まれているカードだけ出せます。カードは 2,3,5,7,11の5種類ですがCPU戦のむずかしいのみ13がはいっています。'),
          _RuleItem(num: '4', title: 'お手つき',
              body: '素因数でないカードを出すとお手つきです。お互いお手つきになると次の合成数が出現します。'),
          _RuleItem(num: '5', title: '10カウント',
              body: 'CPU戦では10カウント以内にカードを出さないと場が流れます。対人戦にはカウントはありません。'),
          _RuleItem(num: '6', title: 'カードの消費',
              body: '出したカードは場が流れても戻りません。山札から新しいカードが補充されます。'),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String num, title, body;
  const _RuleItem({required this.num, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Color(0xFF00d4ff), shape: BoxShape.circle),
            child: Center(child: Text(num,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: Color(0xFFffd700), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}