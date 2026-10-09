String leaveRequestCardInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final value = parts.map((part) => part[0]).join().toUpperCase();
  return value.isEmpty ? '?' : value;
}
