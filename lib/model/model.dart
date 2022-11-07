import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';

@freezed
class Keyframe with _$Keyframe {
  const factory Keyframe({
    int? id,
    @Default(0) int frame,
    required String property,
    @Default(0) double value,
  }) = _Keyframe;
}

@freezed
class Item with _$Item {
  const factory Item.circle({
    int? id,
    @Default([]) List<Keyframe> keyframes,
    required Color color,
    required Offset tl,
    required Offset br,
  }) = _CircleItem;

  const factory Item.rectangle({
    int? id,
    @Default([]) List<Keyframe> keyframes,
    required Color color,
    required Offset tl,
    required Offset br,
  }) = _RectangleItem;
}

extension ItemX on Item {
  Item move(Offset d) {
    return copyWith(tl: tl + d, br: br + d);
  }

  Offset get center => tl + (br - tl) / 2;
}
