import 'package:cattle_monitoring/repositories/animal_repository.dart';
import 'package:cattle_monitoring/features/animals/views/animal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/app_services.dart';
import 'features/animals/animal_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Monitoring',
      home: BlocProvider(
        create: (_) => AnimalCubit(
          AppServices.mqttManager,
          AnimalRepository(),
        )..loadAnimals(),
        child: const AnimalPage(),
      ),
    );
  }
}
