bool isPrime(int n) {
  if (n < 2) return false;
  for (int d = 2; d * d <= n; d++) {
    if (n % d == 0) return false;
  }
  return true;
}

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

// カスタム設定からプレイ可能な合成数を生成する
List<int> generateComposites(Map<int, int> primeCards) {
  final primes = primeCards.keys.toSet();
  if (primes.isEmpty) return List.from(compositeNumbers);

  final result = <int>[];
  for (int n = 4; n <= 500; n++) {
    final factors = factorize(n);
    if (factors.isEmpty) continue;
    // 全ての素因数が選択済みプライムに含まれているか
    if (factors.keys.any((p) => !primes.contains(p))) continue;
    // 各素因数の必要枚数が手持ち枚数以下か
    if (!factors.entries.every((e) => (primeCards[e.key] ?? 0) >= e.value)) {
      continue;
    }
    result.add(n);
  }

  // 複雑度（総指数の和）でソート
  result.sort((a, b) {
    final sa = factorize(a).values.fold(0, (x, y) => x + y);
    final sb = factorize(b).values.fold(0, (x, y) => x + y);
    return sa != sb ? sa.compareTo(sb) : a.compareTo(b);
  });

  return result;
}
