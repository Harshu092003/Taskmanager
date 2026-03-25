import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<List<Task>> getTasks({String? search, String? status}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final response = await _dio.get('/tasks/', queryParameters: queryParams);
    final tasks = (response.data as List).map((e) => Task.fromJson(e)).toList();
    // Sort by sortOrder so custom order is respected after every fetch
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  Future<Task> createTask(Task task) async {
    final response = await _dio.post('/tasks/', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<Task> updateTask(String id, Task task) async {
    final response = await _dio.put('/tasks/$id', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<Task> getTask(String id) async {
    final response = await _dio.get('/tasks/$id');
    return Task.fromJson(response.data);
  }

  // ← new: persist reordered positions in one call
  Future<void> patchTaskOrder(List<Map<String, dynamic>> items) async {
    try {
      await _dio.patch('/tasks/reorder', data: {'tasks': items});
    } on DioException catch (e) {
      // Fallback: if the backend has no bulk endpoint, patch individually
      if (e.response?.statusCode == 404) {
        await Future.wait(
          items.map(
            (item) => _dio.patch(
              '/tasks/${item['id']}',
              data: {'sort_order': item['sort_order']},
            ),
          ),
        );
      } else {
        rethrow;
      }
    }
  }
}
