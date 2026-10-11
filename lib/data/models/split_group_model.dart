// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class SplitGroupModel {
  final String id;
  final String name;
  final String? description;
  final int iconCodePoint;
  final int colorValue;
  final List<String> memberIds;
  final DateTime createdAt;

  const SplitGroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconCodePoint,
    required this.colorValue,
    this.memberIds = const [],
    required this.createdAt,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  SplitGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return SplitGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_code_point': iconCodePoint,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SplitGroupModel.fromSqliteMap(
    Map<String, dynamic> map, {
    List<String> memberIds = const [],
  }) {
    return SplitGroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCodePoint: map['icon_code_point'] as int? ?? Icons.group.codePoint,
      colorValue: map['color_value'] as int? ?? 0xFF00897B,
      memberIds: memberIds,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
