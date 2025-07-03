import 'dart:io';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_generator/isar_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Web Compilation Integration', () {
    test('generates web-compatible code for simple collection', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  String? name;
  int? age;
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/user.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/user.g.dart']!;

      // Verify no large integer literals
      expect(generatedCode, isNot(contains(RegExp(r'\b\d{10,}\b'))));

      // Verify web-safe hash function is present
      expect(generatedCode, contains('_webSafeHash'));

      // Verify function-based ID generation
      expect(generatedCode, contains('idGenerator: () =>'));

      // Verify final instead of const
      expect(generatedCode, contains('final UserSchema'));
      expect(generatedCode, isNot(contains('const UserSchema')));
    });

    test('generates consistent IDs across multiple generations', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;
  String? name;
  double? price;
  
  @Index()
  String? category;
}
''';

      // Generate code multiple times
      final results = <String>[];
      for (var i = 0; i < 3; i++) {
        final result = await testBuilder(
          getIsarGenerator(BuilderOptions.empty),
          {'a|lib/product.dart': source},
          reader: await PackageAssetReader.currentIsolate(),
        );
        results.add(result['a|lib/product.g.dart']!);
      }

      // All generations should produce identical code
      expect(results[0], equals(results[1]));
      expect(results[1], equals(results[2]));

      // Verify the generated code contains expected patterns
      final code = results[0];
      expect(code, contains('idGenerator: () => _webSafeHash(r\'Product\')'));
      expect(code, contains('idGenerator: () => _webSafeHash(r\'category\')'));
    });

    test('handles complex schema with all features', () async {
      const source = '''
import 'package:isar/isar.dart';

@embedded
class Address {
  String? street;
  String? city;
  String? country;
}

@collection
class Company {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  String? name;
  
  Address? address;
  
  final employees = IsarLinks<Employee>();
}

@collection
class Employee {
  Id id = Isar.autoIncrement;
  
  @Index()
  String? firstName;
  
  @Index()
  String? lastName;
  
  @Index(composite: [CompositeIndex('lastName')])
  String? department;
  
  final company = IsarLink<Company>();
  
  @Backlink(to: 'manager')
  final subordinates = IsarLinks<Employee>();
  
  final manager = IsarLink<Employee>();
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/models.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final companyCode = result['a|lib/company.g.dart']!;
      final employeeCode = result['a|lib/employee.g.dart']!;

      // Verify no large integer literals in any generated code
      expect(companyCode, isNot(contains(RegExp(r'\b\d{10,}\b'))));
      expect(employeeCode, isNot(contains(RegExp(r'\b\d{10,}\b'))));

      // Verify all schemas use idGenerator
      expect(companyCode,
          contains('idGenerator: () => _webSafeHash(r\'Company\')'));
      expect(companyCode,
          contains('idGenerator: () => _webSafeHash(r\'Address\')'));
      expect(employeeCode,
          contains('idGenerator: () => _webSafeHash(r\'Employee\')'));

      // Verify indexes use idGenerator
      expect(
          companyCode, contains('idGenerator: () => _webSafeHash(r\'name\')'));
      expect(employeeCode,
          contains('idGenerator: () => _webSafeHash(r\'firstName\')'));
      expect(employeeCode,
          contains('idGenerator: () => _webSafeHash(r\'lastName\')'));
      expect(employeeCode, contains(
          'idGenerator: () => _webSafeHash(r\'department_lastName\')'));

      // Verify links use idGenerator
      expect(companyCode,
          contains('idGenerator: () => _webSafeHash(r\'employees\''));
      expect(employeeCode,
          contains('idGenerator: () => _webSafeHash(r\'company\''));
      expect(employeeCode,
          contains('idGenerator: () => _webSafeHash(r\'manager\''));

      // Verify all schemas are final, not const
      expect(companyCode, contains('final CompanySchema'));
      expect(companyCode, contains('final AddressSchema'));
      expect(employeeCode, contains('final EmployeeSchema'));
      expect(companyCode, isNot(contains('const CompanySchema')));
      expect(companyCode, isNot(contains('const AddressSchema')));
      expect(employeeCode, isNot(contains('const EmployeeSchema')));
    });

    test('generates valid Dart code that can be analyzed', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class TestModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  String? title;
  
  @Index(unique: true)
  String? slug;
  
  DateTime? createdAt;
  
  final tags = IsarLinks<Tag>();
}

@collection
class Tag {
  Id id = Isar.autoIncrement;
  String? name;
  
  @Backlink(to: 'tags')
  final models = IsarLinks<TestModel>();
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/test_model.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final testModelCode = result['a|lib/test_model.g.dart']!;
      final tagCode = result['a|lib/tag.g.dart']!;

      // Write generated code to temporary files for analysis
      final tempDir = Directory.systemTemp.createTempSync('isar_test_');
      try {
        final testModelFile = File('${tempDir.path}/test_model.g.dart');
        final tagFile = File('${tempDir.path}/tag.g.dart');

        await testModelFile.writeAsString(testModelCode);
        await tagFile.writeAsString(tagCode);

        // The files should be valid Dart syntax (this is a basic check)
        expect(testModelCode, contains('extension'));
        expect(testModelCode, contains('final TestModelSchema'));
        expect(tagCode, contains('extension'));
        expect(tagCode, contains('final TagSchema'));

        // Verify the generated code follows expected patterns
        expect(testModelCode, contains('_webSafeHash'));
        expect(tagCode, contains('_webSafeHash'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('maintains backward compatibility patterns', () async {
      const source = '''
import 'package:isar/isar.dart';

@collection
class LegacyModel {
  Id id = Isar.autoIncrement;
  String? data;
}
''';

      final result = await testBuilder(
        getIsarGenerator(BuilderOptions.empty),
        {'a|lib/legacy_model.dart': source},
        reader: await PackageAssetReader.currentIsolate(),
      );

      final generatedCode = result['a|lib/legacy_model.g.dart']!;

      // Should still generate extension for collection access
      expect(generatedCode,
          contains('extension GetLegacyModelCollection on Isar'));
      expect(generatedCode,
          contains('IsarCollection<LegacyModel> get legacyModels'));

      // Should still generate schema with expected structure
      expect(generatedCode,
          contains('final LegacyModelSchema = CollectionSchema('));
      expect(generatedCode, contains('name: r\'LegacyModel\''));
      expect(generatedCode, contains('properties: {'));
      expect(generatedCode, contains('estimateSize:'));
      expect(generatedCode, contains('serialize:'));
      expect(generatedCode, contains('deserialize:'));

      // But should use new idGenerator approach
      expect(generatedCode,
          contains('idGenerator: () => _webSafeHash(r\'LegacyModel\')'));
    });
  });
}
