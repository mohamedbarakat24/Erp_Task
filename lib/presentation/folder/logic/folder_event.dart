import '../models/folder.dart';

abstract class FolderEvent {}

class LoadFolders extends FolderEvent {}

class AddFolder extends FolderEvent {
  final Folder folder;
  AddFolder(this.folder);
}

class UpdateFolder extends FolderEvent {
  final Folder folder;
  UpdateFolder(this.folder);
}

class DeleteFolder extends FolderEvent {
  final String folderId;
  DeleteFolder(this.folderId);
}
