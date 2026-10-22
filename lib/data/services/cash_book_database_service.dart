import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/app_settings.dart';
import '../models/category_model.dart';
import '../models/person_model.dart';
import '../models/settlement_model.dart';
import '../models/split_expense_model.dart';
import '../models/split_group_model.dart';
import '../models/transaction_model.dart';
import '../../config/app_constants.dart';
import '../../ui/utils/formatters.dart';

class CashBookDatabaseService {
  static const String _dbName = AppConstants.dbName;
  static const int _dbVersion = AppConstants.dbVersion;

  static const String tableCategories = AppConstants.tableCategories;
  static const String tableTransactions = AppConstants.tableTransactions;
  static const String tablePersons = AppConstants.tablePersons;
  static const String tableGroups = AppConstants.tableGroups;
  static const String tableGroupMembers = AppConstants.tableGroupMembers;
  static const String tableSplitExpenses = AppConstants.tableSplitExpenses;
  static const String tableExpenseSplits = AppConstants.tableExpenseSplits;
  static const String tableSettlements = AppConstants.tableSettlements;

  Database? _db;
  final String? customDbPath;

  CashBookDatabaseService({this.customDbPath});

  static void ensurePlatformInitialized() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    ensurePlatformInitialized();

    String path;
    if (customDbPath != null) {
      path = customDbPath!;
    } else {
      final databasesPath = await getDatabasesPath();
      path = p.join(databasesPath, _dbName);
    }

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _createSplitTables(db);
        await _seedDefaultCategories(db);
        await _seedDefaultPersons(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSplitTables(db);
          await _seedDefaultPersons(db);
        }
        if (oldVersion < 3) {
          await _ensureBaseInrColumns(db);
          await _healAndBackfillBaseInrAmounts(db);
        }
      },
      onOpen: (db) async {
        await _ensurePersonColumns(db);
        await _ensureBaseInrColumns(db);
        await _ensureAttachmentColumns(db);
        await _healAndBackfillBaseInrAmounts(db);
        await _cleanupOrphanData(db);
      },
    );
  }

  @visibleForTesting
  Future<void> onDatabaseOpenForTest(Database db) async {
    await _ensureBaseInrColumns(db);
    await _ensureAttachmentColumns(db);
    await _healAndBackfillBaseInrAmounts(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        icon_font_package TEXT,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTransactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        base_inr_amount REAL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        title TEXT,
        payment_mode TEXT NOT NULL DEFAULT 'Cash',
        attachment_path TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON $tableTransactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type ON $tableTransactions(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON $tableTransactions(category_id)',
    );
  }

  Future<void> _createSplitTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePersons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone_number TEXT,
        upi_id TEXT,
        color_value INTEGER NOT NULL,
        is_current_user INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableGroups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableGroupMembers (
        group_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        PRIMARY KEY (group_id, person_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSplitExpenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        total_amount REAL NOT NULL,
        base_inr_amount REAL,
        date TEXT NOT NULL,
        paid_by_person_id TEXT NOT NULL,
        group_id TEXT,
        category_id TEXT,
        notes TEXT,
        split_type TEXT NOT NULL DEFAULT 'equal',
        linked_cash_book_tx_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExpenseSplits (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        amount REAL NOT NULL,
        base_inr_amount REAL,
        percentage REAL,
        shares INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettlements (
        id TEXT PRIMARY KEY,
        payer_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        amount REAL NOT NULL,
        base_inr_amount REAL,
        date TEXT NOT NULL,
        group_id TEXT,
        payment_method TEXT NOT NULL DEFAULT 'UPI',
        notes TEXT,
        linked_cash_book_tx_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_expenses_date ON $tableSplitExpenses(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_expenses_group ON $tableSplitExpenses(group_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expense_splits_exp ON $tableExpenseSplits(expense_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_settlements_date ON $tableSettlements(date DESC)',
    );
  }

  Future<void> _ensurePersonColumns(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($tablePersons)');
      final hasUpi = info.any((col) => col['name'] == 'upi_id');
      if (!hasUpi) {
        await db.execute('ALTER TABLE $tablePersons ADD COLUMN upi_id TEXT');
      }
    } catch (e) {
      debugPrint('Error ensuring upi_id on $tablePersons: $e');
    }
  }

  Future<void> _ensureAttachmentColumns(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($tableTransactions)');
      final hasAttachment = info.any((col) => col['name'] == 'attachment_path');
      if (!hasAttachment) {
        await db.execute('ALTER TABLE $tableTransactions ADD COLUMN attachment_path TEXT');
      }
    } catch (e) {
      debugPrint('Error ensuring attachment_path on $tableTransactions: $e');
    }
  }

  Future<void> _ensureBaseInrColumns(Database db) async {
    final tables = [
      tableTransactions,
      tableSplitExpenses,
      tableExpenseSplits,
      tableSettlements,
    ];
    for (final tbl in tables) {
      try {
        final info = await db.rawQuery('PRAGMA table_info($tbl)');
        final hasBaseInr = info.any((col) => col['name'] == 'base_inr_amount');
        if (!hasBaseInr) {
          await db.execute('ALTER TABLE $tbl ADD COLUMN base_inr_amount REAL');
        }
      } catch (e) {
        debugPrint('Error ensuring base_inr_amount on $tbl: $e');
      }
    }
  }

  Future<void> _healAndBackfillBaseInrAmounts(Database db) async {
    try {
      String currentCode = AppFormatters.currencyCode;
      Map<String, double>? customRates;
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(AppConstants.keySettings);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          currentCode =
              (decoded['currencyCode'] as String?)?.toUpperCase() ?? currentCode;
          if (decoded['customExchangeRates'] != null) {
            customRates =
                (decoded['customExchangeRates'] as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, (v as num).toDouble()));
          }
        }
      } catch (_) {
        // Fallback to in-memory AppFormatters.currencyCode if SharedPreferences is unavailable
      }

      final rateToInr = customRates?[currentCode] ??
          CurrencyConversionHelper.defaultRatesToInr[currentCode] ??
          1.0;

      // 1. Transactions
      final txRows = await db.query(tableTransactions);
      for (final row in txRows) {
        final id = row['id'] as String;
        final currentAmount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (baseInr == null) {
          if (currentCode == 'INR') {
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              currentAmount,
              ratesToInr: customRates,
            );
          } else {
            final convertedToInr = currentAmount * rateToInr;
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              convertedToInr,
              ratesToInr: customRates,
            );
          }
        } else {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr,
            ratesToInr: customRates,
          );
        }

        if (currentAmount != baseInr || (row['base_inr_amount'] as num?)?.toDouble() != baseInr) {
          await db.update(
            tableTransactions,
            {'amount': baseInr, 'base_inr_amount': baseInr},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      // 2. Split Expenses
      final expRows = await db.query(tableSplitExpenses);
      for (final row in expRows) {
        final id = row['id'] as String;
        final totalAmount = (row['total_amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (baseInr == null) {
          if (currentCode == 'INR') {
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              totalAmount,
              ratesToInr: customRates,
            );
          } else {
            final convertedToInr = totalAmount * rateToInr;
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              convertedToInr,
              ratesToInr: customRates,
            );
          }
        } else {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr,
            ratesToInr: customRates,
          );
        }

        if (totalAmount != baseInr || (row['base_inr_amount'] as num?)?.toDouble() != baseInr) {
          await db.update(
            tableSplitExpenses,
            {'total_amount': baseInr, 'base_inr_amount': baseInr},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      // 3. Expense Splits
      final splitRows = await db.query(tableExpenseSplits);
      for (final row in splitRows) {
        final id = row['id'] as String;
        final amount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (baseInr == null) {
          if (currentCode == 'INR') {
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              amount,
              ratesToInr: customRates,
            );
          } else {
            final convertedToInr = amount * rateToInr;
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              convertedToInr,
              ratesToInr: customRates,
            );
          }
        } else {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr,
            ratesToInr: customRates,
          );
        }

        if (amount != baseInr || (row['base_inr_amount'] as num?)?.toDouble() != baseInr) {
          await db.update(
            tableExpenseSplits,
            {'amount': baseInr, 'base_inr_amount': baseInr},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      // 4. Settlements
      final settleRows = await db.query(tableSettlements);
      for (final row in settleRows) {
        final id = row['id'] as String;
        final amount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (baseInr == null) {
          if (currentCode == 'INR') {
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              amount,
              ratesToInr: customRates,
            );
          } else {
            final convertedToInr = amount * rateToInr;
            baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
              convertedToInr,
              ratesToInr: customRates,
            );
          }
        } else {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr,
            ratesToInr: customRates,
          );
        }

        if (amount != baseInr || (row['base_inr_amount'] as num?)?.toDouble() != baseInr) {
          await db.update(
            tableSettlements,
            {'amount': baseInr, 'base_inr_amount': baseInr},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } catch (e) {
      debugPrint('Error healing and backfilling base INR amounts: $e');
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final batch = db.batch();
    for (final cat in CategoryModel.defaultCategories) {
      batch.insert(
        tableCategories,
        cat.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedDefaultPersons(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tablePersons'),
    );

    if (count == null || count == 0) {
      final now = DateTime.now();
      final batch = db.batch();

      // Current user
      final you = PersonModel.defaultCurrentUser;
      batch.insert(tablePersons, you.toSqliteMap());

      // Sample friends
      final rahul = PersonModel(
        id: 'person_rahul',
        name: 'Rahul Sharma',
        phoneNumber: '+91 98765 43210',
        colorValue: 0xFF43A047, // Green
        isCurrentUser: false,
        createdAt: now.subtract(const Duration(days: 30)),
      );
      final sneha = PersonModel(
        id: 'person_sneha',
        name: 'Sneha Patel',
        phoneNumber: '+91 98123 45678',
        colorValue: 0xFF8E24AA, // Purple
        isCurrentUser: false,
        createdAt: now.subtract(const Duration(days: 25)),
      );
      final amit = PersonModel(
        id: 'person_amit',
        name: 'Amit Verma',
        phoneNumber: '+91 99887 76655',
        colorValue: 0xFFFF8F00, // Amber
        isCurrentUser: false,
        createdAt: now.subtract(const Duration(days: 20)),
      );

      batch.insert(tablePersons, rahul.toSqliteMap());
      batch.insert(tablePersons, sneha.toSqliteMap());
      batch.insert(tablePersons, amit.toSqliteMap());

      // Sample Group: "Weekend Trip"
      final sampleGroup = SplitGroupModel(
        id: 'group_weekend_trip',
        name: 'Weekend Trip',
        description: 'Road trip & food expenses',
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        colorValue: 0xFF00897B, // Teal
        memberIds: [you.id, rahul.id, sneha.id],
        createdAt: now.subtract(const Duration(days: 5)),
      );
      batch.insert(tableGroups, sampleGroup.toSqliteMap());
      batch.insert(tableGroupMembers, {'group_id': sampleGroup.id, 'person_id': you.id});
      batch.insert(tableGroupMembers, {'group_id': sampleGroup.id, 'person_id': rahul.id});
      batch.insert(tableGroupMembers, {'group_id': sampleGroup.id, 'person_id': sneha.id});

      // Sample expense: "Dinner & Drinks" ₹1,500 paid by You, split equally ₹500 each
      final sampleExp = SplitExpenseModel(
        id: 'exp_sample_1',
        title: 'Dinner & Drinks',
        totalAmount: 1500.0,
        baseInrAmount: 1500.0,
        date: now.subtract(const Duration(days: 2)),
        paidByPersonId: you.id,
        groupId: sampleGroup.id,
        categoryId: 'exp_food',
        notes: 'Delicious cafe dinner',
        splitType: 'equal',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      batch.insert(tableSplitExpenses, sampleExp.toSqliteMap());

      batch.insert(tableExpenseSplits, {
        'id': 'split_1_1',
        'expense_id': sampleExp.id,
        'person_id': you.id,
        'amount': 500.0,
        'base_inr_amount': 500.0,
      });
      batch.insert(tableExpenseSplits, {
        'id': 'split_1_2',
        'expense_id': sampleExp.id,
        'person_id': rahul.id,
        'amount': 500.0,
        'base_inr_amount': 500.0,
      });
      batch.insert(tableExpenseSplits, {
        'id': 'split_1_3',
        'expense_id': sampleExp.id,
        'person_id': sneha.id,
        'amount': 500.0,
        'base_inr_amount': 500.0,
      });

      await batch.commit(noResult: true);
    }
  }

  /// Migrates data from legacy SharedPreferences if present
  Future<void> migrateFromSharedPreferencesIfApplicable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? categoriesJson = prefs.getString(AppConstants.keyCategoriesLegacy);
      final String? transactionsJson = prefs.getString(AppConstants.keyTransactionsLegacy);

      if (transactionsJson != null && transactionsJson.isNotEmpty) {
        final db = await database;
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableTransactions'),
        );

        if (count == 0) {
          importFromSharedPreferences(categoriesJson, transactionsJson);
        }
      }
    } catch (_) {
      // Ignore migration errors to avoid blocking startup
    }
  }

  Future<void> importFromSharedPreferences(
    String? categoriesJson,
    String? transactionsJson,
  ) async {
    final db = await database;
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(categoriesJson) as List<dynamic>;
        final batch = db.batch();
        for (final item in decoded) {
          final cat = CategoryModel.fromMap(item as Map<String, dynamic>);
          batch.insert(
            tableCategories,
            cat.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }

    if (transactionsJson != null && transactionsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(transactionsJson) as List<dynamic>;
        final batch = db.batch();
        for (final item in decoded) {
          final tx = TransactionModel.fromMap(item as Map<String, dynamic>);
          batch.insert(
            tableTransactions,
            tx.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }
  }

  // --- Category Operations ---

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCategories,
      orderBy: 'is_default DESC, name ASC',
    );

    if (maps.isEmpty) {
      await _seedDefaultCategories(db);
      return CategoryModel.defaultCategories;
    }

    return maps.map((m) => CategoryModel.fromSqliteMap(m)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      tableCategories,
      category.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      tableCategories,
      category.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<bool> deleteCategory(String id) async {
    final db = await database;

    final existing = await db.query(
      tableCategories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (existing.isEmpty) return false;
    final cat = CategoryModel.fromSqliteMap(existing.first);
    if (cat.isDefault) return false;

    final fallbackCatId = cat.type.name == 'income'
        ? AppConstants.fallbackIncomeCategoryId
        : AppConstants.fallbackExpenseCategoryId;

    await db.transaction((txn) async {
      await txn.update(
        tableTransactions,
        {'category_id': fallbackCatId},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        tableCategories,
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    return true;
  }

  Future<void> resetCategoriesToDefaults() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableCategories);
      final batch = txn.batch();
      for (final cat in CategoryModel.defaultCategories) {
        batch.insert(tableCategories, cat.toSqliteMap());
      }
      await batch.commit(noResult: true);
    });
  }

  // --- Transaction Operations ---

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromSqliteMap(m)).toList();
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    final map = transaction.toSqliteMap();
    if (map['base_inr_amount'] == null) {
      final currentCode = AppFormatters.currencyCode;
      map['base_inr_amount'] = CurrencyConversionHelper.convert(
        transaction.amount,
        fromCode: currentCode,
        toCode: 'INR',
      );
    }
    await db.insert(
      tableTransactions,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    final map = transaction.toSqliteMap();
    if (map['base_inr_amount'] == null) {
      final currentCode = AppFormatters.currencyCode;
      map['base_inr_amount'] = CurrencyConversionHelper.convert(
        transaction.amount,
        fromCode: currentCode,
        toCode: 'INR',
      );
    }
    await db.update(
      tableTransactions,
      map,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Persons Operations ---

  Future<List<PersonModel>> getPersons() async {
    final db = await database;
    final maps = await db.query(
      tablePersons,
      orderBy: 'is_current_user DESC, name ASC',
    );
    return maps.map((m) => PersonModel.fromSqliteMap(m)).toList();
  }

  Future<void> insertPerson(PersonModel person) async {
    final db = await database;
    await db.insert(
      tablePersons,
      person.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePerson(PersonModel person) async {
    final db = await database;
    await db.update(
      tablePersons,
      person.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<bool> deletePerson(String id) async {
    if (id == PersonModel.currentUserDefaultId) return false;
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableGroupMembers, where: 'person_id = ?', whereArgs: [id]);
      await txn.delete(tablePersons, where: 'id = ?', whereArgs: [id]);

      // Delete expenses paid by this person
      final expRows = await txn.query(
        tableSplitExpenses,
        columns: ['id', 'linked_cash_book_tx_id'],
        where: 'paid_by_person_id = ?',
        whereArgs: [id],
      );
      for (final r in expRows) {
        final expId = r['id'] as String;
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await txn.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
        await txn.delete(tableExpenseSplits, where: 'expense_id = ?', whereArgs: [expId]);
      }
      await txn.delete(tableSplitExpenses, where: 'paid_by_person_id = ?', whereArgs: [id]);

      // Remove this person from any remaining expense splits
      await txn.delete(tableExpenseSplits, where: 'person_id = ?', whereArgs: [id]);

      // Delete settlements involving this person
      final settleRows = await txn.query(
        tableSettlements,
        columns: ['id', 'linked_cash_book_tx_id'],
        where: 'payer_id = ? OR receiver_id = ?',
        whereArgs: [id, id],
      );
      for (final r in settleRows) {
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await txn.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
      }
      await txn.delete(tableSettlements, where: 'payer_id = ? OR receiver_id = ?', whereArgs: [id, id]);
    });
    return true;
  }

  // --- Group Operations ---

  Future<List<SplitGroupModel>> getGroups() async {
    final db = await database;
    final groupMaps = await db.query(
      tableGroups,
      orderBy: 'created_at DESC',
    );

    final List<SplitGroupModel> groups = [];
    for (final map in groupMaps) {
      final groupId = map['id'] as String;
      final memberRows = await db.query(
        tableGroupMembers,
        columns: ['person_id'],
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      final memberIds = memberRows.map((r) => r['person_id'] as String).toList();
      groups.add(SplitGroupModel.fromSqliteMap(map, memberIds: memberIds));
    }
    return groups;
  }

  Future<void> insertGroup(SplitGroupModel group) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        tableGroups,
        group.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final personId in group.memberIds) {
        await txn.insert(
          tableGroupMembers,
          {'group_id': group.id, 'person_id': personId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> updateGroup(SplitGroupModel group) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableGroups,
        group.toSqliteMap(),
        where: 'id = ?',
        whereArgs: [group.id],
      );
      await txn.delete(
        tableGroupMembers,
        where: 'group_id = ?',
        whereArgs: [group.id],
      );
      for (final personId in group.memberIds) {
        await txn.insert(
          tableGroupMembers,
          {'group_id': group.id, 'person_id': personId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableGroupMembers, where: 'group_id = ?', whereArgs: [id]);
      await txn.delete(tableGroups, where: 'id = ?', whereArgs: [id]);

      // Cascade delete split expenses and linked cash book transactions for this group
      final expRows = await txn.query(
        tableSplitExpenses,
        columns: ['id', 'linked_cash_book_tx_id'],
        where: 'group_id = ?',
        whereArgs: [id],
      );
      for (final r in expRows) {
        final expId = r['id'] as String;
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await txn.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
        await txn.delete(tableExpenseSplits, where: 'expense_id = ?', whereArgs: [expId]);
      }
      await txn.delete(tableSplitExpenses, where: 'group_id = ?', whereArgs: [id]);

      // Cascade delete settlements for this group
      final settleRows = await txn.query(
        tableSettlements,
        columns: ['id', 'linked_cash_book_tx_id'],
        where: 'group_id = ?',
        whereArgs: [id],
      );
      for (final r in settleRows) {
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await txn.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
      }
      await txn.delete(tableSettlements, where: 'group_id = ?', whereArgs: [id]);
    });
  }

  // --- Split Expenses Operations ---

  Future<List<SplitExpenseModel>> getSplitExpenses({
    String? groupId,
    String? personId,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (groupId != null) {
      whereClause = 'group_id = ?';
      whereArgs = [groupId];
    }

    final expenseMaps = await db.query(
      tableSplitExpenses,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    final List<SplitExpenseModel> expenses = [];
    for (final map in expenseMaps) {
      final expenseId = map['id'] as String;
      final splitRows = await db.query(
        tableExpenseSplits,
        where: 'expense_id = ?',
        whereArgs: [expenseId],
      );
      final splits = splitRows.map((r) => ExpenseSplitItem.fromSqliteMap(r)).toList();
      expenses.add(SplitExpenseModel.fromSqliteMap(map, splits: splits));
    }

    if (personId != null) {
      return expenses.where((e) {
        return e.paidByPersonId == personId ||
            e.splits.any((s) => s.personId == personId);
      }).toList();
    }

    return expenses;
  }

  Future<void> insertSplitExpense(SplitExpenseModel expense) async {
    final db = await database;
    final map = expense.toSqliteMap();
    final currentCode = AppFormatters.currencyCode;
    if (map['base_inr_amount'] == null) {
      map['base_inr_amount'] = CurrencyConversionHelper.convert(
        expense.totalAmount,
        fromCode: currentCode,
        toCode: 'INR',
      );
    }
    await db.transaction((txn) async {
      await txn.insert(
        tableSplitExpenses,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (int i = 0; i < expense.splits.length; i++) {
        final split = expense.splits[i];
        final splitId = '${expense.id}_split_$i';
        final splitMap = split.toSqliteMap(expense.id, splitId);
        if (splitMap['base_inr_amount'] == null) {
          splitMap['base_inr_amount'] = CurrencyConversionHelper.convert(
            split.amount,
            fromCode: currentCode,
            toCode: 'INR',
          );
        }
        await txn.insert(
          tableExpenseSplits,
          splitMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateSplitExpense(SplitExpenseModel expense) async {
    final db = await database;
    final map = expense.toSqliteMap();
    final currentCode = AppFormatters.currencyCode;
    if (map['base_inr_amount'] == null) {
      map['base_inr_amount'] = CurrencyConversionHelper.convert(
        expense.totalAmount,
        fromCode: currentCode,
        toCode: 'INR',
      );
    }
    await db.transaction((txn) async {
      await txn.update(
        tableSplitExpenses,
        map,
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      await txn.delete(
        tableExpenseSplits,
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      for (int i = 0; i < expense.splits.length; i++) {
        final split = expense.splits[i];
        final splitId = '${expense.id}_split_$i';
        final splitMap = split.toSqliteMap(expense.id, splitId);
        if (splitMap['base_inr_amount'] == null) {
          splitMap['base_inr_amount'] = CurrencyConversionHelper.convert(
            split.amount,
            fromCode: currentCode,
            toCode: 'INR',
          );
        }
        await txn.insert(
          tableExpenseSplits,
          splitMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteSplitExpense(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableExpenseSplits, where: 'expense_id = ?', whereArgs: [id]);
      await txn.delete(tableSplitExpenses, where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Settlements Operations ---

  Future<List<SettlementModel>> getSettlements({
    String? groupId,
    String? personId,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (groupId != null) {
      whereClause = 'group_id = ?';
      whereArgs = [groupId];
    }

    final maps = await db.query(
      tableSettlements,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    final settlements = maps.map((m) => SettlementModel.fromSqliteMap(m)).toList();

    if (personId != null) {
      return settlements
          .where((s) => s.payerId == personId || s.receiverId == personId)
          .toList();
    }

    return settlements;
  }

  Future<void> insertSettlement(SettlementModel settlement) async {
    final db = await database;
    final map = settlement.toSqliteMap();
    if (map['base_inr_amount'] == null) {
      final currentCode = AppFormatters.currencyCode;
      map['base_inr_amount'] = CurrencyConversionHelper.convert(
        settlement.amount,
        fromCode: currentCode,
        toCode: 'INR',
      );
    }
    await db.insert(
      tableSettlements,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSettlement(String id) async {
    final db = await database;
    await db.delete(
      tableSettlements,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> _cleanupOrphanData(Database db) async {
    try {
      // 1. Delete expense splits whose parent split expense no longer exists
      await db.execute(
        'DELETE FROM $tableExpenseSplits WHERE expense_id NOT IN (SELECT id FROM $tableSplitExpenses)',
      );

      // 2. Delete split expenses belonging to a group that no longer exists
      final orphanGroupExpenses = await db.rawQuery(
        'SELECT id, linked_cash_book_tx_id FROM $tableSplitExpenses WHERE group_id IS NOT NULL AND group_id NOT IN (SELECT id FROM $tableGroups)',
      );
      for (final r in orphanGroupExpenses) {
        final expId = r['id'] as String;
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await db.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
        await db.delete(tableExpenseSplits, where: 'expense_id = ?', whereArgs: [expId]);
      }
      await db.execute(
        'DELETE FROM $tableSplitExpenses WHERE group_id IS NOT NULL AND group_id NOT IN (SELECT id FROM $tableGroups)',
      );

      // 3. Delete settlements belonging to a group that no longer exists
      final orphanGroupSettlements = await db.rawQuery(
        'SELECT id, linked_cash_book_tx_id FROM $tableSettlements WHERE group_id IS NOT NULL AND group_id NOT IN (SELECT id FROM $tableGroups)',
      );
      for (final r in orphanGroupSettlements) {
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await db.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
      }
      await db.execute(
        'DELETE FROM $tableSettlements WHERE group_id IS NOT NULL AND group_id NOT IN (SELECT id FROM $tableGroups)',
      );

      // 4. Delete split expenses whose payer no longer exists in persons table
      final orphanPayerExpenses = await db.rawQuery(
        'SELECT id, linked_cash_book_tx_id FROM $tableSplitExpenses WHERE paid_by_person_id NOT IN (SELECT id FROM $tablePersons)',
      );
      for (final r in orphanPayerExpenses) {
        final expId = r['id'] as String;
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await db.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
        await db.delete(tableExpenseSplits, where: 'expense_id = ?', whereArgs: [expId]);
      }
      await db.execute(
        'DELETE FROM $tableSplitExpenses WHERE paid_by_person_id NOT IN (SELECT id FROM $tablePersons)',
      );

      // 5. Delete expense splits for persons who no longer exist
      await db.execute(
        'DELETE FROM $tableExpenseSplits WHERE person_id NOT IN (SELECT id FROM $tablePersons)',
      );

      // 6. Delete settlements where payer or receiver no longer exists
      final orphanPersonSettlements = await db.rawQuery(
        'SELECT id, linked_cash_book_tx_id FROM $tableSettlements WHERE payer_id NOT IN (SELECT id FROM $tablePersons) OR receiver_id NOT IN (SELECT id FROM $tablePersons)',
      );
      for (final r in orphanPersonSettlements) {
        final linkedTxId = r['linked_cash_book_tx_id'] as String?;
        if (linkedTxId != null) {
          await db.delete(tableTransactions, where: 'id = ?', whereArgs: [linkedTxId]);
        }
      }
      await db.execute(
        'DELETE FROM $tableSettlements WHERE payer_id NOT IN (SELECT id FROM $tablePersons) OR receiver_id NOT IN (SELECT id FROM $tablePersons)',
      );
    } catch (e) {
      debugPrint('Error cleaning orphan data: $e');
    }
  }

  /// Converts all monetary amounts in the database using [conversionFactor].
  /// Preserves canonical base INR amounts so that switching between currencies
  /// (e.g. INR -> USD -> INR) is completely lossless and prevents fractional point drift.
  Future<void> convertAllCurrencyAmounts(
    double conversionFactor, {
    String? fromCurrency,
    String? toCurrency,
    Map<String, double>? ratesToInr,
  }) async {
    final db = await database;
    final targetCode = toCurrency?.toUpperCase() ??
        ((conversionFactor >= 50.0 ||
                (conversionFactor - 86.50).abs() < 1.0 ||
                (conversionFactor - 94.00).abs() < 1.0)
            ? 'INR'
            : 'USD');
    final isTargetInr = targetCode == 'INR';
    final isSourceInr = fromCurrency?.toUpperCase() == 'INR';

    await db.transaction((txn) async {
      // 1. Transactions
      final txRows = await txn.query(tableTransactions);
      for (final row in txRows) {
        final id = row['id'] as String;
        final currentAmount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (isSourceInr || (baseInr == null && !isTargetInr)) {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr ?? currentAmount,
            ratesToInr: ratesToInr,
          );
        }

        double newAmount;
        if (isTargetInr) {
          if (baseInr != null && baseInr > 0) {
            newAmount = baseInr;
          } else {
            final raw = currentAmount * conversionFactor;
            newAmount = CurrencyConversionHelper.recoverDriftedInrAmount(
              raw,
              ratesToInr: ratesToInr,
            );
            baseInr = newAmount;
          }
        } else {
          final effectiveBase = baseInr ?? currentAmount;
          newAmount = double.parse(
            CurrencyConversionHelper.convert(
              effectiveBase,
              fromCode: 'INR',
              toCode: targetCode,
              ratesToInr: ratesToInr,
            ).toStringAsFixed(2),
          );
          baseInr = effectiveBase;
        }

        await txn.update(
          tableTransactions,
          {'amount': newAmount, 'base_inr_amount': baseInr},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 2. Split Expenses
      final splitExpRows = await txn.query(tableSplitExpenses);
      for (final row in splitExpRows) {
        final id = row['id'] as String;
        final currentAmount = (row['total_amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (isSourceInr || (baseInr == null && !isTargetInr)) {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr ?? currentAmount,
            ratesToInr: ratesToInr,
          );
        }

        double newAmount;
        if (isTargetInr) {
          if (baseInr != null && baseInr > 0) {
            newAmount = baseInr;
          } else {
            final raw = currentAmount * conversionFactor;
            newAmount = CurrencyConversionHelper.recoverDriftedInrAmount(
              raw,
              ratesToInr: ratesToInr,
            );
            baseInr = newAmount;
          }
        } else {
          final effectiveBase = baseInr ?? currentAmount;
          newAmount = double.parse(
            CurrencyConversionHelper.convert(
              effectiveBase,
              fromCode: 'INR',
              toCode: targetCode,
              ratesToInr: ratesToInr,
            ).toStringAsFixed(2),
          );
          baseInr = effectiveBase;
        }

        await txn.update(
          tableSplitExpenses,
          {'total_amount': newAmount, 'base_inr_amount': baseInr},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 3. Expense Splits
      final splitRows = await txn.query(tableExpenseSplits);
      for (final row in splitRows) {
        final id = row['id'] as String;
        final currentAmount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (isSourceInr || (baseInr == null && !isTargetInr)) {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr ?? currentAmount,
            ratesToInr: ratesToInr,
          );
        }

        double newAmount;
        if (isTargetInr) {
          if (baseInr != null && baseInr > 0) {
            newAmount = baseInr;
          } else {
            final raw = currentAmount * conversionFactor;
            newAmount = CurrencyConversionHelper.recoverDriftedInrAmount(
              raw,
              ratesToInr: ratesToInr,
            );
            baseInr = newAmount;
          }
        } else {
          final effectiveBase = baseInr ?? currentAmount;
          newAmount = double.parse(
            CurrencyConversionHelper.convert(
              effectiveBase,
              fromCode: 'INR',
              toCode: targetCode,
              ratesToInr: ratesToInr,
            ).toStringAsFixed(2),
          );
          baseInr = effectiveBase;
        }

        await txn.update(
          tableExpenseSplits,
          {'amount': newAmount, 'base_inr_amount': baseInr},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 4. Settlements
      final settleRows = await txn.query(tableSettlements);
      for (final row in settleRows) {
        final id = row['id'] as String;
        final currentAmount = (row['amount'] as num).toDouble();
        double? baseInr = (row['base_inr_amount'] as num?)?.toDouble();

        if (isSourceInr || (baseInr == null && !isTargetInr)) {
          baseInr = CurrencyConversionHelper.recoverDriftedInrAmount(
            baseInr ?? currentAmount,
            ratesToInr: ratesToInr,
          );
        }

        double newAmount;
        if (isTargetInr) {
          if (baseInr != null && baseInr > 0) {
            newAmount = baseInr;
          } else {
            final raw = currentAmount * conversionFactor;
            newAmount = CurrencyConversionHelper.recoverDriftedInrAmount(
              raw,
              ratesToInr: ratesToInr,
            );
            baseInr = newAmount;
          }
        } else {
          final effectiveBase = baseInr ?? currentAmount;
          newAmount = double.parse(
            CurrencyConversionHelper.convert(
              effectiveBase,
              fromCode: 'INR',
              toCode: targetCode,
              ratesToInr: ratesToInr,
            ).toStringAsFixed(2),
          );
          baseInr = effectiveBase;
        }

        await txn.update(
          tableSettlements,
          {'amount': newAmount, 'base_inr_amount': baseInr},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }
}

