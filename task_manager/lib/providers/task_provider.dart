import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final searchQueryProvider = StateProvider<String>((ref) => '');

final statusFilterProvider = StateProvider<String?>((ref) => null);

final debouncedSearchProvider = StateProvider<String>((ref) => '');

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  Timer? _debounceTimer;

  @override
  Future<List<Task>> build() async {
    final search = ref.watch(debouncedSearchProvider);
    final status = ref.watch(statusFilterProvider);
    return _fetchTasks(search: search, status: status);
  }

  Future<List<Task>> _fetchTasks({String? search, String? status}) async {
    final api = ref.read(apiServiceProvider);
    return api.getTasks(search: search, status: status);
  }

  void updateSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(debouncedSearchProvider.notifier).state = query;
    });
  }

  Future<Task> createTask(Task task) async {
    final api = ref.read(apiServiceProvider);
    final created = await api.createTask(task);
    ref.invalidateSelf();
    return created;
  }

  Future<Task> updateTask(String id, Task task) async {
    final api = ref.read(apiServiceProvider);
    final updated = await api.updateTask(id, task);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteTask(String id) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteTask(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  // ← new
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null) return;

    final updated = List<Task>.from(current);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    // Re-stamp sequential sortOrder values
    final reindexed = [
      for (int i = 0; i < updated.length; i++)
        updated[i].copyWith(sortOrder: i),
    ];

    // Optimistic update — UI reflects the change instantly
    state = AsyncData(reindexed);

    // Persist to backend; roll back on failure
    try {
      await ref.read(apiServiceProvider).patchTaskOrder(
            reindexed
                .map((t) => {'id': t.id, 'sort_order': t.sortOrder})
                .toList(),
          );
    } catch (e) {
      state = AsyncData(current); // roll back
      rethrow;
    }
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);
