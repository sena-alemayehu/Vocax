import 'package:flutter_test/flutter_test.dart';
import 'package:vocax/services/fuzzy_match.dart';

void main() {
  final apps = ['YouTube', 'Google Maps', 'WhatsApp', 'Settings', 'Camera'];

  String? find(String query) => bestMatch<String>(query, apps, (app) => app);

  test('matches ignoring case, spaces and punctuation', () {
    expect(find('you tube'), 'YouTube');
    expect(find("what's app"), 'WhatsApp');
  });

  test('matches part of a longer name', () {
    expect(find('maps'), 'Google Maps');
  });

  test('forgives a small speech mistake', () {
    expect(find('whatsap'), 'WhatsApp');
    expect(find('camra'), 'Camera');
  });

  test('returns null when nothing is close', () {
    expect(find('moon'), isNull);
  });

  test('edit distance counts single-letter changes', () {
    expect(editDistance('kitten', 'sitting'), 3);
    expect(editDistance('same', 'same'), 0);
  });
}
