/// Lower-cases [text] and keeps only letters and digits (in any script), so
/// "You Tube", "youtube" and "YouTube!" all give the same key.
String matchKey(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
}

/// Number of single-character edits needed to turn [a] into [b].
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final substitution = previous[j - 1] + cost;
      var best = deletion < insertion ? deletion : insertion;
      if (substitution < best) best = substitution;
      current[j] = best;
    }
    previous = current;
  }
  return previous[b.length];
}

/// An item together with how well it matched (higher is better).
class Scored<T> {
  const Scored(this.item, this.score);

  final T item;
  final int score;
}

int _score(String query, String key) {
  if (key == query) return 1000;

  final diff = (key.length - query.length).abs();
  if (key.startsWith(query)) return 800 - diff;
  if (query.length >= 3 && key.contains(query)) return 600 - diff;
  if (key.length >= 4 && query.contains(key)) return 500 - diff;

  // Speech recognition often gets a letter or two wrong.
  final allowed = query.length <= 3 ? 0 : (query.length <= 7 ? 1 : 2);
  if (allowed > 0 && diff <= allowed) {
    final distance = editDistance(query, key);
    if (distance <= allowed) return 400 - distance * 50;
  }
  return 0;
}

/// The item whose label is closest to [query], with its score, or null.
Scored<T>? bestMatchScored<T>(
  String query,
  Iterable<T> items,
  String Function(T item) label,
) {
  final q = matchKey(query);
  if (q.isEmpty) return null;

  Scored<T>? best;
  for (final item in items) {
    final key = matchKey(label(item));
    if (key.isEmpty) continue;
    final score = _score(q, key);
    if (score > 0 && (best == null || score > best.score)) {
      best = Scored<T>(item, score);
    }
  }
  return best;
}

/// The item whose label is closest to [query], or null.
T? bestMatch<T>(
  String query,
  Iterable<T> items,
  String Function(T item) label,
) {
  return bestMatchScored<T>(query, items, label)?.item;
}
