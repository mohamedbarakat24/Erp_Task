import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/folder.dart';
import 'folder_event.dart';
import 'folder_state.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final List<Folder> _folders = [];

  FolderBloc() : super(FolderInitial()) {
    on<LoadFolders>((event, emit) {
      emit(FolderLoading());
      emit(FolderLoaded(List.from(_folders)));
    });

    on<AddFolder>((event, emit) {
      _folders.add(event.folder);

      if (event.folder.parentId != null) {
        final parentIndex = _folders.indexWhere(
          (f) => f.id == event.folder.parentId,
        );
        if (parentIndex != -1) {
          final parentFolder = _folders[parentIndex];
          final updatedChildFolderIds = List<String>.from(
            parentFolder.childFolderIds,
          )..add(event.folder.id);

          final updatedParentFolder = Folder(
            id: parentFolder.id,
            name: parentFolder.name,
            parentId: parentFolder.parentId,
            childFolderIds: updatedChildFolderIds,
          );

          _folders[parentIndex] = updatedParentFolder;
        }
      }

      emit(FolderLoaded(List.from(_folders)));
    });

    on<UpdateFolder>((event, emit) {
      int index = _folders.indexWhere((f) => f.id == event.folder.id);
      if (index != -1) {
        _folders[index] = event.folder;
        emit(FolderLoaded(List.from(_folders)));
      } else {
        emit(FolderError('Folder not found'));
      }
    });

    on<DeleteFolder>((event, emit) {
      final deletedFolderIndex = _folders.indexWhere(
        (f) => f.id == event.folderId,
      );
      if (deletedFolderIndex != -1) {
        final deletedFolder = _folders[deletedFolderIndex];
        final parentId = deletedFolder.parentId;

        _folders.removeAt(deletedFolderIndex);

        if (parentId != null) {
          final parentIndex = _folders.indexWhere((f) => f.id == parentId);
          if (parentIndex != -1) {
            final parentFolder = _folders[parentIndex];
            final updatedChildFolderIds = List<String>.from(
              parentFolder.childFolderIds,
            )..remove(event.folderId);

            final updatedParentFolder = Folder(
              id: parentFolder.id,
              name: parentFolder.name,
              parentId: parentFolder.parentId,
              childFolderIds: updatedChildFolderIds,
            );

            _folders[parentIndex] = updatedParentFolder;
          }
        }
      }

      emit(FolderLoaded(List.from(_folders)));
    });
  }
}
