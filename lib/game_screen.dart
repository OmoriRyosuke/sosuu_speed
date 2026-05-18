import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_settings.dart';
import 'strings.dart';
import 'game_utils.dart';

const String _interstitialAdUnitId = 'ca-app-pub-9623929703707876/3413193716';

enum CpuLevel { easy, normal, hard }

class DifficultyScreen extends StatelessWidget {
  final GameConfig? config;
  const DifficultyScreen({super.key, this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(S.selectDiff)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (config != null && !config!.isDefault) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00e676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00e676)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.tune, color: Color(0xFF00e676), size: 16),
                  const SizedBox(width: 6),
                  Text(config!.name, style: const TextStyle(color: Color(0xFF00e676), fontSize: 13)),
                ]),
              ),
            ],
            Text(S.chooseStrength, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 32),
            _DiffButton(label: S.diffEasy, sub: S.diffEasySub, color: const Color(0xFF00e676), onTap: () => _go(context, CpuLevel.easy)),
            const SizedBox(height: 14),
            _DiffButton(label: S.diffNormal, sub: S.diffNormalSub, color: const Color(0xFFffd700), onTap: () => _go(context, CpuLevel.normal)),
            const SizedBox(height: 14),
            _DiffButton(label: S.diffHard, sub: S.diffHardSub, color: const Color(0xFFff4444), onTap: () => _go(context, CpuLevel.hard)),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, CpuLevel level) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => GameScreen(cpuLevel: level, config: config)));
}

class _DiffButton extends StatelessWidget {
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _DiffButton({required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onTap,
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final CpuLevel cpuLevel;
  final GameConfig? config;
  const GameScreen({super.key, required this.cpuLevel, this.config});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Map<int, int> _defaultCards = {2: 5, 3: 4, 5: 3, 7: 3, 11: 3};
  static const Map<int, int> _hardCards = {2: 5, 3: 4, 5: 3, 7: 3, 11: 3, 13: 3, 17: 3};

  Map<int, int> get _cardCounts {
    final cfg = widget.config;
    if (cfg == null || cfg.isDefault) {
      return widget.cpuLevel == CpuLevel.hard ? _hardCards : _defaultCards;
    }
    return cfg.primeCards;
  }

  List<int> get _compositePool {
    final cfg = widget.config;
    if (cfg == null || cfg.isDefault) {
      switch (widget.cpuLevel) {
        case CpuLevel.easy: return compositeNumbers;
        case CpuLevel.normal: return compositeNumbersNormal;
        case CpuLevel.hard: return compositeNumbersHard;
      }
    }
    return cfg.composites ?? compositeNumbers;
  }

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

  void _loadAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _interstitialAd = ad; _adLoaded = true; },
        onAdFailedToLoad: (error) { _adLoaded = false; },
      ),
    );
  }

  void _showAdThenResult() {
    if (_adLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) { ad.dispose(); _navigateToResult(); },
        onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); _navigateToResult(); },
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
            MaterialPageRoute(builder: (_) => GameScreen(cpuLevel: widget.cpuLevel, config: widget.config)),
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
    _deck = List.from(_compositePool)..shuffle(_rng);
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
    _cardCounts.forEach((prime, count) {
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
      if (slots[slotSize - 1] == slots[slotSize - 2] && slots[slotSize - 2] == slots[slotSize - 3]) needDifferent = true;
    }
    if (slotSize == 4 && typesInSlot.length <= 2) needDifferent = true;
    if (needDifferent) {
      final different = deck.firstWhere((c) => !typesInSlot.contains(c), orElse: () => -1);
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
        setState(() { _readyGoText = ''; _acceptInput = true; _countDown = 10; });
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
      if (_countDown <= 0) { t.cancel(); _flushZone(); }
    });
  }

  void _flushZone() {
    _cpuTimer?.cancel();
    _countTimer?.cancel();
    _autoFlushTimer?.cancel();
    setState(() { _playZone = {}; _countDown = -1; _acceptInput = false; });
    Future.delayed(const Duration(seconds: 1), () { if (mounted) _drawComposite(); });
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
    if ((!_cpuHasPlayable() && !_playerHasPlayable()) || (_penaltyPlayer && !_cpuHasPlayable())) {
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
      setState(() { _penaltyMsg = S.penaltyMsg(prime); _penaltyPlayer = true; });
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
    if (_playerSlots.isEmpty && _playerDeck.isEmpty) { _endGame(playerWon: true); return; }
    if (_isComplete()) {
      Future.delayed(const Duration(seconds: 1), () { if (mounted) _flushZone(); });
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
    if (widget.cpuLevel == CpuLevel.easy && _rng.nextDouble() < 0.25) { _scheduleCpuMove(); return; }
    final playableIndices = <int>[];
    for (int i = 0; i < _cpuSlots.length; i++) {
      if (_canPlay(_cpuSlots[i])) playableIndices.add(i);
    }
    if (playableIndices.isEmpty) { _checkAutoFlush(); return; }
    final idx = playableIndices[_rng.nextInt(playableIndices.length)];
    final prime = _cpuSlots[idx];
    setState(() {
      _playZone[prime] ??= {};
      _playZone[prime]!['cpu'] = (_playZone[prime]!['cpu'] ?? 0) + 1;
      _cpuSlots.removeAt(idx);
    });
    _fillSlots(_cpuSlots, _cpuDeck);
    if (_cpuSlots.isEmpty && _cpuDeck.isEmpty) { _endGame(playerWon: false); return; }
    if (_isComplete()) {
      Future.delayed(const Duration(seconds: 1), () { if (mounted) _flushZone(); });
      return;
    }
    _scheduleCpuMove();
  }

  void _startCount() {
    if (_countDown <= 10) return;
    _countTimer?.cancel();
    setState(() { _countDown = 10; _penaltyPlayer = true; });
    _startAutoCount();
  }

  void _endGame({required bool playerWon}) {
    _cpuTimer?.cancel();
    _countTimer?.cancel();
    _autoFlushTimer?.cancel();
    setState(() { _gameOver = true; _playerWon = playerWon; });
    Future.delayed(const Duration(milliseconds: 300), _showAdThenResult);
  }

  String _cpuLevelName() {
    switch (widget.cpuLevel) {
      case CpuLevel.easy:   return AppSettings.instance.isEnglish ? 'Easy' : 'かんたん';
      case CpuLevel.normal: return AppSettings.instance.isEnglish ? 'Normal' : 'ふつう';
      case CpuLevel.hard:   return AppSettings.instance.isEnglish ? 'Hard' : 'むずかしい';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return const Scaffold(
      backgroundColor: Color(0xFF0a1628),
      body: Center(child: CircularProgressIndicator(color: Colors.white)));
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a1628),
        foregroundColor: Colors.white,
        toolbarHeight: isSmall ? 40 : kToolbarHeight,
        title: Text(S.cpuBattleTitle, style: TextStyle(fontSize: isSmall ? 14 : 18)),
        actions: [
          TextButton.icon(
            onPressed: _startCount,
            icon: Icon(Icons.timer, color: Colors.orange, size: isSmall ? 16 : 24),
            label: Text(_countDown > 0 ? '$_countDown' : S.countLabel,
                style: TextStyle(color: Colors.orange, fontSize: isSmall ? 12 : 14)),
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
        Text('CPU（${_cpuLevelName()}）', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
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
          Text(S.questionCard, style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 12)),
          SizedBox(height: isSmall ? 2 : 4),
          if (_countDown > 0) ...[
            Text('$_countDown', style: TextStyle(fontSize: isSmall ? 36 : 48, fontWeight: FontWeight.w900, color: Colors.orange)),
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
                  border: Border.all(color: _readyGoText.isNotEmpty ? Colors.white24 : Colors.white54, width: 2),
                ),
                child: Center(
                  child: _readyGoText.isNotEmpty ? const SizedBox.shrink()
                      : Text(_currentComposite != null ? '$_currentComposite' : '',
                          style: TextStyle(color: Colors.white, fontSize: numSize, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_readyGoText.isNotEmpty)
                SizedBox(width: cardW - 10,
                  child: FittedBox(fit: BoxFit.scaleDown,
                    child: Text(_readyGoText, maxLines: 1,
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900,
                        color: _readyGoText == 'GO!' ? const Color(0xFF00e676) : const Color(0xFFffd700),
                        letterSpacing: 1)))),
            ]),
          ),
          SizedBox(height: vGap),
          Row(children: [
            Icon(Icons.smart_toy, color: Colors.redAccent, size: isSmall ? 11 : 14),
            const SizedBox(width: 4),
            Text('${S.cpuHandLabel}  ${AppSettings.instance.isEnglish ? "Deck:" : "山:"} ${_cpuDeck.length}${AppSettings.instance.isEnglish ? "" : "枚"}',
                style: TextStyle(color: Colors.white38, fontSize: isSmall ? 9 : 11)),
          ]),
          SizedBox(height: isSmall ? 2 : 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: List.generate(_cpuSlots.length,
                (i) => _buildCard(_cpuSlots[i], owner: 'cpu', small: true, isSmall: isSmall))),
          ),
          SizedBox(height: vGap),
          Text(S.playZone, style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 12)),
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
                ? Center(child: Text(S.playZoneHint, style: TextStyle(color: Colors.white24, fontSize: isSmall ? 10 : 12)))
                : Wrap(
                    spacing: 4, runSpacing: 4, alignment: WrapAlignment.center,
                    children: [
                      for (final e in _playZone.entries) ...[
                        for (int i = 0; i < (e.value['player'] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'player', isSmall: isSmall),
                        for (int i = 0; i < (e.value['cpu'] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'cpu', isSmall: isSmall),
                      ],
                    ]),
          ),
          if (_penaltyMsg.isNotEmpty) ...[
            SizedBox(height: isSmall ? 4 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(_penaltyMsg, style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 11 : 13)),
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
            Text('${S.youLabel}  ${AppSettings.instance.isEnglish ? "Deck:" : "山:"} ${_playerDeck.length}${AppSettings.instance.isEnglish ? "" : "枚"}',
                style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
            if (_penaltyPlayer)
              Padding(padding: const EdgeInsets.only(left: 8),
                child: Text(S.penaltyActive, style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 10 : 12))),
          ]),
          SizedBox(height: isSmall ? 4 : 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_playerSlots.length, (i) {
                final tappable = !_penaltyPlayer && _acceptInput;
                return GestureDetector(
                  onTap: tappable ? () => _playerPlayCard(i) : null,
                  child: _buildCard(_playerSlots[i], owner: 'hand', isSmall: isSmall),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int? prime, {bool faceDown = false, bool small = false, String? owner, bool isSmall = false}) {
    final w = small ? (isSmall ? 34.0 : 44.0) : (isSmall ? 50.0 : 60.0);
    final h = small ? (isSmall ? 44.0 : 56.0) : (isSmall ? 64.0 : 76.0);
    final fontSize = small ? (isSmall ? 14.0 : 18.0) : (isSmall ? 20.0 : 24.0);
    Color borderColor, bgColor, textColor;
    if (faceDown) {
      borderColor = Colors.white24; bgColor = const Color(0xFF1a1a2e); textColor = Colors.white24;
    } else if (owner == 'player' || owner == 'hand') {
      borderColor = const Color(0xFF00d4ff); bgColor = const Color(0xFF00d4ff).withValues(alpha: 0.15); textColor = const Color(0xFF00d4ff);
    } else if (owner == 'cpu') {
      borderColor = const Color(0xFFff4444); bgColor = const Color(0xFFff4444).withValues(alpha: 0.15); textColor = const Color(0xFFff4444);
    } else {
      borderColor = Colors.white38; bgColor = const Color(0xFF1a2a3a); textColor = Colors.white;
    }
    return Container(
      width: w, height: h, margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: faceDown
            ? const Icon(Icons.question_mark, color: Colors.white24, size: 20)
            : Text('$prime', style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

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
            Text(playerWon ? S.youWin : S.cpuWin,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                  color: playerWon ? const Color(0xFFffd700) : Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onRetry,
              child: Text(S.retry, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTitle,
              child: Text(S.toTitle, style: const TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text(S.howToTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _RuleItem(num: '1', title: S.r1t, body: S.r1b),
          _RuleItem(num: '2', title: S.r2t, body: S.r2b),
          _RuleItem(num: '3', title: S.r3t, body: S.r3b),
          _RuleItem(num: '4', title: S.r4t, body: S.r4b),
          _RuleItem(num: '5', title: S.r5t, body: S.r5b),
          _RuleItem(num: '6', title: S.r6t, body: S.r6b),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Color(0xFF00d4ff), shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFFffd700), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
        ])),
      ]),
    );
  }
}
