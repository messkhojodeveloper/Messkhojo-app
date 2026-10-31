import 'dart:math';

double deg2rad(double deg) {
  return deg * (pi / 180);
}

double? calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  if (lat1.isNaN || lon1.isNaN || lat2.isNaN || lon2.isNaN) return null;

  const double R = 6371;
  final double dLat = deg2rad(lat2 - lat1);
  final double dLon = deg2rad(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

  final double c = 2 * atan2(sqrt(max(0, min(1, a))), sqrt(max(0, min(1, 1 - a))));
  return R * c;
}

int levenshtein(String a, String b) {
  final int m = a.length;
  final int n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;

  final List<int> dp = List.generate(m + 1, (i) => i);
  for (int j = 1; j <= n; j++) {
    int prev = dp[0];
    dp[0] = j;
    for (int i = 1; i <= m; i++) {
      final int temp = dp[i];
      dp[i] = a[i - 1] == b[j - 1]
          ? prev
          : 1 + min(prev, min(dp[i], dp[i - 1]));
      prev = temp;
    }
  }
  return dp[m];
}

int fuzzyScore(String? query, String? text) {
  if (query == null || text == null) return 0;
  final String q = query.toLowerCase().trim();
  final String t = text.toLowerCase().trim();
  if (q.isEmpty || t.isEmpty) return 0;

  if (t == q) return 120;
  if (t.startsWith(q)) return 110;
  if (t.contains(q)) return 100;

  final List<String> qWords = q.split(RegExp(r'\s+'));
  final List<String> tWords = t.split(RegExp(r'\s+'));
  int wordMatchCount = 0;
  for (final String qw in qWords) {
    if (qw.length < 2) continue;
    if (tWords.any((tw) => tw.contains(qw) || qw.contains(tw))) {
      wordMatchCount++;
    }
  }
  if (wordMatchCount > 0) {
    return 60 + ((wordMatchCount / qWords.length) * 30).round();
  }

  if (tWords.any((tw) => tw.startsWith(q))) return 70;

  double bestWordSim = 0.0;
  for (final String qw in qWords) {
    if (qw.length < 2) continue;
    for (final String tw in tWords) {
      if (tw.length < 2) continue;
      final int dist = levenshtein(qw, tw);
      final int maxLen = qw.length > tw.length ? qw.length : tw.length;
      final double sim = 1 - dist / maxLen;
      if (sim > bestWordSim) bestWordSim = sim;
    }
  }

  final String subT = t.substring(0, min(t.length, q.length + 3));
  final int fullDist = levenshtein(q, subT);
  final double fullSim = 1 - fullDist / max(q.length, subT.length);
  bestWordSim = max(bestWordSim, fullSim);

  if (bestWordSim >= 0.5) {
    return 20 + (bestWordSim * 30).round();
  }

  return 0;
}