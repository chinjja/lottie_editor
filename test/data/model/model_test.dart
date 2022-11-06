import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lottie_editor/data/model/model.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Isar isar;

  setUp(() async {
    isar = await Isar.open([KeyframeSchema, ItemSchema]);
    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });
  test('isar', () async {
    expect(await isar.keyframes.count(), 0);

    final k1 = Keyframe();
    final k2 = Keyframe();
    await isar.writeTxn(() async {
      await isar.keyframes.put(k1);
      await isar.keyframes.put(k2);
      k1.next.value = k2;
      await k1.next.save();
    });

    final l1 = await isar.keyframes.get(k1.id);
    final l2 = await isar.keyframes.get(k2.id);

    expect(l1?.prev.value?.id, isNull);
    expect(l1?.next.value?.id, k2.id);

    expect(l2?.prev.value?.id, k1.id);
    expect(l2?.next.value?.id, isNull);
  });
}
