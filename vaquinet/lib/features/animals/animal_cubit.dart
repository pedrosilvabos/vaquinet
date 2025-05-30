import 'dart:async';

import 'package:cattle_monitoring/repositories/animal_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cattle_monitoring/data/models/cow_model.dart';
import 'package:cattle_monitoring/managers/mqtt_manager.dart';
import 'animal_state.dart';

class AnimalCubit extends Cubit<AnimalState> {
  final MQTTManager mqttManager;
  final AnimalRepository animalRepository;
  late final StreamSubscription _mqttSubscription;

  AnimalCubit(
    this.mqttManager,
    this.animalRepository,
  ) : super(const AnimalState.initial()) {
    _subscribeToMqtt();
  }

  void _subscribeToMqtt() {
    _mqttSubscription = mqttManager.messageStream.listen((event) {
      if (event.topic.startsWith('cows/details')) {
        print('Received MQTT event: ${event.payload} on topic ${event.topic}');
        loadAnimals();
      }
    });
  }

  Future<void> loadAnimals() async {
    emit(const AnimalState.loading());

    try {
      final cows = await animalRepository.fetchAll();
      emit(AnimalState.loaded(cows));
    } catch (e) {
      emit(AnimalState.error('Failed to load cows: $e'));
    }
  }

  Future<void> getAnimalById(int id) async {
    emit(const AnimalState.loading());

    try {
      final cow = await animalRepository.fetchById(id);
      emit(AnimalState.loaded([cow]));
    } catch (e) {
      emit(AnimalState.error('Failed to fetch cow: $e'));
    }
  }

  Future<void> addAnimal(CowModel cow) async {
    emit(const AnimalState.loading());

    try {
      await animalRepository.create(cow);
      await loadAnimals();
    } catch (e) {
      emit(AnimalState.error('Failed to add cow: $e'));
    }
  }

  Future<void> updateAnimal(CowModel original, CowModel updated) async {
    if (original.id == null) {
      emit(const AnimalState.error('Cow ID is required for update'));
      return;
    }

    emit(const AnimalState.loading());

    try {
      await animalRepository.update(original, updated);
      await loadAnimals();
    } catch (e) {
      emit(AnimalState.error('Failed to update cow: $e'));
    }
  }

  Future<void> deleteAnimal(String id) async {
    emit(const AnimalState.loading());

    try {
      await animalRepository.delete(id);
      await loadAnimals();
    } catch (e) {
      emit(AnimalState.error('Failed to delete cow: $e'));
    }
  }

  @override
  Future<void> close() {
    _mqttSubscription.cancel();
    return super.close();
  }
}
