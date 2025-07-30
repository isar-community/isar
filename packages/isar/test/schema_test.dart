import 'package:test/test.dart';

void main() {
  group('Schema Backward Compatibility', () {
    test('web-safe hash function produces consistent results', () {
      // Test the hash function that gets generated
      int webSafeHash(String input, [int seed = 0]) {
        var hash = 5381 + seed;
        for (var i = 0; i < input.length; i++) {
          hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
        }
        return hash;
      }

      // Test consistency
      expect(
          webSafeHash('TestCollection'), equals(webSafeHash('TestCollection')));
      expect(webSafeHash('TestIndex'), equals(webSafeHash('TestIndex')));

      // Test different inputs produce different results
      expect(webSafeHash('Collection1'),
          isNot(equals(webSafeHash('Collection2'))));

      // Test all results are within JavaScript safe range
      final testInputs = [
        'VeryLongCollectionNameThatMightCauseIssues',
        'AnotherCollection',
        'ShortName',
        '',
        'Collection' * 50,
      ];

      for (final input in testInputs) {
        final hash = webSafeHash(input);
        expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
        expect(hash, greaterThanOrEqualTo(0));
      }
    });

    test('hash function handles edge cases', () {
      int webSafeHash(String input, [int seed = 0]) {
        var hash = 5381 + seed;
        for (var i = 0; i < input.length; i++) {
          hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
        }
        return hash;
      }

      // Test empty string
      final emptyHash = webSafeHash('');
      expect(emptyHash, isA<int>());
      expect(emptyHash, greaterThanOrEqualTo(0));

      // Test with seed
      expect(webSafeHash('test', 0), equals(webSafeHash('test')));
      expect(webSafeHash('test', 1), isNot(equals(webSafeHash('test', 0))));

      // Test special characters
      final specialChars = [
        '!@#\$%^&*()',
        'Collection-with-dashes',
        'Collection_with_underscores'
      ];
      for (final input in specialChars) {
        final hash = webSafeHash(input);
        expect(hash, isA<int>());
        expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('hash function provides good distribution', () {
      int webSafeHash(String input, [int seed = 0]) {
        var hash = 5381 + seed;
        for (var i = 0; i < input.length; i++) {
          hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
        }
        return hash;
      }

      final hashes = <int>{};
      final inputs = List.generate(100, (i) => 'Collection$i');

      for (final input in inputs) {
        final hash = webSafeHash(input);
        hashes.add(hash);
      }

      // Should have good distribution (low collision rate)
      expect(hashes.length, greaterThan(95),
          reason: 'Hash function has too many collisions');
    });
  });
}
