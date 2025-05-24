import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/logic/folder/folder_bloc.dart';
import '../data/logic/folder/folder_event.dart';
import '../data/logic/folder/folder_state.dart';
import '../models/folder.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import 'document_list_screen.dart';
import '../data/logic/document/document_bloc.dart';
import '../data/logic/document/document_state.dart';
import '../models/document.dart';
import '../data/logic/document/document_event.dart';
import 'package:file_selector/file_selector.dart';
import '../utils/dialogs.dart';

class FolderListScreen extends StatelessWidget {
  final String? parentId;
  const FolderListScreen({Key? key, this.parentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, folderState) {
          if (folderState is FolderLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (folderState is FolderLoaded) {
            // Filter folders to show only children of the current parentId
            final currentFolders =
                folderState.folders
                    .where((folder) => folder.parentId == parentId)
                    .toList();

            return BlocBuilder<DocumentBloc, DocumentState>(
              builder: (context, documentState) {
                if (documentState is DocumentLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (documentState is DocumentLoaded) {
                  // Filter documents for the current parentId
                  final currentDocuments =
                      documentState.documents
                          .where((document) => document.folderId == parentId)
                          .toList();

                  // Combine and sort folders and documents (folders first)
                  final combinedItems = [
                    ...currentFolders,
                    ...currentDocuments,
                  ];
                  // You might want to add sorting by name or type here

                  if (combinedItems.isEmpty) {
                    return const Center(
                      child: Text('No items found in this location.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: combinedItems.length,
                    itemBuilder: (context, index) {
                      final item = combinedItems[index];

                      if (item is Folder) {
                        // Render Folder item
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              // Add permission check for delete folder
                              // For simplicity now, allowing folder deletion without permission check like before.
                              // In a real app, you'd check permissions for folders too.
                              context.read<FolderBloc>().add(
                                DeleteFolder(item.id),
                              );
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: AppColors.darkGreyClr.withOpacity(
                                0.1,
                              ),
                              color: Colors.grey.withOpacity(0.2),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryClr,
                                  child: const Icon(
                                    Icons.folder,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: AppColors.primaryClr,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.darkGreyClr,
                                ),
                                onTap: () {
                                  // Navigate to the subfolder
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => FolderListScreen(
                                            parentId: item.id,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      } else if (item is Document) {
                        // Render Document item
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orangeClr,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              // Permission check for deleting a document (already implemented)
                              final hasDeletePermission =
                                  item.permissions['owner']?['delete'] ?? false;

                              if (!hasDeletePermission) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You do not have permission to delete this file.',
                                    ),
                                  ),
                                );
                                return; // Prevent bloc event if no permission
                              }
                              context.read<DocumentBloc>().add(
                                DeleteDocument(item.id),
                              );
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: AppColors.cardBg,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryClr,
                                  child: const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: AppColors.primaryClr,
                                  ),
                                ),
                                subtitle: Text(
                                  item.type,
                                  style: const TextStyle(
                                    color: AppColors.darkGreyClr,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.darkGreyClr,
                                ),
                                onTap: () {
                                  // Show document details dialog
                                  showDocumentDetailsDialog(context, item);
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Fallback for unexpected item types
                    },
                  );
                } else if (documentState is DocumentError) {
                  return Center(child: Text(documentState.message));
                }
                return const SizedBox.shrink();
              },
            );
          } else if (folderState is FolderError) {
            return Center(child: Text(folderState.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (parentId == null) {
            // At root level, allow adding folders
            _showAddFolderDialog(context);
          } else {
            // Inside a folder, allow uploading files
            showFileUploadDialog(
              context,
              parentId!,
            ); // Call the new upload dialog
          }
        },
        tooltip: parentId == null ? 'Add New Folder' : 'Upload New File',
        child: Icon(parentId == null ? Icons.folder_open : Icons.upload_file),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(hintText: 'Enter folder name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                final folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  final newFolder = Folder(
                    id: const Uuid().v4(),
                    name: folderName,
                    parentId: null, // Always create in the root level
                    childFolderIds: [],
                  );
                  context.read<FolderBloc>().add(AddFolder(newFolder));
                  Navigator.pop(dialogContext);
                }
                // Optionally show an error if name is empty
              },
            ),
          ],
        );
      },
    );
  }

  // _handleFileUpload method is no longer needed here as it's in the dialog
}
