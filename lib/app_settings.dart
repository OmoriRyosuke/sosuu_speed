import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameConfig {
  final String name;
  final Map<int, int> primeCards;
  final List<int>? composites; // null = use default per difficulty

  const GameConfig({
    required this.name,
    required this.primeCards,
    this.composites,
  });

  static const GameConfig defaultConfig = GameConfig(
    name: 'Default',
    primeCards: {2: 5, 3: 4, 5: 3, 7: 3, 11: 3},
  );

  bool get isDefault =>
      name == 'Default' &&
      primeCards.length == 5 &&
      primeCards[2] == 5 &&
      primeCards[3] == 4 &&
      primeCards[5] == 3 &&
      primeCards[7] == 3 &&
      primeCards[11] == 3;

  Map<String, dynamic> toJson() => {
        'name': name,
        'primeCards': {for (final e in primeCards.entries) '${e.key}': e.value},
        if (composites != null) 'composites': composites,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        name: json['name'] as String? ?? 'Config',
        primeCards: {
          for (final e
              in ((json['primeCards'] as Map?)?.cast<String, dynamic>() ?? {})
                  .entries)
            int.parse(e.key): e.value as int,
        },
        composites: (json['composites'] as List<dynamic>?)
            ?.map((e) => e is int ? e : int.parse(e.toString()))
            .toList(),
      );

  GameConfig copyWith({String? name, Map<int, int>? primeCards, List<int>? composites}) =>
      GameConfig(
        name: name ?? this.name,
        primeCards: primeCards ?? Map.from(this.primeCards),
        composites: composites ?? this.composites,
      );
}

class AppSettings {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  bool isEnglish = false;
  static const int maxSlots = 10;
  final List<GameConfig?> savedConfigs =
      List.filled(maxSlots, null, growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isEnglish = prefs.getBool('isEnglish') ?? false;
    for (int i = 0; i < maxSlots; i++) {
      final raw = prefs.getString('config_$i');
      if (raw != null) {
        try {
          savedConfigs[i] =
              GameConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
  }

  Future<void> setLanguage(bool english) async {
    isEnglish = english;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', english);
  }

  Future<void> saveConfig(int slot, GameConfig config) async {
    savedConfigs[slot] = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('config_$slot', jsonEncode(config.toJson()));
  }

  Future<void> deleteConfig(int slot) async {
    savedConfigs[slot] = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('config_$slot');
  }
}
