import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;
  final Widget? dragHandle;
  final String searchQuery; // ← new

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.index,
    this.searchQuery = '', // ← new, defaults to empty (no highlight)
    this.dragHandle,
  });

  /// Splits [title] around every case-insensitive occurrence of [query] and
  /// returns a [RichText] where each match is highlighted.
  Widget _buildHighlightedTitle(
    String title,
    String query,
    TextStyle baseStyle,
  ) {
    if (query.isEmpty) {
      return Text(title, style: baseStyle);
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final matchIndex = lowerTitle.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        // Append whatever is left after the last match
        if (start < title.length) {
          spans.add(TextSpan(text: title.substring(start), style: baseStyle));
        }
        break;
      }
      // Text before the match
      if (matchIndex > start) {
        spans.add(
          TextSpan(text: title.substring(start, matchIndex), style: baseStyle),
        );
      }
      // The matched portion — highlighted
      spans.add(
        TextSpan(
          text: title.substring(matchIndex, matchIndex + query.length),
          style: baseStyle.copyWith(
            color: AppTheme.accent,
            backgroundColor: AppTheme.accent.withOpacity(0.15),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = task.isBlocked && task.status != TaskStatus.done;
    final color = statusColor(task.status.value);

    // Base style for the title — same as before
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isBlocked ? AppTheme.textMuted : AppTheme.textPrimary,
      decoration: task.status == TaskStatus.done
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      decorationColor: AppTheme.textMuted,
    );

    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
          begin: const Offset(0, 0.06),
          end: Offset.zero,
          curve: Curves.easeOut,
        ),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isBlocked
                ? AppTheme.blockedColor.withOpacity(0.15)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBlocked
                  ? AppTheme.blockedColor.withOpacity(0.5)
                  : AppTheme.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Drag handle — only shown when provided
                    if (dragHandle != null) ...[
                      dragHandle!,
                      const SizedBox(width: 8),
                    ],
                    // Status indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isBlocked ? AppTheme.textMuted : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title with optional search highlight
                    Expanded(
                      child: _buildHighlightedTitle(
                        task.title,
                        searchQuery,
                        titleStyle,
                      ),
                    ),
                    _StatusChip(
                      status: task.status.value,
                      isBlocked: isBlocked,
                    ),
                    const SizedBox(width: 8),
                    _DeleteButton(onDelete: onDelete),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isBlocked
                          ? AppTheme.textMuted
                          : AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isBlocked
                          ? AppTheme.textMuted
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(task.dueDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isBlocked
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary,
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: AppTheme.danger.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Blocked by: ${task.blockedByTitle ?? '...'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.danger.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length < 3) return isoDate;
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
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
    } catch (_) {
      return isoDate;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isBlocked;

  const _StatusChip({required this.status, required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? AppTheme.textMuted : statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            title: Text(
              'Delete Task?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            content: Text(
              'This action cannot be undone.',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 15,
          color: AppTheme.danger.withOpacity(0.7),
        ),
      ),
    );
  }
}
