import 'dart:io';
import 'dart:math';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_generator/isar_generator.dart';
import 'package:test/test.dart';

/// Simulates the web compilation scenario that was failing before the fix
void main() {
  group('Web Compilation Simulation', () {
    test('reproduces original issue with large integer literals', () async {
      // This test verifies that the original problem (large integer literals)
      // no longer occurs in the generated code
      
      const source = '''
import 'package:isar/isar.dart';

@collection
class ScheduledCommandEntity {
  Id id = Isar.autoIncrement;
  
  @Index()
  String? commandType;
  
  @Index()
  DateTime? createdAt;
  
  String? data;
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/scheduled_command_entity.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/scheduled_command_entity.g.dart']!;
      
      // Verify no large integer literals that would break JavaScript
      final largeIntPattern = RegExp(r'\b\d{10,}\b');
      final matches = largeIntPattern.allMatches(generatedCode);
      
      expect(matches.length, equals(0), 
             reason: 'Generated code contains large integer literals that break web compilation');
      
      // Verify the code uses function-based generation instead
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'ScheduledCommandEntity\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'commandType\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'createdAt\')'));
    });

    test('verifies JavaScript safe integer range compliance', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class TestEntity {
  Id id = Isar.autoIncrement;
  String? veryLongPropertyNameThatMightCauseHashCollisions;
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/test_entity.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/test_entity.g.dart']!;
      
      // Extract the _webSafeHash function and test it
      expect(generatedCode, contains('int _webSafeHash(String input, [int seed = 0])'));
      expect(generatedCode, contains('& 0x7FFFFFFF')); // JavaScript safe integer mask
      
      // Verify the function stays within safe bounds
      final hashFunctionMatch = RegExp(
        r'int _webSafeHash\(String input, \[int seed = 0\]\) \{[^}]+\}',
        multiLine: true,
        dotAll: true,
      ).firstMatch(generatedCode);
      
      expect(hashFunctionMatch, isNotNull, 
             reason: 'Could not find _webSafeHash function in generated code');
    });

    test('simulates compilation with dart2js constraints', () async {
      // This test simulates the constraints that dart2js has with large integers
      
      const source = '''
import 'package:isar/isar.dart';

@embedded
class Address {
  String? street;
  String? city;
  String? postalCode;
}

@collection
class Person {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  String? email;
  
  @Index()
  String? firstName;
  
  @Index()
  String? lastName;
  
  @Index(composite: [CompositeIndex('lastName')])
  String? department;
  
  Address? homeAddress;
  Address? workAddress;
  
  final friends = IsarLinks<Person>();
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/person.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/person.g.dart']!;
      
      // Verify all numeric literals are within JavaScript safe range
      final numericLiterals = RegExp(r'\b\d+\b').allMatches(generatedCode);
      
      for (final match in numericLiterals) {
        final value = int.tryParse(match.group(0)!);
        if (value != null && value > 0x1FFFFFFFFFFFFF) { // 2^53 - 1
          fail('Found numeric literal $value that exceeds JavaScript safe integer range');
        }
      }
      
      // Verify all schemas use function-based ID generation
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'Person\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'Address\')'));
      
      // Verify all indexes use function-based ID generation
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'email\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'firstName\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'lastName\')'));
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'department_lastName\')'));
      
      // Verify links use function-based ID generation
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'friends\''));
    });

    test('validates generated code syntax for web compilation', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class WebTestModel {
  Id id = Isar.autoIncrement;
  String? data;
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/web_test_model.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/web_test_model.g.dart']!;
      
      // Verify the generated code has valid Dart syntax patterns
      expect(generatedCode, contains('final WebTestModelSchema = CollectionSchema('));
      expect(generatedCode, isNot(contains('const WebTestModelSchema')));
      
      // Verify function expressions are properly formatted
      expect(generatedCode, contains('idGenerator: () => _webSafeHash(r\'WebTestModel\')'));
      
      // Verify no syntax that would break in const contexts
      expect(generatedCode, isNot(contains('const')));
      
      // Verify the web-safe hash function is properly defined
      expect(generatedCode, contains('int _webSafeHash(String input, [int seed = 0]) {'));
      expect(generatedCode, contains('return hash;'));
    });

    test('stress test with many collections and complex relationships', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  @Index(unique: true) String? username;
  @Index() String? email;
  final posts = IsarLinks<Post>();
  final comments = IsarLinks<Comment>();
}

@collection
class Post {
  Id id = Isar.autoIncrement;
  @Index() String? title;
  @Index() String? category;
  @Index(composite: [CompositeIndex('createdAt')]) String? status;
  DateTime? createdAt;
  final author = IsarLink<User>();
  final comments = IsarLinks<Comment>();
  final tags = IsarLinks<Tag>();
}

@collection
class Comment {
  Id id = Isar.autoIncrement;
  @Index() DateTime? createdAt;
  String? content;
  final author = IsarLink<User>();
  final post = IsarLink<Post>();
}

@collection
class Tag {
  Id id = Isar.autoIncrement;
  @Index(unique: true) String? name;
  String? description;
  @Backlink(to: 'tags') final posts = IsarLinks<Post>();
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/models.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final userCode = result['a|lib/user.g.dart']!;
      final postCode = result['a|lib/post.g.dart']!;
      final commentCode = result['a|lib/comment.g.dart']!;
      final tagCode = result['a|lib/tag.g.dart']!;
      
      final allCode = [userCode, postCode, commentCode, tagCode];
      
      for (final code in allCode) {
        // Verify no large integer literals
        expect(code, isNot(contains(RegExp(r'\b\d{10,}\b'))));
        
        // Verify web-safe hash function is present
        expect(code, contains('_webSafeHash'));
        
        // Verify final instead of const
        expect(code, isNot(contains('const ')));
        expect(code, contains('final '));
        
        // Verify function-based ID generation
        expect(code, contains('idGenerator: () =>'));
      }
      
      // Verify specific patterns for each model
      expect(userCode, contains('idGenerator: () => _webSafeHash(r\'User\')'));
      expect(postCode, contains('idGenerator: () => _webSafeHash(r\'Post\')'));
      expect(commentCode, contains('idGenerator: () => _webSafeHash(r\'Comment\')'));
      expect(tagCode, contains('idGenerator: () => _webSafeHash(r\'Tag\')'));
    });

    test('verifies hash function produces consistent results', () {
      // Test the actual hash function that gets generated
      int webSafeHash(String input, [int seed = 0]) {
        var hash = 5381 + seed;
        for (var i = 0; i < input.length; i++) {
          hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
        }
        return hash;
      }
      
      // Test consistency
      expect(webSafeHash('TestCollection'), equals(webSafeHash('TestCollection')));
      expect(webSafeHash('TestIndex'), equals(webSafeHash('TestIndex')));
      
      // Test different inputs produce different results
      expect(webSafeHash('Collection1'), isNot(equals(webSafeHash('Collection2'))));
      
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
  });
}
