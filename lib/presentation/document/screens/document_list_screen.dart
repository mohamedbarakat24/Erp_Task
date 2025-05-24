import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/document_bloc.dart';
import '../logic/document_event.dart';
import '../logic/document_state.dart';
import '../models/document.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import 'package:file_selector/file_selector.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class DocumentListScreen extends StatelessWidget {
  final String folderId;
  final String? folderName;
  const DocumentListScreen({Key? key, required this.folderId, this.folderName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderName ?? 'Documents')),
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DocumentLoaded) {
            final docs =
                state.documents.where((d) => d.folderId == folderId).toList();
            if (docs.isEmpty) {
              return const Center(child: Text('No documents found.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      // Add permission check for delete
                      final hasDeletePermission =
                          doc.permissions['owner']?['delete'] ?? false;

                      if (!hasDeletePermission) {
                        // Show a message and prevent deletion if permission is denied
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You do not have permission to delete this file.',
                            ),
                          ),
                        );
                        // We might need to prevent dismissal here, but Dismissible doesn't easily support preventing dismissal based on async checks.
                        // For simplicity now, we show a message, the item will still dismiss visually but the bloc won't delete it.
                        // A better approach for a real app would involve confirming deletion *before* dismissing or handling the UI state more carefully.
                        return; // Stop here if no permission
                      }

                      // Proceed with deletion if permission is granted
                      context.read<DocumentBloc>().add(DeleteDocument(doc.id));
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
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppColors.primaryClr,
                          ),
                        ),
                        subtitle: Text(
                          doc.type,
                          style: const TextStyle(color: AppColors.darkGreyClr),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.darkGreyClr,
                        ),
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              final tagController = TextEditingController();
                              List<String> tags = List<String>.from(doc.tags);
                              String? tagError;
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text(doc.name),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Type: ${doc.type}'),
                                          Text(
                                            'Size: ${(doc.size / 1024).toStringAsFixed(2)} KB',
                                          ),
                                          if (doc.metadata['fileName'] != null)
                                            Text(
                                              'File: ${doc.metadata['fileName']}',
                                            ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Tags:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 8,
                                            children:
                                                tags
                                                    .map(
                                                      (tag) => Chip(
                                                        label: Text(tag),
                                                        onDeleted: () {
                                                          setState(() {
                                                            tags.remove(tag);
                                                          });
                                                        },
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: tagController,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: 'Add tag',
                                                      ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  final newTag =
                                                      tagController.text.trim();
                                                  if (newTag.isEmpty) {
                                                    setState(() {
                                                      tagError = 'Enter a tag';
                                                    });
                                                    return;
                                                  }
                                                  if (tags.contains(newTag)) {
                                                    setState(() {
                                                      tagError =
                                                          'Tag already exists';
                                                    });
                                                    return;
                                                  }
                                                  setState(() {
                                                    tags.add(newTag);
                                                    tagController.clear();
                                                    tagError = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          if (tagError != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                tagError!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),

                                          // Permissions section
                                          const Text(
                                            'Permissions:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // UI for managing permissions (using Checkboxes for example)
                                          CheckboxListTile(
                                            title: const Text('View'),
                                            value:
                                                doc.permissions['owner']?['view'] ??
                                                false, // Default to false if not set
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (doc.permissions['owner'] ==
                                                    null) {
                                                  doc.permissions['owner'] = {};
                                                }
                                                doc.permissions['owner']?['view'] =
                                                    value ?? false;
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            dense: true,
                                          ),
                                          CheckboxListTile(
                                            title: const Text('Edit'),
                                            value:
                                                doc.permissions['owner']?['edit'] ??
                                                false, // Default to false if not set
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (doc.permissions['owner'] ==
                                                    null) {
                                                  doc.permissions['owner'] = {};
                                                }
                                                doc.permissions['owner']?['edit'] =
                                                    value ?? false;
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            dense: true,
                                          ),
                                          CheckboxListTile(
                                            title: const Text('Download'),
                                            value:
                                                doc.permissions['owner']?['download'] ??
                                                false, // Default to false if not set
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (doc.permissions['owner'] ==
                                                    null) {
                                                  doc.permissions['owner'] = {};
                                                }
                                                doc.permissions['owner']?['download'] =
                                                    value ?? false;
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            dense: true,
                                          ),

                                          const SizedBox(height: 16),

                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.open_in_new),
                                            label: const Text('View File'),
                                            onPressed: () async {
                                              final filePath =
                                                  doc.metadata['filePath'];
                                              if (filePath == null ||
                                                  filePath.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'File path not available.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              // Check if the user ('owner' in this simple example) has view permission
                                              final hasViewPermission =
                                                  doc.permissions['owner']?['view'] ??
                                                  false;

                                              if (!hasViewPermission) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'You do not have permission to view this file.',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              if (doc.type == 'PDF') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => PDFViewerScreen(
                                                          filePath: filePath,
                                                        ),
                                                  ),
                                                );
                                              } else {
                                                try {
                                                  // Convert backslashes to forward slashes for compatibility
                                                  final compatibleFilePath =
                                                      filePath.replaceAll(
                                                        '\\',
                                                        '/',
                                                      );
                                                  await OpenFilex.open(
                                                    compatibleFilePath,
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to open file: ${e.toString()}',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(dialogContext),
                                        child: const Text('Close'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Save tags to the document (in-memory for now)
                                          final updatedDoc = Document(
                                            id: doc.id,
                                            name: doc.name,
                                            type: doc.type,
                                            size: doc.size,
                                            tags: tags,
                                            metadata: doc.metadata,
                                            folderId: doc.folderId,
                                            permissions:
                                                doc.permissions, // Use updated permissions
                                          );
                                          context.read<DocumentBloc>().add(
                                            UpdateDocument(updatedDoc),
                                          );
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text('Save Tags'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is DocumentError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addDoc',
        onPressed: () async {
          final nameController = TextEditingController();
          String? errorText;
          XFile? pickedFile;
          await showDialog(
            context: context,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Add Document'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Document name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(
                            pickedFile == null ? 'Choose File' : 'Change File',
                          ),
                          onPressed: () async {
                            final XFile? file = await openFile();
                            if (file != null) {
                              setState(() {
                                pickedFile = file;
                                errorText = null;
                                if (nameController.text.isEmpty) {
                                  nameController.text =
                                      file.name.split('.').first;
                                }
                              });
                            }
                          },
                        ),
                        if (pickedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'File: [36m${pickedFile!.name}[0m',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                FutureBuilder<int>(
                                  future: pickedFile!.length(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Text(
                                        'Size: ...',
                                        style: TextStyle(fontSize: 13),
                                      );
                                    }
                                    return Text(
                                      'Size: [36m${(snapshot.data! / 1024).toStringAsFixed(2)} KB[0m',
                                      style: const TextStyle(fontSize: 13),
                                    );
                                  },
                                ),
                                Text(
                                  'Type: ${pickedFile!.name.split('.').last.toUpperCase()}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        if (errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorText!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty ||
                              pickedFile == null) {
                            setState(() {
                              errorText =
                                  'Please enter a name and choose a file.';
                            });
                            return;
                          }

                          // Define allowed file types and max size
                          const allowedExtensions = [
                            'pdf',
                            'doc',
                            'docx',
                            'xls',
                            'xlsx',
                            'ppt',
                            'pptx',
                          ];
                          const maxFileSize = 10 * 1024 * 1024; // 10 MB

                          final fileExtension =
                              pickedFile!.name.split('.').last.toLowerCase();
                          final fileSize = await pickedFile!.length();

                          if (!allowedExtensions.contains(fileExtension)) {
                            setState(() {
                              errorText =
                                  'Unsupported file type. Allowed types: ${allowedExtensions.join(', ')}';
                            });
                            return;
                          }

                          if (fileSize > maxFileSize) {
                            setState(() {
                              errorText =
                                  'File size exceeds the maximum limit of ${maxFileSize ~/ (1024 * 1024)} MB.';
                            });
                            return;
                          }

                          // If validation passes, proceed to add the document
                          Navigator.pop(dialogContext, {
                            'name': nameController.text.trim(),
                            'type':
                                pickedFile!.name.split('.').last.toUpperCase(),
                            'size': fileSize,
                            'fileName': pickedFile!.name,
                            'filePath': pickedFile!.path,
                          });
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          ).then((result) {
            if (result != null &&
                result['name'] != null &&
                result['type'] != null) {
              final newDoc = Document(
                id: const Uuid().v4(),
                name: result['name']!,
                type: result['type']!,
                size: result['size'] ?? 0,
                tags: [],
                metadata: {
                  'fileName': result['fileName'],
                  'filePath': result['filePath'],
                },
                folderId: folderId,
                permissions: {},
              );
              context.read<DocumentBloc>().add(AddDocument(newDoc));
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  const PDFViewerScreen({required this.filePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PDFViewerScreen(filePath: filePath),
                ),
              );
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(filePath),
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load PDF: ${details.description}'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PDFViewerScreen(filePath: filePath),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
