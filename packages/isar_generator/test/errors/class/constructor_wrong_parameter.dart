// constructor parameter type does not match property type

import 'package:isar/isar.dart';

@collection
class Model {
  Model();

  Id? id;

  String prop1 = '5';
}
