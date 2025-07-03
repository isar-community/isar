import 'package:isar/isar.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectInfo', () {
    test('idGenerator generates valid function string', () {
      final objectInfo = ObjectInfo(
        dartName: 'TestCollection',
        isarName: 'TestCollection',
        accessor: 'testCollections',
        properties: [],
      );
      
      final idGenerator = objectInfo.idGenerator;
      expect(idGenerator, isA<String>());
      expect(idGenerator, contains('_webSafeHash'));
      expect(idGenerator, contains('TestCollection'));
      expect(idGenerator, startsWith('() =>'));
      expect(idGenerator, matches(r"^\(\) => _webSafeHash\(r'TestCollection'\)$"));
    });

    test('idGenerator handles special characters in names', () {
      final objectInfo = ObjectInfo(
        dartName: 'Test_Collection',
        isarName: 'Test-Collection',
        accessor: 'testCollections',
        properties: [],
      );
      
      final idGenerator = objectInfo.idGenerator;
      expect(idGenerator, contains('Test-Collection'));
      expect(idGenerator, matches(r"^\(\) => _webSafeHash\(r'Test-Collection'\)$"));
    });
  });

  group('ObjectIndex', () {
    test('idGenerator generates valid function string', () {
      final index = ObjectIndex(
        name: 'testIndex',
        properties: [],
        unique: false,
        replace: false,
      );
      
      final idGenerator = index.idGenerator;
      expect(idGenerator, isA<String>());
      expect(idGenerator, contains('_webSafeHash'));
      expect(idGenerator, contains('testIndex'));
      expect(idGenerator, startsWith('() =>'));
      expect(idGenerator, matches(r"^\(\) => _webSafeHash\(r'testIndex'\)$"));
    });

    test('idGenerator handles different index names', () {
      final testCases = [
        'simpleIndex',
        'compound_index',
        'index-with-dashes',
        'IndexWithCamelCase',
        'index123',
      ];
      
      for (final indexName in testCases) {
        final index = ObjectIndex(
          name: indexName,
          properties: [],
          unique: false,
          replace: false,
        );
        
        final idGenerator = index.idGenerator;
        expect(idGenerator, contains(indexName));
        expect(idGenerator, matches(RegExp(r"^\(\) => _webSafeHash\(r'" + RegExp.escape(indexName) + r"'\)$")));
      }
    });
  });

  group('ObjectLink', () {
    test('idGenerator generates valid function string for regular link', () {
      final link = ObjectLink(
        dartName: 'testLink',
        isarName: 'testLink',
        targetLinkIsarName: null,
        targetCollectionDartName: 'TargetCollection',
        targetCollectionIsarName: 'TargetCollection',
        isSingle: true,
      );
      
      final objectIsarName = 'SourceCollection';
      final idGenerator = link.idGenerator(objectIsarName);
      
      expect(idGenerator, isA<String>());
      expect(idGenerator, contains('_webSafeHash'));
      expect(idGenerator, contains('testLink'));
      expect(idGenerator, contains('SourceCollection'));
      expect(idGenerator, startsWith('() =>'));
    });

    test('idGenerator generates valid function string for backlink', () {
      final link = ObjectLink(
        dartName: 'backLink',
        isarName: 'backLink',
        targetLinkIsarName: 'originalLink',
        targetCollectionDartName: 'TargetCollection',
        targetCollectionIsarName: 'TargetCollection',
        isSingle: false,
      );
      
      final objectIsarName = 'SourceCollection';
      final idGenerator = link.idGenerator(objectIsarName);
      
      expect(idGenerator, isA<String>());
      expect(idGenerator, contains('_webSafeHash'));
      expect(idGenerator, contains('originalLink'));
      expect(idGenerator, contains('TargetCollection'));
      expect(idGenerator, contains('1')); // seed for backlink
    });

    test('idGenerator handles different link configurations', () {
      final testCases = [
        {
          'isarName': 'simpleLink',
          'targetLinkIsarName': null,
          'targetCollection': 'Target1',
          'isBacklink': false,
        },
        {
          'isarName': 'backLink',
          'targetLinkIsarName': 'forwardLink',
          'targetCollection': 'Target2',
          'isBacklink': true,
        },
        {
          'isarName': 'link_with_underscores',
          'targetLinkIsarName': null,
          'targetCollection': 'Target_Collection',
          'isBacklink': false,
        },
      ];
      
      for (final testCase in testCases) {
        final link = ObjectLink(
          dartName: testCase['isarName'] as String,
          isarName: testCase['isarName'] as String,
          targetLinkIsarName: testCase['targetLinkIsarName'] as String?,
          targetCollectionDartName: testCase['targetCollection'] as String,
          targetCollectionIsarName: testCase['targetCollection'] as String,
          isSingle: true,
        );
        
        final idGenerator = link.idGenerator('SourceCollection');
        expect(idGenerator, isA<String>());
        expect(idGenerator, startsWith('() =>'));
        expect(idGenerator, contains('_webSafeHash'));
        
        if (testCase['isBacklink'] as bool) {
          expect(idGenerator, contains(testCase['targetLinkIsarName'] as String));
          expect(idGenerator, contains('1')); // backlink seed
        } else {
          expect(idGenerator, contains(testCase['isarName'] as String));
          expect(idGenerator, contains('0')); // regular link seed
        }
      }
    });

    test('isBacklink property works correctly', () {
      final regularLink = ObjectLink(
        dartName: 'regularLink',
        isarName: 'regularLink',
        targetLinkIsarName: null,
        targetCollectionDartName: 'Target',
        targetCollectionIsarName: 'Target',
        isSingle: true,
      );
      
      final backLink = ObjectLink(
        dartName: 'backLink',
        isarName: 'backLink',
        targetLinkIsarName: 'originalLink',
        targetCollectionDartName: 'Target',
        targetCollectionIsarName: 'Target',
        isSingle: false,
      );
      
      expect(regularLink.isBacklink, isFalse);
      expect(backLink.isBacklink, isTrue);
    });
  });
}
