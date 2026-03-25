import 'package:shared_preferences/shared_preferences.dart';

class DraftService {
  static const _titleKey = 'draft_title';
  static const _descKey = 'draft_description';
  static const _dueDateKey = 'draft_due_date';
  static const _statusKey = 'draft_status';
  static const _blockedByIdKey = 'draft_blocked_by_id';

  Future<Map<String, String?>> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'title': prefs.getString(_titleKey),
      'description': prefs.getString(_descKey),
      'due_date': prefs.getString(_dueDateKey),
      'status': prefs.getString(_statusKey),
      'blocked_by_id': prefs.getString(_blockedByIdKey),
    };
  }

  Future<void> saveDraft({
    required String title,
    required String description,
    required String? dueDate,
    required String status,
    required String? blockedById,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, title);
    await prefs.setString(_descKey, description);
    if (dueDate != null) await prefs.setString(_dueDateKey, dueDate);
    await prefs.setString(_statusKey, status);
    if (blockedById != null) {
      await prefs.setString(_blockedByIdKey, blockedById);
    } else {
      await prefs.remove(_blockedByIdKey);
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_titleKey);
    await prefs.remove(_descKey);
    await prefs.remove(_dueDateKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_blockedByIdKey);
  }

  Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_titleKey);
    return title != null && title.isNotEmpty;
  }
}
