import 'package:cattle_monitoring/components/cards/cow_card.dart';
import 'package:cattle_monitoring/components/map.dart';
import 'package:cattle_monitoring/data/models/cow_model.dart';
import 'package:cattle_monitoring/features/animals/animal_cubit.dart';
import 'package:cattle_monitoring/features/animals/animal_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnimalPage extends StatelessWidget {
  const AnimalPage({super.key});

  void _showAddCowDialog(BuildContext context) {
    final nameController = TextEditingController();
    final tempController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Cow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: tempController,
              decoration: const InputDecoration(labelText: 'Temperature'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final temp = double.tryParse(tempController.text.trim()) ?? 0.0;
              final location = locationController.text.trim();

              if (name.isNotEmpty && location.isNotEmpty) {
                final cow = CowModel(name: name, temperature: temp, location: location);
                context.read<AnimalCubit>().addAnimal(cow);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCowDialog(BuildContext context, CowModel cow) {
    final nameController = TextEditingController(text: cow.name);
    final tempController = TextEditingController(text: cow.temperature.toString());
    final locationController = TextEditingController(text: cow.location);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Cow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: tempController,
              decoration: const InputDecoration(labelText: 'Temperature'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updated = CowModel(
                id: cow.id,
                name: nameController.text.trim(),
                temperature: double.tryParse(tempController.text.trim()) ?? cow.temperature,
                location: locationController.text.trim(),
              );
              context.read<AnimalCubit>().updateAnimal(cow, updated);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, CowModel cow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('${cow.name} Details')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Temperature: ${cow.temperature}°C\nLocation: ${cow.location}'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnimalCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cattle Monitoring')),
      body: BlocBuilder<AnimalCubit, AnimalState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Initializing...')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (animals) {
              // Parse cow locations into LatLng list
              final positions = animals
                  .map((cow) {
                    final parts = cow.location.split(',');
                    if (parts.length >= 2) {
                      final lat = double.tryParse(parts[0].trim());
                      final lon = double.tryParse(parts[1].trim());
                      if (lat != null && lon != null) {
                        return LatLng(lat, lon);
                      }
                    }
                    return null;
                  })
                  .whereType<LatLng>()
                  .toList();

              // Calculate centroid or fallback
              LatLng mapCenter;
              if (positions.isNotEmpty) {
                final avgLat = positions.map((p) => p.latitude).reduce((a, b) => a + b) / positions.length;
                final avgLng = positions.map((p) => p.longitude).reduce((a, b) => a + b) / positions.length;
                mapCenter = LatLng(avgLat, avgLng);
              } else {
                // Default fallback (Terceira Azores approx center)
                mapCenter = LatLng(38.715, -27.232);
              }

              // Create markers for cows
              final markers = animals.map((cow) {
                return Marker(
                  point: LatLng(
                    cow.latitude ?? 38.715, // Fallback to default if null
                    cow.longitude ?? -27.232, // Fallback to default if null
                  ),
                  width: 5,
                  height: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                  ),
                );
              }).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await cubit.loadAnimals();
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: 200, // fixed map height
                      child: MapWidget(
                        center: mapCenter,
                        zoom: 13.0,
                        markers: markers,
                      ),
                    ),
                    Expanded(
                      child: animals.isEmpty
                          ? const ListTile(title: Text("No cows found."))
                          : ListView.builder(
                              itemCount: animals.length,
                              itemBuilder: (context, index) {
                                final cow = animals[index];
                                return CowCard(
                                  cow: cow,
                                  onEdit: () => _showEditCowDialog(context, cow),
                                  onDelete: () => cubit.deleteAnimal(cow.id!),
                                  onDetail: () => _navigateToDetail(context, cow),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
            error: (message) => Center(child: Text('Error: $message')),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton(
          onPressed: () => _showAddCowDialog(context),
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
