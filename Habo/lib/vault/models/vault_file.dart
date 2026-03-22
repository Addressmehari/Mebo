import 'package:flutter/foundation.dart';

@immutable
class VaultFile {
  final int? id;
  final int folderId; // Reference to folder id
  final String name; // Filentame (e.g. maths.pdf)
  final String localPath; // Relative path in internal storage
  final String fileType; // image, docs, video, etc
  final int sizeInBytes; // Size in bytes (< 100MB)
  final DateTime createdAt;

  const VaultFile({
    this.id,
    required this.folderId,
    required this.name,
    required this.localPath,
    required this.fileType,
    required this.sizeInBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'folder_id': folderId,
      'name': name,
      'localPath': localPath,
      'fileType': fileType,
      'sizeInBytes': sizeInBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VaultFile.fromMap(Map<String, dynamic> map) {
    return VaultFile(
      id: map['id'] as int?,
      folderId: map['folder_id'] as int,
      name: map['name'] as String,
      localPath: map['localPath'] as String,
      fileType: map['fileType'] as String,
      sizeInBytes: map['sizeInBytes'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  VaultFile copyWith({
    int? id,
    int? folderId,
    String? name,
    String? localPath,
    String? fileType,
    int? sizeInBytes,
    DateTime? createdAt,
  }) {
    return VaultFile(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      fileType: fileType ?? this.fileType,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
