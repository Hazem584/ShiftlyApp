part of '../../notifications_screen.dart';

class _Destination {
  const _Destination({
    required this.id,
    required this.location,
    required this.kind,
  });
  final String id;
  final String location;
  final _DestinationKind kind;
}
