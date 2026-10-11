// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'transaction_type.dart';

class CategoryModel {
  final String id;
  final String name;
  final TransactionType type;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
    this.isDefault = false,
  });

  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
        fontPackage: iconFontPackage,
      );

  Color get color => Color(colorValue);

  CategoryModel copyWith({
    String? id,
    String? name,
    TransactionType? type,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int? colorValue,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'colorValue': colorValue,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      iconCodePoint: map['iconCodePoint'] as int? ?? Icons.category_rounded.codePoint,
      iconFontFamily: map['iconFontFamily'] as String?,
      iconFontPackage: map['iconFontPackage'] as String?,
      colorValue: map['colorValue'] as int? ?? 0xFF1976D2,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'icon_font_package': iconFontPackage,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromSqliteMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      iconCodePoint: (map['icon_code_point'] as int?) ??
          (map['iconCodePoint'] as int?) ??
          Icons.category_rounded.codePoint,
      iconFontFamily: (map['icon_font_family'] as String?) ??
          (map['iconFontFamily'] as String?),
      iconFontPackage: (map['icon_font_package'] as String?) ??
          (map['iconFontPackage'] as String?),
      colorValue: (map['color_value'] as int?) ??
          (map['colorValue'] as int?) ??
          0xFF1976D2,
      isDefault: map['is_default'] == 1 || map['isDefault'] == true,
    );
  }

  static List<CategoryModel> get defaultExpenseCategories => [
        CategoryModel(
          id: 'exp_food',
          name: 'Food & Dining',
          type: TransactionType.expense,
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          colorValue: 0xFFE65100, // Deep Orange
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_groceries',
          name: 'Groceries',
          type: TransactionType.expense,
          iconCodePoint: Icons.shopping_cart_rounded.codePoint,
          colorValue: 0xFF2E7D32, // Green
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_transport',
          name: 'Transport & Fuel',
          type: TransactionType.expense,
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          colorValue: 0xFF0288D1, // Light Blue
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_shopping',
          name: 'Shopping',
          type: TransactionType.expense,
          iconCodePoint: Icons.shopping_bag_rounded.codePoint,
          colorValue: 0xFF8E24AA, // Purple
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_bills',
          name: 'Bills & Utilities',
          type: TransactionType.expense,
          iconCodePoint: Icons.receipt_long_rounded.codePoint,
          colorValue: 0xFFF57F17, // Amber
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_rent',
          name: 'Rent & Housing',
          type: TransactionType.expense,
          iconCodePoint: Icons.home_rounded.codePoint,
          colorValue: 0xFF00897B, // Teal
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_health',
          name: 'Health & Medical',
          type: TransactionType.expense,
          iconCodePoint: Icons.local_hospital_rounded.codePoint,
          colorValue: 0xFFC62828, // Red
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_entertainment',
          name: 'Entertainment',
          type: TransactionType.expense,
          iconCodePoint: Icons.movie_rounded.codePoint,
          colorValue: 0xFFAD1457, // Pink
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_education',
          name: 'Education',
          type: TransactionType.expense,
          iconCodePoint: Icons.school_rounded.codePoint,
          colorValue: 0xFF4527A0, // Deep Purple
          isDefault: true,
        ),
        CategoryModel(
          id: 'exp_other',
          name: 'Other Expense',
          type: TransactionType.expense,
          iconCodePoint: Icons.more_horiz_rounded.codePoint,
          colorValue: 0xFF546E7A, // Blue Grey
          isDefault: true,
        ),
      ];

  static List<CategoryModel> get defaultIncomeCategories => [
        CategoryModel(
          id: 'inc_salary',
          name: 'Salary',
          type: TransactionType.income,
          iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
          colorValue: 0xFF1B5E20, // Dark Green
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_business',
          name: 'Business & Sales',
          type: TransactionType.income,
          iconCodePoint: Icons.storefront_rounded.codePoint,
          colorValue: 0xFF1565C0, // Blue
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_investment',
          name: 'Investment & Dividends',
          type: TransactionType.income,
          iconCodePoint: Icons.trending_up_rounded.codePoint,
          colorValue: 0xFF00695C, // Teal
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_freelance',
          name: 'Freelance & Side Gig',
          type: TransactionType.income,
          iconCodePoint: Icons.laptop_mac_rounded.codePoint,
          colorValue: 0xFF6A1B9A, // Purple
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_gifts',
          name: 'Gifts & Grants',
          type: TransactionType.income,
          iconCodePoint: Icons.card_giftcard_rounded.codePoint,
          colorValue: 0xFFE65100, // Orange
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_rental',
          name: 'Rental Income',
          type: TransactionType.income,
          iconCodePoint: Icons.apartment_rounded.codePoint,
          colorValue: 0xFF00838F, // Cyan
          isDefault: true,
        ),
        CategoryModel(
          id: 'inc_other',
          name: 'Other Income',
          type: TransactionType.income,
          iconCodePoint: Icons.attach_money_rounded.codePoint,
          colorValue: 0xFF455A64, // Blue Grey
          isDefault: true,
        ),
      ];

  static List<CategoryModel> get defaultCategories => [
        ...defaultExpenseCategories,
        ...defaultIncomeCategories,
      ];
}
