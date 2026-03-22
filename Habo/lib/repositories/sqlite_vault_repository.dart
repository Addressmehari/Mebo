import 'package:habo/model/habo_model.dart';
import 'package:habo/repositories/vault_repository.dart';
import 'package:habo/vault/models/vault_folder.dart';
import 'package:habo/vault/models/vault_file.dart';

class SqliteVaultRepository implements VaultRepository {
  final HaboModel _model;

  SqliteVaultRepository(this._model);

  @override
  Future<List<VaultFolder>> getAllFolders() async {
    final maps = await _model.getAllVaultFolders();
    return maps.map((m) => VaultFolder.fromMap(m)).toList();
  }

  @override
  Future<int> createFolder(VaultFolder folder) async {
    return await _model.insertVaultFolder(folder.toMap());
  }

  @override
  Future<void> deleteFolder(int folderId) async {
    await _model.deleteVaultFolder(folderId);
  }

  @override
  Future<List<VaultFile>> getFilesForFolder(int folderId) async {
    final maps = await _model.getVaultFilesForFolder(folderId);
    return maps.map((m) => VaultFile.fromMap(m)).toList();
  }

  @override
  Future<int> createFile(VaultFile file) async {
    return await _model.insertVaultFile(file.toMap());
  }

  @override
  Future<void> deleteFile(int fileId) async {
    await _model.deleteVaultFile(fileId);
  }
}
