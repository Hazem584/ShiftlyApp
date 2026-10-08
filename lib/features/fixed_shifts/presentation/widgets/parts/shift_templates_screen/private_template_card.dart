part of '../../shift_templates_screen.dart';

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
  });
  final ShiftTemplate template;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _color(template.color);
    return Opacity(
      opacity: template.active ? 1 : .68,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _badge(
                template.active
                    ? Icons.check_circle_outline
                    : Icons.archive_outlined,
                template.active ? 'Active' : 'Archived',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_time(template.startMinute)} – ${_time(template.endMinute)}  •  ${_duration(template.durationMinutes)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (template.overnight)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, size: 15),
                    SizedBox(width: 4),
                    Flexible(child: Text('Overnight / next-day end')),
                  ],
                ),
              ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _policy(
                  Icons.hourglass_top_rounded,
                  '${template.graceMinutes}m grace',
                ),
                _policy(
                  Icons.login_rounded,
                  '${template.allowedEarlyCheckInMinutes}m early',
                ),
                _policy(
                  Icons.more_time_rounded,
                  '${template.allowedLateCheckInMinutes}m late',
                ),
                _policy(
                  Icons.timer_outlined,
                  '${_duration(template.minimumWorkMinutes)} minimum',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (template.active) ...[
                  TextButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onArchive,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined),
                    label: const Text('Archive'),
                  ),
                ] else
                  const Text(
                    'Read-only history',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _policy(IconData icon, String text) => _badge(icon, text);

  Widget _badge(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.field,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Wrap(
      spacing: 5,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [Icon(icon, size: 15), Text(text)],
    ),
  );
}
