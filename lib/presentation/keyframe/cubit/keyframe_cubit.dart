import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lottie_editor/model/model.dart';

part 'keyframe_state.dart';
part 'keyframe_cubit.freezed.dart';

class KeyframeCubit extends Cubit<KeyframeState> {
  KeyframeCubit() : super(const KeyframeState.initial());

  void updateFrame(int frame) {
    //
  }

  void updateFrameCount(int frameCount) {
    //
  }

  void start() {
    //
  }

  void stop() {
    //
  }

  void reset() {
    //
  }
}
