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
class Model with _$Model {
  const factory Model({
    required Offset origin,
    required List<Offset> data,
  }) = _Model;
}

extension ModelX on Model {
  Model move(Offset offset) {
    return copyWith(
      origin: origin + offset,
      data: data.map((e) => e + offset).toList(),
    );
  }
}

@freezed
class Item with _$Item {
  const factory Item({
    int? id,
    @Default([]) List<Keyframe> keyframes,
    required Color color,
    required Matrix4 transform,
    required Model model,
  }) = _Item;
}

extension ItemX on Item {
  Item move(Offset d) {
    return copyWith(
      transform: transform
        ..clone()
        ..translate(d.dx, d.dy),
    );
  }
}
