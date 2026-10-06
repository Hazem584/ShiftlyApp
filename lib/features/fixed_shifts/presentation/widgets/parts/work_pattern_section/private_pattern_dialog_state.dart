part of '../../work_pattern_section.dart';

class _PatternDialogState extends State<_PatternDialog> {
  final _days = <int>{};
  late DateTime _date;
  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _date = widget.today;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New work pattern'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Working weekdays',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var day = 0; day < 7; day++)
                FilterChip(
                  key: Key('weekday-$day'),
                  label: Text(_labels[day]),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(
                    () => selected ? _days.add(day) : _days.remove(day),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text('Effective ${_dateKey(_date)}'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Today or a future workspace-local date. This creates a new version.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _days.isEmpty
            ? null
            : () => Navigator.pop(context, (
                days: Set<int>.from(_days),
                date: _date,
              )),
        child: const Text('Continue'),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: widget.today,
      lastDate: DateTime(widget.today.year + 5, 12, 31),
      initialDate: _date,
    );
    if (value != null && !value.isBefore(widget.today)) {
      setState(() => _date = value);
    }
  }
}
