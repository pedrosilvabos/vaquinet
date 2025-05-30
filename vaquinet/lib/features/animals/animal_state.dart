import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/cow_model.dart';

part 'animal_state.freezed.dart';

@freezed
class AnimalState with _$AnimalState {
  const factory AnimalState.initial() = _Initial;
  const factory AnimalState.loading() = _Loading;
  const factory AnimalState.loaded(List<CowModel> animals) = _Loaded;
  const factory AnimalState.error(String message) = _Error;
}
