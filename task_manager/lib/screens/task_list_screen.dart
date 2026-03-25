import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskListProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final rawSearch = ref.watch(searchQueryProvider);

    final isFiltering = rawSearch.isNotEmpty || statusFilter != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TaskFlow',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          taskAsync.when(
            data: (tasks) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${tasks.length} tasks',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      ref.read(taskListProvider.notifier).updateSearch(v);
                    });
                  },
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tasks…',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    suffixIcon: rawSearch.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _debounce?.cancel();
                              ref
                                  .read(taskListProvider.notifier)
                                  .updateSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: statusFilter == null,
                        color: AppTheme.textSecondary,
                        onTap: () => ref
                            .read(statusFilterProvider.notifier)
                            .state = null,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'To-Do',
                        isSelected: statusFilter == 'To-Do',
                        color: AppTheme.statusTodo,
                        onTap: () => ref
                            .read(statusFilterProvider.notifier)
                            .state = 'To-Do',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Progress',
                        isSelected: statusFilter == 'In Progress',
                        color: AppTheme.statusInProgress,
                        onTap: () => ref
                            .read(statusFilterProvider.notifier)
                            .state = 'In Progress',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Done',
                        isSelected: statusFilter == 'Done',
                        color: AppTheme.statusDone,
                        onTap: () => ref
                            .read(statusFilterProvider.notifier)
                            .state = 'Done',
                      ),
                    ],
                  ),
                ),
                if (isFiltering)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Clear filters to reorder tasks',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Task list
          Expanded(
            child: taskAsync.when(
              loading: () => _ShimmerList(),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(taskListProvider.notifier).refresh(),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _EmptyState(isFiltered: isFiltering);
                }

                if (isFiltering) {
                  return RefreshIndicator(
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.surface,
                    onRefresh: () =>
                        ref.read(taskListProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) {
                        final task = tasks[i];
                        return TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          index: i,
                          searchQuery: rawSearch,
                          onTap: () => _openForm(context, task: task),
                          onDelete: () => _deleteTask(task),
                        );
                      },
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: tasks.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    ref
                        .read(taskListProvider.notifier)
                        .reorderTasks(oldIndex, newIndex);
                  },
                  itemBuilder: (ctx, i) {
                    final task = tasks[i];
                    return TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      index: i,
                      searchQuery: rawSearch,
                      onTap: () => _openForm(context, task: task),
                      onDelete: () => _deleteTask(task),
                      dragHandle: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(
                          Icons.drag_handle_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Task',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        elevation: 4,
      ),
    );
  }

  void _openForm(BuildContext context, {Task? task}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => TaskFormScreen(taskToEdit: task),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _deleteTask(Task task) async {
    try {
      await ref.read(taskListProvider.notifier).deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${task.title}" deleted',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceVariant,
        highlightColor: AppTheme.border,
        child: Column(
          children: List.generate(
            5,
            (i) => Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered
                ? Icons.search_off_rounded
                : Icons.check_circle_outline_rounded,
            size: 56,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No matching tasks' : 'No tasks yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Try adjusting your search or filter'
                : 'Tap + New Task to get started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not connect to server',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
