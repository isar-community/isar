import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class IsarAnalyzer {
  ObjectInfo analyzeCollection(Element2 element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement2;

    final properties = <ObjectProperty>[];
    final links = <ObjectLink>[];
    for (final propertyElement in modelClass.allAccessors) {
      if (propertyElement.isLink || propertyElement.isLinks) {
        final link = analyzeObjectLink(propertyElement);
        links.add(link);
      } else {
        final property = analyzeObjectProperty(propertyElement, constructor);
        properties.add(property);
      }
    }
    _checkValidPropertiesConstructor(properties, constructor);
    if (links.map((e) => e.isarName).distinct().length != links.length) {
      err('Two or more links have the same name.', modelClass);
    }

    final indexes = <ObjectIndex>[];
    for (final propertyElement in modelClass.allAccessors) {
      indexes.addAll(analyzeObjectIndex(properties, propertyElement));
    }
    if (indexes.map((e) => e.name).distinct().length != indexes.length) {
      err('Two or more indexes have the same name.', modelClass);
    }

    final idProperties = properties.where((it) => it.isId);
    if (idProperties.isEmpty) {
      err(
        'No id property defined. Use the "Id" type for your id property.',
        modelClass,
      );
    } else if (idProperties.length > 1) {
      err('Two or more properties with type "Id" defined.', modelClass);
    }

    return ObjectInfo(
      dartName: modelClass.displayName,
      isarName: modelClass.isarName,
      accessor: modelClass.collectionAccessor,
      properties: properties,
      embeddedDartNames: _getEmbeddedDartNames(element),
      indexes: indexes,
      links: links,
    );
  }

  ObjectInfo analyzeEmbedded(Element2 element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement2;

    if (constructor.formalParameters.any((e) => e.isRequired)) {
      err(
        'Constructors of embedded objects must not have required parameters.',
        constructor,
      );
    }

    final properties = <ObjectProperty>[];
    for (final propertyElement in modelClass.allAccessors) {
      if (propertyElement.isLink || propertyElement.isLinks) {
        err('Embedded objects must not contain links', propertyElement);
      } else {
        final property = analyzeObjectProperty(propertyElement, constructor);
        properties.add(property);
      }
    }
    _checkValidPropertiesConstructor(properties, constructor);

    final hasIndex = modelClass.allAccessors.any(
      (it) => it.indexAnnotations.isNotEmpty,
    );
    if (hasIndex) {
      err('Embedded objects must not have indexes.', modelClass);
    }

    final hasIdProperty = properties.any((it) => it.isId);
    if (hasIdProperty) {
      err('Embedded objects must not define an id.', modelClass);
    }

    return ObjectInfo(
      dartName: modelClass.displayName,
      isarName: modelClass.isarName,
      properties: properties,
    );
  }

  ConstructorElement2 _checkValidClass(Element2 modelClass) {
    if (modelClass is! ClassElement2 ||
        modelClass is EnumElement2 ||
        modelClass is MixinElement2) {
      err(
        'Only classes may be annotated with @Collection or @Embedded.',
        modelClass,
      );
    }

    if (modelClass.isAbstract) {
      err('Class must not be abstract.', modelClass);
    }

    if (!modelClass.isPublic) {
      err('Class must be public.', modelClass);
    }

    final constructor = modelClass.constructors2
        .firstOrNullWhere((ConstructorElement2 c) => c.firstFragment.periodOffset == null);
    if (constructor == null) {
      err('Class needs an unnamed constructor.', modelClass);
    }

    final hasCollectionSupertype = modelClass.allSupertypes.any((type) {
      return type.element3.collectionAnnotation != null ||
          type.element3.embeddedAnnotation != null;
    });
    if (hasCollectionSupertype) {
      err(
        'Class must not have a supertype annotated with @Collection or '
        '@Embedded.',
        modelClass,
      );
    }

    return constructor;
  }

  void _checkValidPropertiesConstructor(
    List<ObjectProperty> properties,
    ConstructorElement2 constructor,
  ) {
    if (properties.map((e) => e.isarName).distinct().length !=
        properties.length) {
      err(
        'Two or more properties have the same name.',
        constructor.enclosingElement2,
      );
    }

    final unknownConstructorParameter = constructor.formalParameters.firstOrNullWhere(
      (p) => p.isRequired && properties.none((e) => e.dartName == p.name3),
    );
    if (unknownConstructorParameter != null) {
      err(
        'Constructor parameter does not match a property.',
        unknownConstructorParameter,
      );
    }
  }

  Map<String, String> _getEmbeddedDartNames(ClassElement2 element) {
    void fillNames(Map<String, String> names, ClassElement2 element) {
      for (final property in element.allAccessors) {
        final type = property.type.scalarType.element3;
        if (type is ClassElement2 && type.embeddedAnnotation != null) {
          final isarName = type.isarName;
          if (!names.containsKey(isarName)) {
            names[type.isarName] = type.displayName;
            fillNames(names, type);
          }
        }
      }
    }

    final names = <String, String>{};
    fillNames(names, element);
    return names;
  }

  ObjectProperty analyzeObjectProperty(
    PropertyInducingElement2 property,
    ConstructorElement2 constructor,
  ) {
    final dartType = property.type;
    final scalarDartType = dartType.scalarType;
    Map<String, dynamic>? enumMap;
    String? enumPropertyName;
    String? defaultEnumElement;

    late final IsarType isarType;
    if (scalarDartType.element3 is EnumElement2) {
      final enumeratedAnn = property.enumeratedAnnotation;
      if (enumeratedAnn == null) {
        err('Enum property must be annotated with @enumerated.', property);
      }

      final enumClass = scalarDartType.element3! as EnumElement2;
      final enumElements =
          enumClass.fields2.where((f) => f.isEnumConstant).toList();
      defaultEnumElement = '${enumClass.name3}.${enumElements.first.name3}';

      if (enumeratedAnn.type == EnumType.ordinal) {
        isarType = dartType.isDartCoreList ? IsarType.byteList : IsarType.byte;
        enumMap = {
          for (var i = 0; i < enumElements.length; i++) enumElements[i].name3!: i,
        };
        enumPropertyName = 'index';
      } else if (enumeratedAnn.type == EnumType.ordinal32) {
        isarType = dartType.isDartCoreList ? IsarType.intList : IsarType.int;

        enumMap = {
          for (var i = 0; i < enumElements.length; i++) enumElements[i].name3!: i,
        };
        enumPropertyName = 'index';
      } else if (enumeratedAnn.type == EnumType.name) {
        isarType =
            dartType.isDartCoreList ? IsarType.stringList : IsarType.string;
        enumMap = {
          for (final value in enumElements) value.name3! : value.name3,
        };
        enumPropertyName = 'name';
      } else {
        enumPropertyName = enumeratedAnn.property;
        if (enumPropertyName == null) {
          err(
            'Enums with type EnumType.value must specify which property '
            'should be used.',
            property,
          );
        }
        final enumProperty = enumClass.getField2(enumPropertyName);
        if (enumProperty == null || enumProperty.isEnumConstant) {
          err('Enum property "$enumProperty" does not exist.', property);
        } else if (enumProperty is PropertyAccessorElement2) {
          err('Only fields are supported for enum properties', enumProperty);
        }

        final enumIsarType = enumProperty.type.isarType;
        if (enumIsarType != IsarType.byte &&
            enumIsarType != IsarType.int &&
            enumIsarType != IsarType.long &&
            enumIsarType != IsarType.string) {
          err('Unsupported enum property type.', enumProperty);
        }

        isarType =
            dartType.isDartCoreList ? enumIsarType!.listType : enumIsarType!;
        enumMap = {};
        for (final element in enumElements) {
          final property2 =
              element.computeConstantValue()!.getField(enumPropertyName)!;
          final propertyValue = property2.toBoolValue() ??
              property2.toIntValue() ??
              property2.toDoubleValue() ??
              property2.toStringValue();
          if (propertyValue == null) {
            err(
              'Null values are not supported for enum properties.',
              property2.variable2,
            );
          }

          if (enumMap.values.contains(propertyValue)) {
            err(
              'Enum property has duplicate values.',
              property2.variable2,
            );
          }
          enumMap[element.name3!] = propertyValue;
        }
      }
    } else {
      if (dartType.isarType != null) {
        isarType = dartType.isarType!;
      } else {
        err(
          'Unsupported type. Please annotate the property with @ignore.',
          property,
        );
      }
    }

    final nullable = dartType.nullabilitySuffix != NullabilitySuffix.none;
    final elementNullable = isarType.isList &&
        dartType.scalarType.nullabilitySuffix != NullabilitySuffix.none;

    if ((isarType == IsarType.byte && nullable) ||
        (isarType == IsarType.byteList && elementNullable)) {
      err('Bytes must not be nullable.', property);
    }

    final constructorParameter =
        constructor.formalParameters.firstOrNullWhere((p) => p.name3 == property.name3);
    int? constructorPosition;
    late PropertyDeser deserialize;
    if (constructorParameter != null) {
      if (constructorParameter.type != property.type) {
        err(
          'Constructor parameter type does not match property type',
          constructorParameter,
        );
      }
      deserialize = constructorParameter.isNamed
          ? PropertyDeser.namedParam
          : PropertyDeser.positionalParam;
      constructorPosition =
          constructor.formalParameters.indexOf(constructorParameter);
    } else {
      deserialize =
          property.setter2 == null ? PropertyDeser.none : PropertyDeser.assign;
    }

    return ObjectProperty(
      dartName: property.displayName,
      isarName: property.isarName,
      typeClassName: dartType.scalarType.element3!.name3!,
      targetIsarName: isarType.containsObject
          ? dartType.scalarType.element3!.isarName
          : null,
      isarType: isarType,
      isId: dartType.isIsarId,
      enumMap: enumMap,
      enumProperty: enumPropertyName,
      defaultEnumElement: defaultEnumElement,
      nullable: nullable,
      elementNullable: elementNullable,
      userDefaultValue: constructorParameter?.defaultValueCode,
      deserialize: deserialize,
      assignable: property.setter2 != null,
      constructorPosition: constructorPosition,
    );
  }

  ObjectLink analyzeObjectLink(PropertyInducingElement2 property) {
    if (property.type.nullabilitySuffix != NullabilitySuffix.none) {
      err('Link properties must not be nullable.', property);
    } else if (property.isLate) {
      err('Link properties must not be late.', property);
    }

    final type = property.type as ParameterizedType;
    final linkType = type.typeArguments[0];
    if (linkType.nullabilitySuffix != NullabilitySuffix.none) {
      err('Links type must not be nullable.', property);
    }

    final targetCol = linkType.element3! as ClassElement2;
    if (targetCol.collectionAnnotation == null) {
      err('Link target is not annotated with @collection');
    }

    final backlinkAnn = property.backlinkAnnotation;
    String? targetLinkIsarName;
    if (backlinkAnn != null) {
      final targetProperty = targetCol.allAccessors
          .firstOrNullWhere((e) => e.displayName == backlinkAnn.to);
      if (targetProperty == null) {
        err('Target of Backlink does not exist', property);
      } else if (targetProperty.backlinkAnnotation != null) {
        err('Target of Backlink is also a backlink', property);
      }

      if (!targetProperty.isLink && !targetProperty.isLinks) {
        err('Target of backlink is not a link', property);
      }

      final targetLink = analyzeObjectLink(targetProperty);
      targetLinkIsarName = targetLink.isarName;
    }

    return ObjectLink(
      dartName: property.displayName,
      isarName: property.isarName,
      targetLinkIsarName: targetLinkIsarName,
      targetCollectionDartName: linkType.element3!.name3!,
      targetCollectionIsarName: targetCol.isarName,
      isSingle: property.isLink,
    );
  }

  Iterable<ObjectIndex> analyzeObjectIndex(
    List<ObjectProperty> properties,
    PropertyInducingElement2 element,
  ) sync* {
    final property =
        properties.firstOrNullWhere((it) => it.dartName == element.name3);
    if (property == null || property.isId) {
      return;
    }

    for (final index in element.indexAnnotations) {
      final indexProperties = <ObjectIndexProperty>[];
      final isString = property.isarType == IsarType.string ||
          property.isarType == IsarType.stringList;
      final defaultType = property.isarType.isList || isString
          ? IndexType.hash
          : IndexType.value;

      indexProperties.add(
        ObjectIndexProperty(
          property: property,
          type: index.type ?? defaultType,
          caseSensitive: index.caseSensitive ?? isString,
        ),
      );
      for (final c in index.composite) {
        final compositeProperty =
            properties.firstOrNullWhere((it) => it.dartName == c.property);
        if (compositeProperty == null) {
          err('Property does not exist: "${c.property}".', element);
        } else if (compositeProperty.isId) {
          err('Ids cannot be indexed', element);
        } else {
          final isString = compositeProperty.isarType == IsarType.string ||
              compositeProperty.isarType == IsarType.stringList;
          final defaultType = compositeProperty.isarType.isList || isString
              ? IndexType.hash
              : IndexType.value;
          indexProperties.add(
            ObjectIndexProperty(
              property: compositeProperty,
              type: c.type ?? defaultType,
              caseSensitive: c.caseSensitive ?? isString,
            ),
          );
        }
      }

      final name = index.name ??
          indexProperties.map((e) => e.property.isarName).join('_');
      checkIsarName(name, element);

      final objectIndex = ObjectIndex(
        name: name,
        properties: indexProperties,
        unique: index.unique,
        replace: index.replace,
      );
      _verifyObjectIndex(objectIndex, element);

      yield objectIndex;
    }
  }

  void _verifyObjectIndex(ObjectIndex index, Element2 element) {
    final properties = index.properties;

    if (properties.map((it) => it.property.isarName).distinct().length !=
        properties.length) {
      err('Composite index contains duplicate properties.', element);
    }

    for (var i = 0; i < properties.length; i++) {
      final property = properties[i];
      if (property.isarType.isList &&
          property.type != IndexType.hash &&
          properties.length > 1) {
        err('Composite indexes do not support non-hashed lists.', element);
      }
      if (property.isarType.containsFloat && i != properties.lastIndex) {
        err(
          'Only the last property of a composite index may be a '
          'double value.',
          element,
        );
      }
      if (property.isarType == IsarType.string) {
        if (property.type != IndexType.hash && i != properties.lastIndex) {
          err(
            'Only the last property of a composite index may be a '
            'non-hashed String.',
            element,
          );
        }
      }
      if (property.isarType.containsObject) {
        err(
          'Embedded objects may not be indexed.',
          element,
        );
      }
      if (property.type != IndexType.value) {
        if (!property.isarType.isList && property.isarType != IsarType.string) {
          err('Only Strings and Lists may be hashed.', element);
        } else if (property.isarType.containsFloat) {
          err('List<double> may must not be hashed.', element);
        }
      }
      if (property.isarType != IsarType.stringList &&
          property.type == IndexType.hashElements) {
        err('Only String lists may have hashed elements.', element);
      }
    }

    if (!index.unique && index.replace) {
      err('Only unique indexes can replace.', element);
    }
  }
}
