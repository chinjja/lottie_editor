part of 'keyframe_cubit.dart';

@freezed
class KeyframeState with _$KeyframeState {
  const factory KeyframeState.initial() = _Initial;
  const factory KeyframeState.success({
    @Default([]) List<Keyframe> keyframes,
    @Default(0) int frame,
    required int frameCount,
  }) = _Success;
}
