import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'strings.dart';
import 'game_utils.dart';
import 'online_game.dart';
import 'game_screen.dart' show DifficultyScreen;

const List<int> kAvailablePrimes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];

class CreateModeScreen extends StatefulWidget {
  const CreateModeScreen({super.key});
  @override
  State<CreateModeScreen> createState() => _CreateModeScreenState();
}

class _CreateModeScreenState extends State<CreateModeScreen> {
  late Map<int, int> _primeCards;
  late List<int> _composites;
  final Set<int> _extraPrimes = {};
  final _nameController = TextEditingController(text: 'My Config');
  final _addController = TextEditingController();
  final _extraPrimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primeCards = Map.from(GameConfig.defaultConfig.primeCards);
    _composites = List.from(compositeNumbers)..sort();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addController.dispose();
    _extraPrimeController.dispose();
    super.dispose();
  }

  GameConfig get _currentConfig => GameConfig(
        name: _nameController.text.trim().isEmpty
            ? 'Config'
            : _nameController.text.trim(),
        primeCards: Map.from(_primeCards),
        composites: List.from(_composites),
      );

  void _loadConfig(GameConfig config) {
    setState(() {
      _primeCards = Map.from(config.primeCards);
      _composites = config.composites != null
          ? (List.from(config.composites!)..sort())
          : (List.from(compositeNumbers)..sort());
      _nameController.text = config.name;
    });
  }

  Future<void> _saveToSlot(int slot) async {
    await AppSettings.instance.saveConfig(slot, _currentConfig);
    if (mounted) setState(() {});
  }

  Future<void> _deleteSlot(int slot) async {
    await AppSettings.instance.deleteConfig(slot);
    if (mounted) setState(() {});
  }

  void _addComposites() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(RegExp(r'[,\s、]+'));
    bool added = false;
    for (final s in parts) {
      final n = int.tryParse(s.trim());
      if (n != null && n >= 2 && !_composites.contains(n)) {
        _composites.add(n);
        added = true;
      }
    }
    if (added) {
      setState(() => _composites.sort());
      _addController.clear();
    }
  }

  void _addExtraPrime() {
    final text = _extraPrimeController.text.trim();
    final n = int.tryParse(text);
    if (n == null || !isPrime(n)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppSettings.instance.isEnglish
            ? '$text is not a prime number'
            : '$text は素数ではありません')),
      );
      return;
    }
    if (kAvailablePrimes.contains(n) || _extraPrimes.contains(n)) return;
    setState(() => _extraPrimes.add(n));
    _extraPrimeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(S.createTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(S.primeCardsSection),
          const SizedBox(height: 8),
          _buildPrimeGrid(),
          const SizedBox(height: 20),
          _sectionLabel(S.compositeListSection),
          const SizedBox(height: 8),
          _buildCompositeEditor(),
          const SizedBox(height: 20),
          _sectionLabel(S.configNameHint),
          const SizedBox(height: 8),
          _buildNameField(),
          const SizedBox(height: 20),
          _sectionLabel(S.savedSection),
          const SizedBox(height: 8),
          _buildSaveSlots(),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: S.cpuBattleWith,
                  color: const Color(0xFF00d4ff),
                  onTap: _primeCards.isEmpty || _composites.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DifficultyScreen(config: _currentConfig),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: S.onlineBattleWith,
                  color: const Color(0xFF7c4dff),
                  onTap: _primeCards.isEmpty || _composites.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OnlineMenuScreen(config: _currentConfig),
                            ),
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Color(0xFFffd700),
            fontSize: 13,
            fontWeight: FontWeight.bold),
      );

  Widget _buildPrimeGrid() {
    final extraSorted = _extraPrimes.toList()..sort();
    final allPrimes = [...kAvailablePrimes, ...extraSorted];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allPrimes.map((p) {
            final count = _primeCards[p] ?? 0;
            final selected = count > 0;
            final isExtra = !kAvailablePrimes.contains(p);
            return _PrimeTile(
              prime: p,
              count: count,
              selected: selected,
              onToggle: () {
                setState(() {
                  if (!selected) _primeCards[p] = 1;
                });
              },
              onIncrement: selected
                  ? () {
                      if (count < 9) setState(() => _primeCards[p] = count + 1);
                    }
                  : null,
              onDecrement: selected
                  ? () {
                      if (count > 1) {
                        setState(() => _primeCards[p] = count - 1);
                      } else {
                        setState(() {
                          _primeCards.remove(p);
                          if (isExtra) _extraPrimes.remove(p);
                        });
                      }
                    }
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildExtraPrimeInput(),
      ],
    );
  }

  Widget _buildExtraPrimeInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              controller: _extraPrimeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: S.extraPrimeHint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              ),
              onSubmitted: (_) => _addExtraPrime(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addExtraPrime,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFffd700)),
            ),
            child: const Icon(Icons.add, color: Color(0xFFffd700), size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildCompositeEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: (_composites.toList()..sort())
              .map((n) => _CompositeChip(
                    number: n,
                    onRemove: () => setState(() => _composites.remove(n)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: _addController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: S.compositeAddHint,
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                  ),
                  onSubmitted: (_) => _addComposites(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addComposites,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF00d4ff).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00d4ff)),
                ),
                child: const Icon(Icons.add,
                    color: Color(0xFF00d4ff), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(
                  () => _composites = (List.from(compositeNumbers)..sort())),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(S.resetToDefault,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          S.compositeCount(_composites.length),
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: S.configNameHint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSaveSlots() {
    return Column(
      children: List.generate(AppSettings.maxSlots, (i) {
        final config = AppSettings.instance.savedConfigs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: config != null
                          ? const Color(0xFF00d4ff).withValues(alpha: 0.2)
                          : Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: config != null
                              ? const Color(0xFF00d4ff)
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: config != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(config.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                config.primeCards.entries
                                    .map((e) => '${e.key}x${e.value}')
                                    .join('  '),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          )
                        : Text(S.emptySlot,
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 12)),
                  ),
                  if (config != null) ...[
                    _SlotButton(
                      label: S.load,
                      color: const Color(0xFF00e676),
                      onTap: () => _loadConfig(config),
                    ),
                    const SizedBox(width: 6),
                    _SlotButton(
                      label: S.delete,
                      color: Colors.redAccent,
                      onTap: () => _deleteSlot(i),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _SlotButton(
                    label: S.save,
                    color: const Color(0xFFffd700),
                    onTap: _primeCards.isEmpty || _composites.isEmpty
                        ? null
                        : () => _saveToSlot(i),
                  ),
                ],
              ),
              if (config != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 36),
                    _SlotButton(
                      label: S.quickBattleCpu,
                      color: const Color(0xFF00d4ff),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DifficultyScreen(config: config),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SlotButton(
                      label: S.quickBattleOnline,
                      color: const Color(0xFF7c4dff),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnlineMenuScreen(config: config),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _CompositeChip extends StatelessWidget {
  final int number;
  final VoidCallback onRemove;
  const _CompositeChip({required this.number, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00d4ff).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00d4ff).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$number',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _PrimeTile extends StatelessWidget {
  final int prime;
  final int count;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _PrimeTile({
    required this.prime,
    required this.count,
    required this.selected,
    required this.onToggle,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00d4ff);
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              _CountBtn(
                  icon: Icons.keyboard_arrow_up,
                  onTap: onIncrement,
                  size: 18),
              Text(
                '$prime',
                style: const TextStyle(
                  color: activeColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$count',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              _CountBtn(
                  icon: Icons.keyboard_arrow_down,
                  onTap: onDecrement,
                  size: 18),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                '$prime',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text('OFF',
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  const _CountBtn({required this.icon, this.onTap, required this.size});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Icon(icon,
            size: size,
            color: onTap != null ? Colors.white70 : Colors.white24),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _SlotButton(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.15) : Colors.white12,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: onTap != null ? color : Colors.white24, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: onTap != null ? color : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.2) : Colors.white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: onTap != null ? color : Colors.white24, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap != null ? color : Colors.white24,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
