import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class CashBookStorageService {
  static const String _categoriesKey = 'cash_book_categories_v1';
  static const String _transactionsKey = 'cash_book_transactions_v1';

  Future<List<CategoryModel>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_categoriesKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        // Return default categories on first launch
        final defaults = CategoryModel.defaultCategories;
        await saveCategories(defaults);
        return defaults;
      }
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return CategoryModel.defaultCategories;
    }
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = categories.map((cat) => cat.toMap()).toList();
      await prefs.setString(_categoriesKey, jsonEncode(data));
    } catch (e) {
      // In case of storage issues, ignore or log
    }
  }

  Future<List<TransactionModel>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_transactionsKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = transactions.map((tx) => tx.toMap()).toList();
      await prefs.setString(_transactionsKey, jsonEncode(data));
    } catch (e) {
      // In case of storage issues, ignore or log
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.remove(_categoriesKey);
  }
}

