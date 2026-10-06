part of '../../chat_screen.dart';

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});
  final ChatLocation? location;

  @override
  Widget build(BuildContext context) {
    final value = location;
    if (value == null || !value.isValid) {
      return const Text('Location unavailable');
    }
    final fallback =
        '${value.latitude.toStringAsFixed(5)}, ${value.longitude.toStringAsFixed(5)}';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(value.label ?? 'Shared location')),
            ],
          ),
          const SizedBox(height: 6),
          Text(value.address ?? fallback),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _open(value),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open map'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(ChatLocation value) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${value.latitude},${value.longitude}',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(msg: 'No maps application is available.');
    }
  }
}
