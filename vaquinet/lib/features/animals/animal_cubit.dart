import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
        final payload = event.payload;
        final decoded = jsonDecode(payload);

        // 🔍 Safely check for 'data' key
        final data = decoded['data'];

        if (data is List) {
          // Multiple cows
          final cows = data.map((json) => CowModel.fromJson(json)).toList();
          updateOrAddCows(cows);
        } else {
          // Single cow
          final cow = CowModel.fromJson(decoded);
          updateOrAddCow(cow);
        }
        startCowJitter();
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

  void updateOrAddCows(List<CowModel> updatedCows) {
    final random = Random();

    double randomDelta() => (random.nextDouble() - 0.5) * 0.001;

    // Apply movement to each cow
    final movedCows = updatedCows.map((cow) {
      return CowModel(
        id: cow.id,
        name: cow.name,
        temperature: cow.temperature,
        location: cow.location,
        latitude: (cow.latitude ?? 0) + randomDelta(),
        longitude: (cow.longitude ?? 0) + randomDelta(),
      );
    }).toList();

    state.maybeWhen(
      loaded: (cows) {
        final updatedList = List<CowModel>.from(cows);

        for (final movedCow in movedCows) {
          final index = updatedList.indexWhere((c) => c.id == movedCow.id);
          if (index != -1) {
            updatedList[index] = movedCow;
          } else {
            updatedList.add(movedCow);
          }
        }

        emit(AnimalState.loaded(updatedList));
      },
      orElse: () {
        emit(AnimalState.loaded(movedCows));
      },
    );
  }

  void updateOrAddCow(CowModel updatedCow) {
    final random = Random();

    // Generate small random deltas, e.g., ±0.0005 degrees (~50m)
    double randomDelta() => (random.nextDouble() - 0.5) * 0.001;

    final movedCow = CowModel(
      id: updatedCow.id,
      name: updatedCow.name,
      temperature: updatedCow.temperature,
      location: updatedCow.location,
      latitude: (updatedCow.latitude ?? 0) + randomDelta(),
      longitude: (updatedCow.longitude ?? 0) + randomDelta(),
    );

    state.maybeWhen(
      loaded: (cows) {
        final updatedList = List<CowModel>.from(cows);
        final index = updatedList.indexWhere((c) => c.id == movedCow.id);
        if (index != -1) {
          updatedList[index] = movedCow;
        } else {
          updatedList.add(movedCow);
        }
        emit(AnimalState.loaded(updatedList));
      },
      orElse: () {
        emit(AnimalState.loaded([movedCow]));
      },
    );
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

  Timer? _jitterTimer;

  void startCowJitter() {
    _jitterTimer?.cancel();

    _jitterTimer = Timer.periodic(Duration(seconds: 5), (_) {
      state.maybeWhen(
        loaded: (cows) {
          final random = Random();

          final movedCows = cows.map((cow) {
            final shouldMove = random.nextDouble() > 0.5; // 50% chance to move

            if (!shouldMove) return cow; // Cow stands still

            // Tiny drift: 1–5 cm
            final distance = (random.nextDouble() * 0.04 + 0.01) / 10000;
            final angle = random.nextDouble() * 2 * pi;

            final deltaLat = cos(angle) * distance;
            final deltaLng = sin(angle) * distance / cos((cow.latitude ?? 38.65) * pi / 180);

            return cow.copyWith(
              latitude: (cow.latitude ?? 0) + deltaLat,
              longitude: (cow.longitude ?? 0) + deltaLng,
            );
          }).toList();

          emit(AnimalState.loaded(movedCows));
        },
        orElse: () {},
      );
    });
  }

  void stopCowJitter() {
    _jitterTimer?.cancel();
    _jitterTimer = null;
  }

  @override
  Future<void> close() {
    _mqttSubscription.cancel();
    return super.close();
  }
}
