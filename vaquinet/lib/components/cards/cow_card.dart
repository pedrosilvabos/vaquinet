import 'package:cattle_monitoring/data/models/cow_model.dart';
import 'package:flutter/material.dart';

class CowCard extends StatelessWidget {
  final CowModel cow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  const CowCard({
    super.key,
    required this.cow,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    String coordinates = '';
    if (cow.latitude != null && cow.longitude != null) {
      coordinates = 'Lat: ${cow.latitude!.toStringAsFixed(5)}, '
          'Lng: ${cow.longitude!.toStringAsFixed(5)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(cow.name),
        subtitle: Text(
          'Temp: ${cow.temperature} °C\n'
          'Location: ${cow.location}'
          '${coordinates.isNotEmpty ? '\n$coordinates' : ''}',
        ),
        onTap: onDetail,
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
