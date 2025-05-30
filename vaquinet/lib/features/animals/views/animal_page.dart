import 'package:cattle_monitoring/components/cards/cow_card.dart';
import 'package:cattle_monitoring/data/models/cow_model.dart';
import 'package:cattle_monitoring/features/animals/animal_cubit.dart';
import 'package:cattle_monitoring/features/animals/animal_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            loaded: (animals) => RefreshIndicator(
              onRefresh: () async {
                cubit.loadAnimals();
              },
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
