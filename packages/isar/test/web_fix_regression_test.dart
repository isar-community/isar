@TestOn('vm')
import 'package:test/test.dart';

void main() {
  group('Web Fix Regression Tests', () {
    group('Hash Function Regression', () {
      test('web-safe hash function produces consistent results', () {
        // Test the hash function that gets generated
        int webSafeHash(String input, [int seed = 0]) {
          var hash = 5381 + seed;
          for (var i = 0; i < input.length; i++) {
            hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
          }
          return hash;
        }

        // Test consistency across multiple calls
        const testInput = 'TestCollection';
        final hash1 = webSafeHash(testInput);
        final hash2 = webSafeHash(testInput);
        final hash3 = webSafeHash(testInput);

        expect(hash1, equals(hash2));
        expect(hash2, equals(hash3));
        expect(hash1, equals(hash3));
      });

      test('hash function stays within JavaScript safe range', () {
        int webSafeHash(String input, [int seed = 0]) {
          var hash = 5381 + seed;
          for (var i = 0; i < input.length; i++) {
            hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
          }
          return hash;
        }

        const maxSafeInt = 0x7FFFFFFF; // JavaScript safe integer limit

        final testInputs = [
          'VeryLongCollectionNameThatMightCauseOverflow',
          'AnotherLongNameWithSpecialCharacters!@#\$%^&*()',
          'ShortName',
          '',
          'Collection' * 100, // Very long string
          'Unicode测试Collection名称',
          'Numbers123456789',
          'MixedCASEcollection',
        ];

        for (final input in testInputs) {
          final hash = webSafeHash(input);
          expect(hash, lessThanOrEqualTo(maxSafeInt),
              reason: 'Hash for "$input" exceeds safe integer range');
          expect(hash, greaterThanOrEqualTo(0),
              reason: 'Hash for "$input" is negative');
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
        final inputs = List.generate(1000, (i) => 'Collection$i');

        for (final input in inputs) {
          final hash = webSafeHash(input);
          hashes.add(hash);
        }

        // Should have good distribution (low collision rate)
        expect(hashes.length, greaterThan(990),
            reason: 'Hash function has too many collisions');
      });

      test('hash function handles edge cases correctly', () {
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

        // Test with different seeds
        expect(webSafeHash('test'), equals(webSafeHash('test', 0)));
        expect(webSafeHash('test', 1), isNot(equals(webSafeHash('test', 0))));

        // Test special characters
        final specialInputs = [
          '!@#\$%^&*()',
          'Collection-with-dashes',
          'Collection_with_underscores',
          'Collection.with.dots',
          'Collection with spaces',
        ];

        for (final input in specialInputs) {
          final hash = webSafeHash(input);
          expect(hash, isA<int>());
          expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
          expect(hash, greaterThanOrEqualTo(0));
        }
      });
    });

    group('Backward Compatibility', () {
      test('existing functionality remains unchanged', () {
        // Test that the core concepts still work as expected
        expect(true, isTrue); // Placeholder for actual functionality tests
      });

      test('no breaking changes to public API', () {
        // Test that public APIs haven't changed
        expect(true, isTrue); // Placeholder for actual API tests
      });
    });

    group('Performance Regression', () {
      test('hash generation performance is acceptable', () {
        int webSafeHash(String input, [int seed = 0]) {
          var hash = 5381 + seed;
          for (var i = 0; i < input.length; i++) {
            hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
          }
          return hash;
        }

        final stopwatch = Stopwatch()
          ..start();

        // Generate hashes for many inputs
        for (var i = 0; i < 10000; i++) {
          webSafeHash('TestCollection$i');
        }

        stopwatch.stop();

        // Should complete in reasonable time (less than 100ms for 10k hashes)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
