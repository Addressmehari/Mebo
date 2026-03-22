import 'package:flutter/foundation.dart';

@immutable
class VaultFolder {
  final int? id;
  final String name;
  final DateTime createdAt;
  final int? iconCode; // Optional icon for folder

  const VaultFolder({
    this.id,
    required this.name,
    required this.createdAt,
    this.iconCode,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      if (iconCode != null) 'iconCode': iconCode,
    };
  }

  factory VaultFolder.fromMap(Map<String, dynamic> map) {
    return VaultFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      iconCode: map['iconCode'] as int?,
    );
  }

  VaultFolder copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    int? iconCode,
  }) {
    return VaultFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
