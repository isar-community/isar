---
title: Quickstart
---

# Quickstart

Holy smokes, you're here! Let's get started on using the coolest Flutter database out there...

We're going to be short on words and quick on code in this quickstart.

## 1. Add dependencies

Before the fun begins, we need to add a few packages to the `pubspec.yaml`. We can use pub to do the heavy lifting for us.

```bash
dart pub add isar:^0.0.0-placeholder isar_flutter_libs:^0.0.0-placeholder --hosted-url=https://pub.isar-community.dev
```

## 2. Annotate classes

Annotate your collection classes with `@collection` and choose an `Id` field.

```dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  late int id;

  String? name;

  int? age;
}
```

Ids uniquely identify objects in a collection and allow you to find them again later.

## 3. Run code generator

Execute the following command to start the `build_runner`:

```
dart run build_runner build
```

## 4. Open Isar instance

Open a new Isar instance and pass all of your collection schemas. Optionally you can specify an instance name and directory.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: dir.path,
);
```

## 5. Write and read

Once your instance is open, you can start using the collections.

All basic CRUD operations are available via the `IsarCollection`.

```dart
final newUser = User()
  ..id = isar!.users.autoIncrement()
  ..name = 'Jane Doe'
  ..age = 36;

await isar!.writeAsync((isar) {
  return isar.users.put(newUser); // insert & update
});

final existingUser = isar!.users.get(newUser.id); // get

if (existingUser != null) {
  await isar!.writeAsync((isar) {
    return isar.users.delete(existingUser.id); // delete
  });
}
```

## Other resources

Are you a visual learner? Check out these videos to get started with Isar:
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
