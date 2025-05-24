class Folder {
  final String id;
  final String name;
  final String? parentId;
  final List<String> childFolderIds;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.childFolderIds = const [],
  });
}
