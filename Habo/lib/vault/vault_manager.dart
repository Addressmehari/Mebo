import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:habo/repositories/vault_repository.dart';
import 'package:habo/vault/models/vault_folder.dart';
import 'package:habo/vault/models/vault_file.dart';
import 'package:file_picker/file_picker.dart';

class VaultManager extends ChangeNotifier {
  final VaultRepository _repository;
  List<VaultFolder> folders = [];
  Map<int, List<VaultFile>> folderFiles = {}; // folderId -> files
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  VaultManager(this._repository);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    folders = await _repository.getAllFolders();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFilesForFolder(int folderId) async {
    final files = await _repository.getFilesForFolder(folderId);
    folderFiles[folderId] = files;
    notifyListeners();
  }

  Future<void> createFolder(String name) async {
    final folder = VaultFolder(
      name: name,
      createdAt: DateTime.now(),
    );
    final id = await _repository.createFolder(folder);
    folders.add(folder.copyWith(id: id));
    notifyListeners();
  }

  Future<void> deleteFolder(int folderId) async {
    // 1. Delete all physical files in this folder
    final files = await _repository.getFilesForFolder(folderId);
    for (var file in files) {
      await _deletePhysicalFile(file.localPath);
    }
    
    // 2. Delete from DB (Cascade will handle files in DB if set up, but let's be explicit if needed)
    await _repository.deleteFolder(folderId);
    folders.removeWhere((f) => f.id == folderId);
    folderFiles.remove(folderId);
    notifyListeners();
  }

  Future<void> addFileToFolder(int folderId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final platformFile = result.files.single;
      
      // Enforce 100MB limit
      const int maxSizeBytes = 100 * 1024 * 1024;
      if (platformFile.size > maxSizeBytes) {
        throw Exception("File size exceeds 100MB limit.");
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDocDir.path, 'vault', folderId.toString()));
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      final fileName = platformFile.name;
      final targetPath = p.join(vaultDir.path, fileName);
      
      // Copy file to vault
      final sourceFile = File(platformFile.path!);
      await sourceFile.copy(targetPath);

      // Save relative path to DB
      final relativePath = p.join('vault', folderId.toString(), fileName);
      
      final vaultFile = VaultFile(
        folderId: folderId,
        name: fileName,
        localPath: relativePath,
        fileType: _determineFileType(fileName),
        sizeInBytes: platformFile.size,
        createdAt: DateTime.now(),
      );

      final id = await _repository.createFile(vaultFile);
      if (folderFiles[folderId] == null) {
        folderFiles[folderId] = [];
      }
      folderFiles[folderId]!.insert(0, vaultFile.copyWith(id: id));
      notifyListeners();
    }
  }

  Future<void> deleteFile(VaultFile file) async {
    await _deletePhysicalFile(file.localPath);
    await _repository.deleteFile(file.id!);
    if (folderFiles[file.folderId] != null) {
      folderFiles[file.folderId]!.removeWhere((f) => f.id == file.id);
    }
    notifyListeners();
  }

  Future<void> _deletePhysicalFile(String relativePath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(appDocDir.path, relativePath);
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  String _determineFileType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) return 'image';
    if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) return 'video';
    if (['.pdf', '.doc', '.docx', '.txt'].contains(ext)) return 'doc';
    return 'other';
  }

  Future<String> getFullFilePath(String relativePath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return p.join(appDocDir.path, relativePath);
  }
}
