class ChatDocumentPreview {
  const ChatDocumentPreview({
    this.text,
    this.sheets = const [],
    this.truncated = false,
  });
  final String? text;
  final List<ChatDocumentSheet> sheets;
  final bool truncated;
}

class ChatDocumentSheet {
  const ChatDocumentSheet(this.name, this.rows);
  final String name;
  final List<List<String>> rows;
}
