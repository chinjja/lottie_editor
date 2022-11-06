import 'package:isar/isar.dart';

part 'model.g.dart';

@collection
class Keyframe {
  Id id = Isar.autoIncrement;

  final items = IsarLinks<Item>();

  @Backlink(to: 'next')
  final prev = IsarLink<Keyframe>();
  final next = IsarLink<Keyframe>();
}

@collection
class Item {
  Id id = Isar.autoIncrement;

  @Backlink(to: 'items')
  final keyframes = IsarLinks<Keyframe>();
}
