import 'package:habo/vault/models/vault_folder.dart';
import 'package:habo/vault/models/vault_file.dart';

abstract class VaultRepository {
  Future<List<VaultFolder>> getAllFolders();
  Future<int> createFolder(VaultFolder folder);
  Future<void> deleteFolder(int folderId);
  
  Future<List<VaultFile>> getFilesForFolder(int folderId);
  Future<int> createFile(VaultFile file);
  Future<void> deleteFile(int fileId);
}
