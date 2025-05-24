class Document {
  final String id;
  final String name;
  final String type;
  final int size;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String folderId;
  final Map<String, dynamic> permissions;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.tags,
    required this.metadata,
    required this.folderId,
    required this.permissions,
  });
}
