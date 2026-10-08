import 'package:equatable/equatable.dart';

class OperationalDate extends Equatable implements Comparable<OperationalDate> {
  const OperationalDate._(this.value, this.year, this.month, this.day);

  factory OperationalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid operationalDate');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw const FormatException('Invalid operationalDate');
    }
    return OperationalDate._(value, year, month, day);
  }

  final String value;
  final int year;
  final int month;
  final int day;
  DateTime get calendarDate => DateTime(year, month, day);

  @override
  int compareTo(OperationalDate other) => value.compareTo(other.value);
  @override
  List<Object> get props => [value];
  @override
  String toString() => value;
}
