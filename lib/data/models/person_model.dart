import 'package:flutter/material.dart';

class PersonModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final int colorValue;
  final bool isCurrentUser;
  final DateTime createdAt;

  const PersonModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.colorValue,
    this.isCurrentUser = false,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  PersonModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    int? colorValue,
    bool? isCurrentUser,
    DateTime? createdAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      colorValue: colorValue ?? this.colorValue,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'color_value': colorValue,
      'is_current_user': isCurrentUser ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PersonModel.fromSqliteMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phone_number'] as String?,
      colorValue: map['color_value'] as int,
      isCurrentUser: (map['is_current_user'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static const String currentUserDefaultId = 'person_you';

  static PersonModel get defaultCurrentUser => PersonModel(
        id: currentUserDefaultId,
        name: 'You',
        phoneNumber: null,
        colorValue: 0xFF1E88E5,
        isCurrentUser: true,
        createdAt: DateTime(2025, 1, 1),
      );
}
