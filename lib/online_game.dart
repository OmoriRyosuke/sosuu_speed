import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'main.dart' show factorize, compositeNumbers;

const String _interstitialAdUnitId = 'ca-app-pub-9623929703707876/3413193716';

class OnlineMenuScreen extends StatelessWidget {
  const OnlineMenuScreen({super.key});

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final roomController = TextEditingController();
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('対人戦'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👥', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              SizedBox(
                width: 280, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final roomId = _generateRoomId();
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => WaitingRoomScreen(roomId: roomId, isHost: true),
                    ));
                  },
                  child: const Text('ルームを作る', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
              const Text('または', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 32),
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: roomController,
                  style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    hintText: 'ルームID',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (v) {
                    final up = v.toUpperCase();
                    roomController.value = roomController.value.copyWith(
                      text: up,
                      selection: TextSelection.collapsed(offset: up.length),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 280, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final id = roomController.text.trim().toUpperCase();
                    if (id.length != 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('5文字のルームIDを入力してください')));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => WaitingRoomScreen(roomId: id, isHost: false),
                    ));
                  },
                  child: const Text('ルームに参加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  const WaitingRoomScreen({super.key, required this.roomId, required this.isHost});
  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final _db = FirebaseDatabase.instance;
  StreamSubscription? _sub;
  bool _guestJoined = false;
  bool _navigated = false;
  bool _starting = false;

  DatabaseReference get _roomRef => _db.ref('rooms/${widget.roomId}');

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    if (widget.isHost) {
      await _roomRef.set({
        'status': 'waiting',
        'host': 'ready',
        'guest': null,
        'seed': null,
        'deck': null,
        'game': null,
        'createdAt': ServerValue.timestamp,
      });
      _sub = _roomRef.child('guest').onValue.listen((event) {
        final val = event.snapshot.value;
        if (val != null && mounted && !_navigated && !_guestJoined) {
          setState(() => _guestJoined = true);
        }
      });
    } else {
      final snap = await _roomRef.get();
      if (!snap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ルームが見つかりません')));
          Navigator.pop(context);
        }
        return;
      }
      final data = snap.value as Map<dynamic, dynamic>?;
      if ((data?['status'] as String?) != 'waiting') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('このルームは開始済みです')));
          Navigator.pop(context);
        }
        return;
      }
      await _roomRef.child('guest').set('ready');
      _sub = _roomRef.child('status').onValue.listen((event) {
        if (event.snapshot.value == 'playing' && !_navigated) _startGame();
      });
    }
  }

  void _startGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => OnlineGameScreen(roomId: widget.roomId, isHost: widget.isHost),
    ));
  }

  Future<void> _onStartPressed() async {
    if (!_guestJoined || _starting) return;
    setState(() => _starting = true);

    final rng = Random();
    final seed = rng.nextInt(999999);
    final deck = List.from(compositeNumbers)..shuffle(Random(seed));
    final deckList = deck.cast<int>().toList();

    try {
      await _roomRef.update({'status': 'playing', 'seed': seed, 'deck': deckList});
      await _roomRef.child('game').set({
        'phase': 'init',
        'composite': null,
        'deckPos': 0,
        'playZone': {'_x': 0},
      });
      _startGame();
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('開始に失敗しました: $e')));
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String get _url => 'https://sosuu-speed-2826a.web.app/?room=${widget.roomId}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('待機中...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ルームID', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(widget.roomId,
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 8)),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.roomId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('コピーしました！')));
              },
              icon: const Icon(Icons.copy, color: Colors.white38, size: 14),
              label: const Text('コピー', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: _url, version: QrVersions.auto, size: 160),
            ),
            const SizedBox(height: 8),
            const Text('QRコードを読ませて招待', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 28),
            if (widget.isHost) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _guestJoined ? Icons.check_circle : Icons.hourglass_empty,
                    color: _guestJoined ? const Color(0xFF00e676) : Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _guestJoined ? '相手が参加しました！' : '相手の参加を待っています...',
                    style: TextStyle(color: _guestJoined ? const Color(0xFF00e676) : Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: (_guestJoined && !_starting) ? _onStartPressed : null,
                child: Container(
                  width: 200, height: 52,
                  decoration: BoxDecoration(
                    color: _guestJoined ? const Color(0xFF00d4ff) : Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _starting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ゲームスタート！',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ] else ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                  SizedBox(width: 8),
                  Text('ホストのスタートを待っています...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  const OnlineGameScreen({super.key, required this.roomId, required this.isHost});
  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  static const Map<int, int> _cardCounts = {2: 5, 3: 4, 5: 3, 7: 3, 11: 3};

  final _db = FirebaseDatabase.instance;
  StreamSubscription? _roomSub;

  DatabaseReference get _roomRef => _db.ref('rooms/${widget.roomId}');
  DatabaseReference get _gameRef => _db.ref('rooms/${widget.roomId}/game');

  String get _myKey => widget.isHost ? 'host' : 'guest';
  String get _opKey => widget.isHost ? 'guest' : 'host';

  List<int> _myDeck = [];
  List<int> _mySlots = [];
  List<int> _opponentSlots = [];
  int _opponentDeckCount = 0;
  List<int> _roomDeck = [];

  int? _currentComposite;
  int? _displayedComposite;
  Map<int, int> _targetFactors = {};
  Map<int, Map<String, int>> _playZone = {};

  bool _gameOver = false;
  bool _iWon = false;
  bool _penaltyMe = false;
  bool _penaltyOp = false;
  bool _acceptInput = false;
  String _penaltyMsg = '';
  String _readyGoText = '';
  bool _navigated = false;
  bool _isFlowing = false;

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
    _roomSub?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // ── 広告読み込み ──────────────────────────
  void _loadAd() {
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
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (mounted) setState(() {});
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (mounted) setState(() {});
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _adLoaded = false;
    }
  }

  Future<void> _initGame() async {
    final snap = await _roomRef.get();
    final data = snap.value as Map<dynamic, dynamic>?;

    if (data == null || data['status'] != 'playing' ||
        data['deck'] == null || data['seed'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ルーム状態が不正です')));
        Navigator.pop(context);
      }
      return;
    }

    final deckRaw = data['deck'] as List<dynamic>;
    _roomDeck = deckRaw.map((e) => e is int ? e : int.parse(e.toString())).toList();

    final seed = data['seed'] as int;
    _myDeck = _buildDeck(Random(seed + (widget.isHost ? 1 : 2)));
    _mySlots = [];
    _fillMySlots();

    await _roomRef.child(_myKey).set({
      'slots': _mySlots,
      'deckCount': _myDeck.length,
      'done': false,
      'penalty': false,
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _roomSub = _roomRef.onValue.listen(_onRoomUpdate);

    if (widget.isHost) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_isFlowing) {
        _isFlowing = true;
        try { await _nextCard(); } finally { _isFlowing = false; }
      }
    }
  }

  List<int> _buildDeck(Random rng) {
    final deck = <int>[];
    _cardCounts.forEach((prime, count) {
      for (int i = 0; i < count; i++) deck.add(prime);
    });
    deck.shuffle(rng);
    return deck;
  }

  void _fillMySlots() {
    while (_mySlots.length < 5 && _myDeck.isNotEmpty) {
      _mySlots.add(_myDeck.removeAt(0));
    }
  }

  Future<void> _nextCard() async {
    if (!widget.isHost) return;
    final snap = await _gameRef.get();
    final gm = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final pos = (gm['deckPos'] as int?) ?? 0;
    final nextPos = pos + 1;

    final idx = _roomDeck.length - nextPos;
    if (idx < 0 || idx >= _roomDeck.length) {
      await _gameRef.update({'phase': 'deckEmpty', 'composite': null});
      if (mounted && !_gameOver) _endGame(iWon: false);
      return;
    }

    final card = _roomDeck[idx];
    await _roomRef.child('host').update({'penalty': false});
    await _roomRef.child('guest').update({'penalty': false});
    await _gameRef.update({
      'phase': 'playing',
      'composite': card,
      'deckPos': nextPos,
      'playZone': {'_x': 0},
    });
  }

  void _onRoomUpdate(DatabaseEvent event) {
    if (!mounted || _navigated) return;
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    final opData = data[_opKey] as Map<dynamic, dynamic>?;
    bool opDone = false;
    bool opPenalty = false;
    if (opData != null) {
      final slots = (opData['slots'] as List<dynamic>?)
          ?.map((e) => e is int ? e : int.parse(e.toString())).toList() ?? [];
      final deckCount = opData['deckCount'] as int? ?? 0;
      opDone = opData['done'] as bool? ?? false;
      opPenalty = opData['penalty'] as bool? ?? false;

      if (opDone && !_gameOver) { _endGame(iWon: false); return; }

      setState(() {
        _opponentSlots = slots;
        _opponentDeckCount = deckCount;
        _penaltyOp = opPenalty;
      });
    }

    if (_penaltyMe && opPenalty && widget.isHost && !_isFlowing) {
      _isFlowing = true;
      setState(() => _acceptInput = false);
      Future.delayed(const Duration(milliseconds: 600), () async {
        try { await _nextCard(); } finally {
          if (mounted) _isFlowing = false;
        }
      });
      return;
    }

    final gameData = data['game'] as Map<dynamic, dynamic>?;
    if (gameData == null) return;

    final phase = gameData['phase'] as String? ?? 'init';
    if (phase == 'init') return;
    if (phase == 'deckEmpty') { if (mounted && !_gameOver) _endGame(iWon: false); return; }

    final rawComposite = gameData['composite'];
    if (rawComposite == null) return;
    final composite = rawComposite is int ? rawComposite : int.tryParse(rawComposite.toString()) ?? 0;
    if (composite <= 1) return;

    if (composite != _displayedComposite) {
      _displayedComposite = composite;
      final factors = factorize(composite);
      if (factors.isEmpty) {
        if (widget.isHost && !_isFlowing) {
          _isFlowing = true;
          _nextCard().whenComplete(() { if (mounted) _isFlowing = false; });
        }
        return;
      }

      setState(() {
        _currentComposite = composite;
        _targetFactors = Map.from(factors);
        _playZone = {};
        _penaltyMe = false;
        _penaltyMsg = '';
        _acceptInput = false;
        _readyGoText = 'READY';
      });
      _roomRef.child(_myKey).update({'penalty': false});

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _displayedComposite != composite) return;
        setState(() => _readyGoText = 'GO!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _displayedComposite != composite) return;
          setState(() { _readyGoText = ''; _acceptInput = true; });
        });
      });
      return;
    }

    if (phase != 'playing') return;

    final playZoneRaw = gameData['playZone'] as Map<dynamic, dynamic>?;
    if (playZoneRaw != null) {
      final newZone = <int, Map<String, int>>{};
      playZoneRaw.forEach((k, v) {
        if (k.toString() == '_x') return;
        final prime = int.tryParse(k.toString());
        if (prime == null || v == null || v is! Map) return;
        newZone[prime] = {
          'host': _toInt((v as Map)['host']),
          'guest': _toInt(v['guest']),
        };
      });
      setState(() => _playZone = newZone);

      if (_acceptInput && _isComplete() && widget.isHost && !_isFlowing) {
        _isFlowing = true;
        setState(() => _acceptInput = false);
        _nextCard().whenComplete(() { if (mounted) _isFlowing = false; });
      }
    }
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _isComplete() {
    if (_currentComposite == null || _targetFactors.isEmpty) return false;
    for (final e in _targetFactors.entries) {
      if (e.value <= 0) return false;
      if (_playZoneTotal(e.key) < e.value) return false;
    }
    return true;
  }

  int _playZoneTotal(int prime) {
    final m = _playZone[prime];
    if (m == null) return 0;
    return (m['host'] ?? 0) + (m['guest'] ?? 0);
  }

  bool _canPlay(int prime) {
    final needed = _targetFactors[prime] ?? 0;
    if (needed == 0) return false;
    return _playZoneTotal(prime) < needed;
  }

  Future<void> _playCard(int slotIndex) async {
    if (_gameOver || !_acceptInput || _penaltyMe) return;
    if (slotIndex < 0 || slotIndex >= _mySlots.length) return;

    final prime = _mySlots[slotIndex];

    if (!_canPlay(prime)) {
      setState(() { _penaltyMsg = 'お手つき！ $prime は出せません'; _penaltyMe = true; });
      await _roomRef.child(_myKey).update({'penalty': true});
      return;
    }

    final ref = _db.ref('rooms/${widget.roomId}/game/playZone/$prime/$_myKey');
    final cur = await ref.get();
    await ref.set((_toInt(cur.value)) + 1);

    setState(() {
      _penaltyMsg = '';
      if (_myDeck.isNotEmpty) {
        _mySlots[slotIndex] = _myDeck.removeAt(0);
      } else {
        _mySlots.removeAt(slotIndex);
      }
    });

    await _roomRef.child(_myKey).update({'slots': _mySlots, 'deckCount': _myDeck.length});

    if (_mySlots.isEmpty && _myDeck.isEmpty) _endGame(iWon: true);
  }

  void _endGame({required bool iWon}) {
    if (iWon) _roomRef.child(_myKey).update({'done': true});
    setState(() { _gameOver = true; _iWon = iWon; _navigated = true; });
    Future.delayed(const Duration(milliseconds: 300), _showAdThenResult);
  }

  Future<void> _hostForceNext() async {
    if (!widget.isHost || _isFlowing) return;
    _isFlowing = true;
    setState(() => _acceptInput = false);
    try { await _nextCard(); } finally { if (mounted) _isFlowing = false; }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildResult();
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a1628),
        foregroundColor: Colors.white,
        toolbarHeight: isSmall ? 40 : kToolbarHeight,
        title: Text('対人戦  ${widget.roomId}',
          style: TextStyle(fontSize: isSmall ? 14 : 18)),
        actions: [
          if (widget.isHost)
            TextButton.icon(
              onPressed: _hostForceNext,
              icon: Icon(Icons.sync, color: Colors.orange, size: isSmall ? 16 : 24),
              label: Text('流す', style: TextStyle(color: Colors.orange, fontSize: isSmall ? 12 : 14)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildOpponentArea(isSmall: isSmall),
          const Divider(color: Colors.white12, height: 1),
          Expanded(child: _buildCenterArea(isSmall: isSmall)),
          const Divider(color: Colors.white12, height: 1),
          _buildMyArea(isSmall: isSmall),
        ],
      ),
    );
  }

  Widget _buildOpponentArea({bool isSmall = false}) {
    return Container(
      color: const Color(0xFF0d1f3c),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 4 : 8),
      child: Row(children: [
        Icon(Icons.person_outline, color: Colors.redAccent, size: isSmall ? 14 : 18),
        const SizedBox(width: 6),
        Text('相手  山: $_opponentDeckCount枚',
          style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
        if (_penaltyOp)
          Padding(padding: const EdgeInsets.only(left: 8),
            child: Text('⚠ お手つき中',
              style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 10 : 12))),
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
          SizedBox(height: isSmall ? 2 : 6),
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
            Icon(Icons.person_outline, color: Colors.redAccent, size: isSmall ? 11 : 14),
            const SizedBox(width: 4),
            Text('相手の場札', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 9 : 11)),
          ]),
          SizedBox(height: isSmall ? 2 : 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (_opponentSlots.isEmpty ? List<int?>.filled(5, null) : _opponentSlots.cast<int?>())
                  .map((v) => _buildCard(v, owner: 'opponent', small: true, faceDown: v == null, isSmall: isSmall))
                  .toList(),
            ),
          ),
          SizedBox(height: vGap),
          Text('プレイゾーン', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 12)),
          SizedBox(height: isSmall ? 2 : 4),
          Container(
            constraints: BoxConstraints(minHeight: isSmall ? 52 : 72),
            width: double.infinity,
            padding: const EdgeInsets.all(6),
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
                        for (int i = 0; i < (e.value[_myKey] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'me', isSmall: isSmall),
                        for (int i = 0; i < (e.value[_opKey] ?? 0); i++)
                          _buildCard(e.key, small: true, owner: 'opponent', isSmall: isSmall),
                      ],
                    ],
                  ),
          ),
          if (_penaltyMsg.isNotEmpty) ...[
            SizedBox(height: isSmall ? 4 : 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_penaltyMsg, style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 11 : 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyArea({bool isSmall = false}) {
    return Container(
      color: const Color(0xFF0d1f3c),
      padding: EdgeInsets.fromLTRB(16, isSmall ? 6 : 14, 16, isSmall ? 6 : 10),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.person, color: const Color(0xFF00d4ff), size: isSmall ? 14 : 18),
            const SizedBox(width: 6),
            Text('あなた  山: ${_myDeck.length}枚',
              style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13)),
            if (_penaltyMe)
              Padding(padding: const EdgeInsets.only(left: 8),
                child: Text('⚠ お手つき中',
                  style: TextStyle(color: Colors.redAccent, fontSize: isSmall ? 10 : 12))),
          ]),
          SizedBox(height: isSmall ? 4 : 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_mySlots.length, (i) {
                final tappable = !_penaltyMe && _acceptInput;
                return GestureDetector(
                  onTap: tappable ? () => _playCard(i) : null,
                  child: _buildCard(_mySlots[i], owner: 'me', isSmall: isSmall),
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
    if (faceDown || prime == null) {
      borderColor = Colors.white24; bgColor = const Color(0xFF1a1a2e); textColor = Colors.white24;
    } else if (owner == 'me') {
      borderColor = const Color(0xFF00d4ff); bgColor = const Color(0xFF00d4ff).withOpacity(0.15); textColor = const Color(0xFF00d4ff);
    } else if (owner == 'opponent') {
      borderColor = const Color(0xFFff4444); bgColor = const Color(0xFFff4444).withOpacity(0.15); textColor = const Color(0xFFff4444);
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
        child: (faceDown || prime == null)
            ? const Icon(Icons.question_mark, color: Colors.white24, size: 20)
            : Text('$prime', style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildResult() {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_iWon ? '🏆' : '😢', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(_iWon ? 'あなたの勝ち！' : '相手の勝ち...',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                color: _iWon ? const Color(0xFFffd700) : Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00d4ff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('タイトルへ', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
