import 'package:test/test.dart';

/// Web-safe hash function that generates consistent IDs across platforms
/// without using large integer literals that break JavaScript compilation
int _webSafeHash(String input, [int seed = 0]) {
  // Use a simple but effective hash algorithm that works on all platforms
  // This is based on the djb2 algorithm but modified to stay within safe integer range
  var hash = 5381 + seed;
  for (var i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return hash;
}

void main() {
  group('_webSafeHash', () {
    test('generates consistent hash values for same input', () {
      const input = 'TestCollection';
      final hash1 = _webSafeHash(input);
      final hash2 = _webSafeHash(input);
      final hash3 = _webSafeHash(input);
      
      expect(hash1, equals(hash2));
      expect(hash2, equals(hash3));
      expect(hash1, equals(hash3));
    });

    test('generates different values for different inputs', () {
      final hash1 = _webSafeHash('Collection1');
      final hash2 = _webSafeHash('Collection2');
      final hash3 = _webSafeHash('DifferentName');
      final hash4 = _webSafeHash('');
      
      expect(hash1, isNot(equals(hash2)));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1, isNot(equals(hash4)));
      expect(hash2, isNot(equals(hash3)));
      expect(hash2, isNot(equals(hash4)));
      expect(hash3, isNot(equals(hash4)));
    });

    test('stays within JavaScript safe integer range', () {
      const maxSafeInt = 0x7FFFFFFF; // 2^31 - 1
      
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
        final hash = _webSafeHash(input);
        expect(hash, lessThanOrEqualTo(maxSafeInt), 
               reason: 'Hash for "$input" exceeds safe integer range');
        expect(hash, greaterThanOrEqualTo(0), 
               reason: 'Hash for "$input" is negative');
      }
    });

    test('handles seed parameter correctly', () {
      const input = 'TestCollection';
      final hashNoSeed = _webSafeHash(input);
      final hashSeed0 = _webSafeHash(input, 0);
      final hashSeed1 = _webSafeHash(input, 1);
      final hashSeed100 = _webSafeHash(input, 100);
      
      expect(hashNoSeed, equals(hashSeed0));
      expect(hashSeed1, isNot(equals(hashNoSeed)));
      expect(hashSeed100, isNot(equals(hashNoSeed)));
      expect(hashSeed1, isNot(equals(hashSeed100)));
    });

    test('handles empty string', () {
      final hash = _webSafeHash('');
      expect(hash, isA<int>());
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('handles special characters', () {
      final specialChars = [
        '!@#\$%^&*()',
        'Collection-with-dashes',
        'Collection_with_underscores',
        'Collection.with.dots',
        'Collection with spaces',
        'Collection\nwith\nnewlines',
        'Collection\twith\ttabs',
      ];
      
      for (final input in specialChars) {
        final hash = _webSafeHash(input);
        expect(hash, isA<int>());
        expect(hash, greaterThanOrEqualTo(0));
        expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('generates reasonable distribution', () {
      final hashes = <int>{};
      final inputs = List.generate(1000, (i) => 'Collection$i');
      
      for (final input in inputs) {
        final hash = _webSafeHash(input);
        hashes.add(hash);
      }
      
      // Should have good distribution (low collision rate)
      // With 1000 inputs, we expect close to 1000 unique hashes
      expect(hashes.length, greaterThan(990), 
             reason: 'Hash function has too many collisions');
    });

    test('is deterministic across multiple runs', () {
      const input = 'DeterministicTest';
      final expectedHash = _webSafeHash(input);
      
      // Run multiple times to ensure consistency
      for (var i = 0; i < 100; i++) {
        expect(_webSafeHash(input), equals(expectedHash));
      }
    });
  });
}
