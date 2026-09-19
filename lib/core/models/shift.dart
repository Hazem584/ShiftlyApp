import 'package:equatable/equatable.dart';

class Shift extends Equatable {
  const Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;

  String get timeRange => '${_format(startTime)} – ${_format(endTime)}';

  static String _format(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  List<Object?> get props => [id, name, startTime, endTime];
}
