import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class PersonModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? upiId;
  final int colorValue;
  final bool isCurrentUser;
  final DateTime createdAt;

  const PersonModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.upiId,
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
    String? upiId,
    int? colorValue,
    bool? isCurrentUser,
    DateTime? createdAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
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
      'upi_id': upiId,
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
      upiId: map['upi_id'] as String?,
      colorValue: map['color_value'] as int,
      isCurrentUser: (map['is_current_user'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static const String currentUserDefaultId = AppConstants.defaultCurrentUserId;

  static PersonModel get defaultCurrentUser => PersonModel(
        id: currentUserDefaultId,
        name: AppConstants.defaultCurrentUserName,
        phoneNumber: null,
        upiId: null,
        colorValue: AppConstants.defaultCurrentUserColor,
        isCurrentUser: true,
        createdAt: AppConstants.defaultCurrentUserCreatedAt,
      );
}
