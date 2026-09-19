import 'package:equatable/equatable.dart';

class WorkLocation extends Equatable {
  const WorkLocation({required this.id, required this.name, this.address});

  final String id;
  final String name;
  final String? address;

  @override
  List<Object?> get props => [id, name, address];
}
