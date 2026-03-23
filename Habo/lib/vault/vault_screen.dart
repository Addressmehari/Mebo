import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:habo/vault/vault_manager.dart';
import 'package:habo/vault/models/vault_folder.dart';
import 'package:habo/constants.dart';

class VaultScreen extends StatelessWidget {
  static MaterialPage page() {
    return const MaterialPage(
      name: '/vault',
      key: ValueKey('/vault'),
      child: VaultScreen(),
    );
  }

  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vault',
          style: GoogleFonts.righteous(
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<VaultManager>(
        builder: (context, vaultManager, child) {
          if (vaultManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vaultManager.folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No folders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFolderDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Folder'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: vaultManager.folders.length,
            itemBuilder: (context, index) {
              final folder = vaultManager.folders[index];
              return FolderCard(folder: folder);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFolderDialog(context),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name (e.g. Maths)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<VaultManager>(context, listen: false)
                    .createFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class FolderCard extends StatelessWidget {
  final VaultFolder folder;

  const FolderCard({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => _showFolderOptions(context),
      onTap: () {
        Provider.of<AppStateManager>(context, listen: false)
            .goVaultFolder(folder.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                folder.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Folder'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text('This will delete "${folder.name}" and all files inside it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<VaultManager>(context, listen: false)
                  .deleteFolder(folder.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
