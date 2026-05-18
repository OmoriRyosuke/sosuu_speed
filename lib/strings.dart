import 'app_settings.dart';

class S {
  static bool get _e => AppSettings.instance.isEnglish;

  // ── Title ──────────────────────────────────────────────
  static String get appTitle => _e ? 'Prime Speed' : '素数スピード';
  static String get appSubtitle =>
      _e ? 'Prime Number Speed' : 'Prime Number Speed';
  static String get btnCpu => _e ? '🤖  CPU Battle' : '🤖  CPU戦';
  static String get btnOnline => _e ? '👥  Online Battle' : '👥  対人戦';
  static String get btnCreate => _e ? '🔧  Create Mode' : '🔧  クリエイト';
  static String get btnHowTo => _e ? '📖  How to Play' : '📖  遊び方';

  // ── Difficulty ─────────────────────────────────────────
  static String get selectDiff => _e ? 'Select Difficulty' : '難易度選択';
  static String get chooseStrength =>
      _e ? 'Choose CPU strength' : 'CPUの強さを選んでください';
  static String get diffEasy => _e ? '😊  Easy' : '😊  かんたん';
  static String get diffEasySub =>
      _e ? 'CPU is slow, makes mistakes' : 'CPUがゆっくり・たまに間違える';
  static String get diffNormal => _e ? '😐  Normal' : '😐  ふつう';
  static String get diffNormalSub =>
      _e ? 'CPU is moderate' : 'CPUがそこそこ速い';
  static String get diffHard => _e ? '😈  Hard' : '😈  むずかしい';
  static String get diffHardSub =>
      _e ? 'CPU is super fast, nearly perfect' : 'CPUが超高速・ほぼ完璧';

  // ── Game (CPU) ─────────────────────────────────────────
  static String get cpuBattleTitle => _e ? 'CPU Battle' : 'CPU戦';
  static String get countLabel => _e ? '10-Count' : '10カウント';
  static String get questionCard => _e ? 'Problem' : '題札';
  static String get cpuHandLabel => _e ? 'CPU Hand' : 'CPU場札';
  static String get playZone => _e ? 'Play Zone' : 'プレイゾーン';
  static String get playZoneHint =>
      _e ? 'Place cards here' : 'カードを出す場所';
  static String get deckSuffix => _e ? ' deck' : '枚  山:';
  static String get deckCards => _e ? 'cards' : '枚';
  static String get youLabel => _e ? 'You' : 'あなた';
  static String get penaltyActive =>
      _e ? '⚠ Penalty' : '⚠ お手つき中';
  static String penaltyMsg(int p) =>
      _e ? 'Foul! $p cannot be played' : 'お手つき！ $p は出せません';

  // ── Result ─────────────────────────────────────────────
  static String get youWin => _e ? 'You Win!' : 'あなたの勝ち！';
  static String get cpuWin => _e ? 'CPU Wins...' : 'CPUの勝ち...';
  static String get opWin => _e ? 'Opponent Wins...' : '相手の勝ち...';
  static String get retry => _e ? 'Play Again' : 'もう一度';
  static String get toTitle => _e ? 'Title' : 'タイトルへ';

  // ── Online ─────────────────────────────────────────────
  static String get onlineTitle => _e ? 'Online Battle' : '対人戦';
  static String get createRoom => _e ? 'Create Room' : 'ルームを作る';
  static String get joinRoom => _e ? 'Join Room' : 'ルームに参加';
  static String get roomIdHint => _e ? 'Room ID' : 'ルームID';
  static String get waitingTitle => _e ? 'Waiting...' : '待機中...';
  static String get startGame => _e ? 'Start Game!' : 'ゲームスタート！';
  static String get waitingGuest =>
      _e ? 'Waiting for opponent...' : '相手の参加を待っています...';
  static String get guestJoined =>
      _e ? 'Opponent joined!' : '相手が参加しました！';
  static String get waitingHost =>
      _e ? 'Waiting for host to start...' : 'ホストのスタートを待っています...';
  static String get opponentLabel => _e ? 'Opponent' : '相手';
  static String get opponentHand =>
      _e ? 'Opponent Hand' : '相手の場札';
  static String get copied => _e ? 'Copied!' : 'コピーしました！';
  static String get copy => _e ? 'Copy' : 'コピー';
  static String get scanQr =>
      _e ? 'Scan QR code to invite' : 'QRコードを読ませて招待';
  static String get roomNotFound =>
      _e ? 'Room not found' : 'ルームが見つかりません';
  static String get roomStarted =>
      _e ? 'This room has already started' : 'このルームは開始済みです';
  static String get roomInvalid =>
      _e ? 'Invalid room state' : 'ルーム状態が不正です';
  static String startFailed(Object e) =>
      _e ? 'Failed to start: $e' : '開始に失敗しました: $e';
  static String get enterRoomId =>
      _e ? 'Enter 5-character Room ID' : '5文字のルームIDを入力してください';
  static String get flush => _e ? 'Flush' : '流す';
  static String get configLabel => _e ? 'Config' : '設定';
  static String get defaultLabel => _e ? 'Default' : 'デフォルト';
  static String get onlineGameTitle => _e ? 'Online' : '対人戦';

  // ── Create Mode ────────────────────────────────────────
  static String get createTitle => _e ? 'Create Mode' : 'クリエイトモード';
  static String get primeCardsSection =>
      _e ? 'Prime Cards' : '素数カード設定';
  static String get savedSection =>
      _e ? 'Saved Configs' : '保存した設定';
  static String get configNameHint => _e ? 'Config name' : '設定名';
  static String get save => _e ? 'Save' : '保存';
  static String get delete => _e ? 'Delete' : '削除';
  static String get load => _e ? 'Load' : '読込';
  static String get cpuBattleWith =>
      _e ? 'CPU Battle' : 'CPU戦';
  static String get onlineBattleWith =>
      _e ? 'Online Battle' : '対人戦';
  static String get emptySlot => _e ? '(empty)' : '(空)';
  static String compositeCount(int n) =>
      _e ? '$n composites' : '合成数 $n 問';
  static String get availablePrimes =>
      _e ? 'Available Primes:' : '使用する素数:';
  static String get compositeListSection =>
      _e ? 'Problem Cards' : '場札（出題する数）';
  static String get compositeAddHint =>
      _e ? 'Add number (e.g. 49,119)' : '数字を追加 (例: 49,119)';
  static String get resetToDefault => _e ? 'Reset' : '初期化';
  static String get quickBattleCpu => _e ? 'CPU' : 'CPU';
  static String get quickBattleOnline => _e ? 'Online' : '対人';
  static String get extraPrimeHint =>
      _e ? 'Add prime (e.g. 41,43)' : '素数を追加 (例: 41,43)';
  static String get passBtn => _e ? 'Pass' : 'パス';
  static String get opPassedLabel => _e ? 'Op: passed' : '相手: パス中';

  // ── How to Play ────────────────────────────────────────
  static String get howToTitle => _e ? 'How to Play' : '遊び方';
  static String get r1t => _e ? 'Goal' : '目的';
  static String get r1b => _e
      ? 'Use up all your prime cards first to win!'
      : '場札の素数カードを使い切ること！先に使い切った人の勝ちです。';
  static String get r2t => _e ? 'Problem Card' : '題札（合成数）';
  static String get r2b => _e
      ? 'Factor the composite shown in the center and play the corresponding prime factor cards.'
      : '中央に表示される合成数を素因数分解して、その素因数カードを場から出します。';
  static String get r3t => _e ? 'Playing Cards' : 'カードの出し方';
  static String get r3b => _e
      ? 'Tap a prime card to play it. Only cards that are prime factors can be played. Default cards: 2,3,5,7,11 (Hard adds 13).'
      : '場札の素数カードをタップして出します。素因数として含まれているカードだけ出せます。カードは 2,3,5,7,11の5種類ですがCPU戦のむずかしいのみ13がはいっています。';
  static String get r4t => _e ? 'Foul' : 'お手つき';
  static String get r4b => _e
      ? 'Playing a non-factor card is a foul. If both players foul, the next problem appears.'
      : '素因数でないカードを出すとお手つきです。お互いお手つきになると次の合成数が出現します。';
  static String get r5t => _e ? '10-Count' : '10カウント';
  static String get r5b => _e
      ? 'In CPU Battle, if no card is played within 10 seconds the problem is cleared. No count in Online Battle.'
      : 'CPU戦では10カウント以内にカードを出さないと場が流れます。対人戦にはカウントはありません。';
  static String get r6t => _e ? 'Card Consumption' : 'カードの消費';
  static String get r6b => _e
      ? 'Cards played are not returned even when cleared. New cards are drawn from your deck.'
      : '出したカードは場が流れても戻りません。山札から新しいカードが補充されます。';
}
