import 'dart:convert';
import 'package:cattle_monitoring/core/app_config.dart';
import 'package:cattle_monitoring/data/models/cow_model.dart';
import 'package:http/http.dart' as http;

class AnimalRepository {
  final String _baseUrl = AppConfig.animalApiUrl;

  Future<List<CowModel>> fetchAll() async {
    final request = http.Request('GET', Uri.parse('$_baseUrl/cows'));
    final response = await request.send();

    try {
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final decoded = json.decode(body);

        // 💡 The actual data is in the "data" field
        final List<dynamic> cowList = decoded;

        return cowList.map((e) => CowModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load cows: ${response.statusCode}');
      }
    } catch (e) {
      print('Error parsing cows: $e');
      rethrow;
    }
  }

  Future<CowModel> fetchById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/cows/$id'));

    if (response.statusCode == 200) {
      return CowModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Cow not found (ID $id)');
    }
  }

  Future<void> create(CowModel cow) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/cows'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(cow.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add cow: ${response.statusCode}');
    }
  }

  Future<void> update(CowModel original, CowModel updated) async {
    if (original.id == null) throw Exception('Cow ID is required for update');

    final response = await http.put(
      Uri.parse('$_baseUrl/cows/${original.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updated.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update cow: ${response.statusCode}');
    }
  }

  Future<void> delete(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/cows/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete cow: ${response.statusCode}');
    }
  }
}
