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
