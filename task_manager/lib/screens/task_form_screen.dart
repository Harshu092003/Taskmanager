import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/draft_service.dart';
import '../utils/app_theme.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const TaskFormScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _draftService = DraftService();

  TaskStatus _status = TaskStatus.todo;
  DateTime? _dueDate;
  String? _blockedById;
  String? _blockedByTitle;

  bool _isLoading = false;
  bool _draftLoaded = false;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFromTask(widget.taskToEdit!);
    } else {
      _loadDraft();
    }

    // Auto-save draft on every text change (only for new tasks)
    if (!isEditing) {
      _titleController.addListener(_saveDraft);
      _descController.addListener(_saveDraft);
    }
  }

  void _populateFromTask(Task task) {
    _titleController.text = task.title;
    _descController.text = task.description;
    _status = task.status;
    _blockedById = task.blockedById;
    _blockedByTitle = task.blockedByTitle;
    try {
      final parts = task.dueDate.split('-');
      _dueDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {}
  }

  Future<void> _loadDraft() async {
    final draft = await _draftService.loadDraft();
    if (draft['title'] != null && draft['title']!.isNotEmpty) {
      setState(() {
        _titleController.text = draft['title']!;
        _descController.text = draft['description'] ?? '';
        if (draft['due_date'] != null) {
          try {
            final parts = draft['due_date']!.split('-');
            _dueDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } catch (_) {}
        }
        if (draft['status'] != null) {
          _status = TaskStatus.fromValue(draft['status']!);
        }
        _blockedById = draft['blocked_by_id'];
        _draftLoaded = true;
      });
    }
  }

  void _saveDraft() {
    if (isEditing) return;
    _draftService.saveDraft(
      title: _titleController.text,
      description: _descController.text,
      dueDate: _dueDate != null ? _dueDateIso : null,
      status: _status.value,
      blockedById: _blockedById,
    );
  }

  String get _dueDateIso {
    if (_dueDate == null) return '';
    return '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      _showError('Please select a due date.');
      return;
    }
    if (_isLoading) return; // Prevent double-tap

    setState(() => _isLoading = true);

    final task = Task(
      id: isEditing ? widget.taskToEdit!.id : '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDateIso,
      status: _status,
      blockedById: _blockedById,
    );

    try {
      if (isEditing) {
        await ref
            .read(taskListProvider.notifier)
            .updateTask(widget.taskToEdit!.id, task);
      } else {
        await ref.read(taskListProvider.notifier).createTask(task);
        await _draftService.clearDraft();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError('Failed to save task: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      _saveDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Task' : 'New Task',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_draftLoaded)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 12,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Draft restored',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            _SectionLabel(label: 'Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(hintText: 'Task title…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Description
            _SectionLabel(label: 'Description'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(hintText: 'Add details…'),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),

            // Due date
            _SectionLabel(label: 'Due Date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Select date…'
                          : _formatDate(_dueDate!),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _dueDate == null
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status
            _SectionLabel(label: 'Status'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaskStatus>(
                  value: _status,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceVariant,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  items: TaskStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor(s.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(s.value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _status = v);
                      _saveDraft();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Blocked by
            _SectionLabel(label: 'Blocked By (Optional)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _blockedById,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceVariant,
                  hint: Text(
                    'No blocker',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'None',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    ...tasks
                        .where((t) => t.id != widget.taskToEdit?.id)
                        .map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(
                              t.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _blockedById = v;
                      _blockedByTitle = tasks
                          .where((t) => t.id == v)
                          .firstOrNull
                          ?.title;
                    });
                    _saveDraft();
                  },
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading
                      ? AppTheme.surfaceVariant
                      : AppTheme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'Saving…' : 'Creating…',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'In Progress':
      return AppTheme.statusInProgress;
    case 'Done':
      return AppTheme.statusDone;
    default:
      return AppTheme.statusTodo;
  }
}
