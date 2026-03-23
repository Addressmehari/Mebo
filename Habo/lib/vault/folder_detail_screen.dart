import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habo/vault/vault_manager.dart';
import 'package:habo/vault/models/vault_folder.dart';
import 'package:habo/vault/models/vault_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class FolderDetailScreen extends StatefulWidget {
  final int folderId;

  static MaterialPage page(int folderId) {
    return MaterialPage(
      name: '/folder',
      key: ValueKey('/folder/$folderId'),
      child: FolderDetailScreen(folderId: folderId),
    );
  }

  const FolderDetailScreen({super.key, required this.folderId});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<VaultManager>(context, listen: false)
        .loadFilesForFolder(widget.folderId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultManager>(
      builder: (context, vaultManager, child) {
        final folder = vaultManager.folders.firstWhere((f) => f.id == widget.folderId);
        final files = vaultManager.folderFiles[widget.folderId] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              folder.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
          ),
          body: files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.file_upload, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No files yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _pickFile(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add File'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return FileListTile(file: file);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _pickFile(context),
            child: const Icon(Icons.add_to_photos),
          ),
        );
      },
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      await Provider.of<VaultManager>(context, listen: false)
          .addFileToFolder(widget.folderId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

class FileListTile extends StatelessWidget {
  final VaultFile file;

  const FileListTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(file.fileType),
      title: Text(file.name),
      subtitle: Text(
        '${_formatSize(file.sizeInBytes)} • ${DateFormat.yMMMd().format(file.createdAt)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _confirmDelete(context),
      ),
      onTap: () => _openFile(context),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'image':
        icon = Icons.image;
        color = Colors.blue;
        break;
      case 'video':
        icon = Icons.movie;
        color = Colors.red;
        break;
      case 'doc':
        icon = Icons.description;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Icon(icon, color: color, size: 32);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      Provider.of<VaultManager>(context, listen: false).deleteFile(file);
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(appDocDir.path, file.localPath);
      final fileObj = File(fullPath);
      
      if (await fileObj.exists()) {
        final result = await OpenFilex.open(fullPath);
        if (result.type != ResultType.done) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${result.message}')),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found.')),
        );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }
}
