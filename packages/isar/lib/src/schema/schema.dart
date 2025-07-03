part of isar;

/// This schema either represents a collection or embedded object.
class Schema<OBJ> {
  /// @nodoc
  @protected
  Schema({
    int? id,
    this.idGenerator,
    required this.name,
    required this.properties,
    required this.estimateSize,
    required this.serialize,
    required this.deserialize,
    required this.deserializeProp,
  }) : _id = id,
       assert(id != null || idGenerator != null, 'Either id or idGenerator must be provided');

  /// @nodoc
  @protected
  factory Schema.fromJson(Map<String, dynamic> json) {
    return Schema(
      id: -1,
      name: json['name'] as String,
      properties: {
        for (final property in json['properties'] as List<dynamic>)
          (property as Map<String, dynamic>)['name'] as String:
              PropertySchema.fromJson(property),
      },
      estimateSize: (_, __, ___) => throw UnimplementedError(),
      serialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserialize: (_, __, ___, ____) => throw UnimplementedError(),
      deserializeProp: (_, __, ___, ____) => throw UnimplementedError(),
    );
  }

  /// Internal id of this collection or embedded object.
  final int? _id;

  /// Function to generate the internal id of this collection or embedded object.
  final int Function()? idGenerator;

  /// Internal id of this collection or embedded object.
  int get id => _id ?? idGenerator!();

  /// Name of the collection or embedded object
  final String name;

  /// Whether this is an embedded object
  bool get embedded => true;

  /// A map of name -> property pairs
  final Map<String, PropertySchema> properties;

  /// @nodoc
  @protected
  final EstimateSize<OBJ> estimateSize;

  /// @nodoc
  @protected
  final Serialize<OBJ> serialize;

  /// @nodoc
  @protected
  final Deserialize<OBJ> deserialize;

  /// @nodoc
  @protected
  final DeserializeProp deserializeProp;

  /// Returns a property by its name or throws an error.
  @pragma('vm:prefer-inline')
  PropertySchema property(String propertyName) {
    final property = properties[propertyName];
    if (property != null) {
      return property;
    } else {
      throw IsarError('Unknown property "$propertyName"');
    }
  }

  /// @nodoc
  @protected
  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'embedded': embedded,
      'properties': [
        for (final property in properties.values) property.toJson(),
      ],
    };

    return json;
  }

  /// @nodoc
  @protected
  Type get type => OBJ;
}

/// @nodoc
@protected
typedef EstimateSize<T> = int Function(
  T object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef Serialize<T> = void Function(
  T object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef Deserialize<T> = T Function(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef DeserializeProp = dynamic Function(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
);
