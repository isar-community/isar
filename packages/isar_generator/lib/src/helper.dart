import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart' hide Name;
import 'package:source_gen/source_gen.dart';

const TypeChecker _collectionChecker = TypeChecker.fromRuntime(Collection);
const TypeChecker _enumeratedChecker = TypeChecker.fromRuntime(Enumerated);
const TypeChecker _embeddedChecker = TypeChecker.fromRuntime(Embedded);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(Ignore);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(Name);
const TypeChecker _indexChecker = TypeChecker.fromRuntime(Index);
const TypeChecker _backlinkChecker = TypeChecker.fromRuntime(Backlink);

extension ClassElementX on ClassElement2 {
  bool get hasZeroArgsConstructor {
    return constructors2.any(
      (ConstructorElement2 c) =>
          c.isPublic &&
          !c.formalParameters.any((FormalParameterElement p) => !p.isOptional),
    );
  }

  List<PropertyInducingElement2> get allAccessors {
    final ignoreFields =
        collectionAnnotation?.ignore ?? embeddedAnnotation!.ignore;
    final accessors = [...setters2,...getters2];
    return [
      ...accessors.mapNotNull((e) => e.variable3),

      if (collectionAnnotation?.inheritance ?? embeddedAnnotation!.inheritance)
        for (final InterfaceType supertype in allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...[...supertype.getters,...supertype.setters].mapNotNull((e) => e.variable3),
        ],
    ]
        .where(
          (PropertyInducingElement2 e) =>
              e.isPublic &&
              !e.isStatic &&
              !_ignoreChecker.hasAnnotationOf(e.nonSynthetic2) &&
              !ignoreFields.contains(e.name3),
        )
        .distinctBy((e) => e.name3)
        .toList();
  }

  List<String> get enumConsts {
    return fields2
        .where((e) => e.isEnumConstant)
        .filter((e) => e.name3 != null)
        .map((e) => e.name3!)
        .toList();
  }
}

extension PropertyElementX on PropertyInducingElement2 {
  bool get isLink => type.element3!.name3 == 'IsarLink';

  bool get isLinks => type.element3!.name3 == 'IsarLinks';

  Enumerated? get enumeratedAnnotation {
    final ann = _enumeratedChecker.firstAnnotationOfExact(this);
    if (ann == null) {
      return null;
    }
    final typeIndex = ann.getField('type')!.getField('index')!.toIntValue()!;
    return Enumerated(
      EnumType.values[typeIndex],
      ann.getField('property')?.toStringValue(),
    );
  }

  Backlink? get backlinkAnnotation {
    final ann = _backlinkChecker.firstAnnotationOfExact(this);
    if (ann == null) {
      return null;
    }
    return Backlink(to: ann.getField('to')!.toStringValue()!);
  }

  List<Index> get indexAnnotations {
    return _indexChecker.annotationsOfExact(this).map((DartObject ann) {
      final rawComposite = ann.getField('composite')!.toListValue();
      final composite = <CompositeIndex>[];
      if (rawComposite != null) {
        for (final c in rawComposite) {
          final indexTypeField = c.getField('type')!;
          IndexType? indexType;
          if (!indexTypeField.isNull) {
            final indexTypeIndex =
                indexTypeField.getField('index')!.toIntValue()!;
            indexType = IndexType.values[indexTypeIndex];
          }
          composite.add(
            CompositeIndex(
              c.getField('property')!.toStringValue()!,
              type: indexType,
              caseSensitive: c.getField('caseSensitive')!.toBoolValue(),
            ),
          );
        }
      }
      final indexTypeField = ann.getField('type')!;
      IndexType? indexType;
      if (!indexTypeField.isNull) {
        final indexTypeIndex = indexTypeField.getField('index')!.toIntValue()!;
        indexType = IndexType.values[indexTypeIndex];
      }
      return Index(
        name: ann.getField('name')!.toStringValue(),
        composite: composite,
        unique: ann.getField('unique')!.toBoolValue()!,
        replace: ann.getField('replace')!.toBoolValue()!,
        type: indexType,
        caseSensitive: ann.getField('caseSensitive')!.toBoolValue(),
      );
    }).toList();
  }
}

extension ElementX on Element2 {
  String get isarName {
    final ann = _nameChecker.firstAnnotationOfExact(this);
    late String name;
    if (ann == null) {
      name = displayName;
    } else {
      name = ann.getField('name')!.toStringValue()!;
    }
    checkIsarName(name, this);
    return name;
  }

  Collection? get collectionAnnotation {
    final ann = _collectionChecker.firstAnnotationOfExact(this);
    if (ann == null) {
      return null;
    }
    return Collection(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      accessor: ann.getField('accessor')!.toStringValue(),
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
    );
  }

  String get collectionAccessor {
    var accessor = collectionAnnotation?.accessor;
    if (accessor != null) {
      return accessor;
    }

    accessor = displayName.decapitalize();
    if (!accessor.endsWith('s')) {
      accessor += 's';
    }

    return accessor;
  }

  Embedded? get embeddedAnnotation {
    final ann = _embeddedChecker.firstAnnotationOfExact(this);
    if (ann == null) {
      return null;
    }
    return Embedded(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
    );
  }
}

void checkIsarName(String name, Element2 element) {
  if (name.isBlank || name.startsWith('_')) {
    err('Names must not be blank or start with "_".', element);
  }
}

Never err(String msg, [Element2? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}

