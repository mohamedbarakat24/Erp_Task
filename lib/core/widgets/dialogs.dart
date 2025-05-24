import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/document/logic/document_bloc.dart';
import '../../presentation/document/logic/document_event.dart';
import '../../presentation/document/models/document.dart';
import '../constants/app_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

// Function to show document details dialog
Future<void> showDocumentDetailsDialog(
  BuildContext context,
  Document doc,
) async {
  await showDialog(
    context: context,
    builder: (dialogContext) {
      final tagController = TextEditingController();
      List<String> tags = List<String>.from(doc.tags);
      String? tagError;
      final Map<String, dynamic> tempPermissions = Map.from(doc.permissions);

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(doc.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${doc.type}'),
                  Text('Size: ${(doc.size / 1024).toStringAsFixed(2)} KB'),
                  if (doc.metadata['fileName'] != null)
                    Text('File: ${doc.metadata['fileName']}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Tags:',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          decoration: const InputDecoration(
                            hintText: 'Add tag',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final newTag = tagController.text.trim();
                          if (newTag.isEmpty) {
                            setState(() {
                              tagError = 'Enter a tag';
                            });
                            return;
                          }
                          if (tags.contains(newTag)) {
                            setState(() {
                              tagError = 'Tag already exists';
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
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        tagError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('View'),
                    value: tempPermissions['owner']?['view'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (tempPermissions['owner'] == null) {
                          tempPermissions['owner'] = {};
                        }
                        tempPermissions['owner']?['view'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Edit'),
                    value: tempPermissions['owner']?['edit'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (tempPermissions['owner'] == null) {
                          tempPermissions['owner'] = {};
                        }
                        tempPermissions['owner']?['edit'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Download'),
                    value: tempPermissions['owner']?['download'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (tempPermissions['owner'] == null) {
                          tempPermissions['owner'] = {};
                        }
                        tempPermissions['owner']?['download'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View File'),
                    onPressed: () async {
                      final filePath = doc.metadata['filePath'];
                      if (filePath == null || filePath.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File path not available.'),
                          ),
                        );
                        return;
                      }

                      final hasViewPermission =
                          doc.permissions['owner']?['view'] ?? false;
                      if (!hasViewPermission) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                            builder: (_) => PDFViewerScreen(filePath: filePath),
                          ),
                        );
                      } else {
                        try {
                          final compatibleFilePath = filePath.replaceAll(
                            '\\',
                            '/',
                          );
                          await OpenFilex.open(compatibleFilePath);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedDoc = Document(
                    id: doc.id,
                    name: doc.name,
                    type: doc.type,
                    size: doc.size,
                    tags: tags,
                    metadata: doc.metadata,
                    folderId: doc.folderId,
                    permissions: tempPermissions,
                  );
                  context.read<DocumentBloc>().add(UpdateDocument(updatedDoc));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );
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

// Function to show file upload dialog
Future<void> showFileUploadDialog(BuildContext context, String folderId) async {
  final fileNameController = TextEditingController();
  List<String> tags = [];
  String? tagError;
  Map<String, dynamic> permissions = {
    'owner': {'view': true, 'edit': true, 'delete': true, 'download': true},
  };
  XFile? pickedFile;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload New File'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: fileNameController,
                    decoration: const InputDecoration(hintText: 'File Name'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      pickedFile == null ? 'Pick File' : pickedFile!.name,
                    ),
                    onPressed: () async {
                      // Implement file picking and validation
                      final result = await openFile(); // Using file_selector
                      if (result != null) {
                        // Basic validation: max size 50MB (adjust as needed)
                        final fileSize = await result.length();
                        if (fileSize > 50 * 1024 * 1024) {
                          // 50MB in bytes
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File size exceeds 50MB.'),
                            ),
                          );
                          setState(
                            () => pickedFile = null,
                          ); // Clear selected file if too large
                        } else {
                          // Optional: add file type validation here
                          setState(() => pickedFile = result);
                        }
                      } else {
                        setState(() => pickedFile = null);
                      }
                    },
                  ),
                  if (pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Selected: ${pickedFile!.name}'),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tags:',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          decoration: const InputDecoration(
                            hintText: 'Add tag',
                          ),
                          onSubmitted: (newTag) {
                            if (newTag.trim().isNotEmpty &&
                                !tags.contains(newTag.trim())) {
                              setState(() {
                                tags.add(newTag.trim());
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Simplified permissions for the dialog example
                  CheckboxListTile(
                    title: const Text('View'),
                    value: permissions['owner']?['view'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (permissions['owner'] == null)
                          permissions['owner'] = {};
                        permissions['owner']['view'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Edit'),
                    value: permissions['owner']?['edit'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (permissions['owner'] == null)
                          permissions['owner'] = {};
                        permissions['owner']['edit'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Download'),
                    value: permissions['owner']?['download'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (permissions['owner'] == null)
                          permissions['owner'] = {};
                        permissions['owner']['download'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    pickedFile == null
                        ? null
                        : () async {
                          // Handle file upload logic
                          if (fileNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File name cannot be empty.'),
                              ),
                            );
                            return;
                          }

                          final newDocument = Document(
                            id: const Uuid().v4(),
                            name: fileNameController.text.trim(),
                            type:
                                pickedFile!.mimeType ??
                                'unknown', // Get file type
                            size: await pickedFile!.length(), // Get file size
                            folderId: folderId, // Use the current folder's ID
                            tags: tags, // Added tags
                            metadata: {
                              'filePath':
                                  pickedFile!.path != null
                                      ? pickedFile!.path!
                                      : '', // Store file path (consider security/storage)
                              'originalName':
                                  pickedFile!.name, // Store original file name
                            },
                            permissions: permissions, // Added permissions
                          );

                          context.read<DocumentBloc>().add(
                            AddDocument(newDocument),
                          );
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'File ${newDocument.name} uploaded.',
                              ),
                            ),
                          );
                        },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      );
    },
  );
}
