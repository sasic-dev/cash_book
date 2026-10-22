import '../models/category_model.dart';
import '../models/person_model.dart';
import '../models/settlement_model.dart';
import '../models/split_expense_model.dart';
import '../models/split_group_model.dart';
import '../models/transaction_model.dart';
import '../services/cash_book_database_service.dart';
import 'i_cash_book_repository.dart';

export 'i_cash_book_repository.dart';

class CashBookRepository implements ICashBookRepository {
  final CashBookDatabaseService _dbService;

  CashBookRepository({CashBookDatabaseService? dbService})
      : _dbService = dbService ?? CashBookDatabaseService();

  @override
  Future<void> init() async {
    await _dbService.migrateFromSharedPreferencesIfApplicable();
  }

  // --- Categories ---

  @override
  Future<List<CategoryModel>> getCategories() async {
    return await _dbService.getCategories();
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await _dbService.insertCategory(category);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _dbService.updateCategory(category);
  }

  @override
  Future<bool> deleteCategory(String id) async {
    return await _dbService.deleteCategory(id);
  }

  @override
  Future<void> resetCategoriesToDefaults() async {
    await _dbService.resetCategoriesToDefaults();
  }

  // --- Transactions ---

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return await _dbService.getTransactions();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbService.insertTransaction(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbService.updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _dbService.deleteTransaction(id);
  }

  // --- Persons ---

  @override
  Future<List<PersonModel>> getPersons() async {
    return await _dbService.getPersons();
  }

  @override
  Future<void> addPerson(PersonModel person) async {
    await _dbService.insertPerson(person);
  }

  @override
  Future<void> updatePerson(PersonModel person) async {
    await _dbService.updatePerson(person);
  }

  @override
  Future<bool> deletePerson(String id) async {
    return await _dbService.deletePerson(id);
  }

  // --- Groups ---

  @override
  Future<List<SplitGroupModel>> getGroups() async {
    return await _dbService.getGroups();
  }

  @override
  Future<void> addGroup(SplitGroupModel group) async {
    await _dbService.insertGroup(group);
  }

  @override
  Future<void> updateGroup(SplitGroupModel group) async {
    await _dbService.updateGroup(group);
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _dbService.deleteGroup(id);
  }

  // --- Split Expenses ---

  @override
  Future<List<SplitExpenseModel>> getSplitExpenses({
    String? groupId,
    String? personId,
  }) async {
    return await _dbService.getSplitExpenses(
      groupId: groupId,
      personId: personId,
    );
  }

  @override
  Future<void> addSplitExpense(SplitExpenseModel expense) async {
    await _dbService.insertSplitExpense(expense);
  }

  @override
  Future<void> updateSplitExpense(SplitExpenseModel expense) async {
    await _dbService.updateSplitExpense(expense);
  }

  @override
  Future<void> deleteSplitExpense(String id) async {
    await _dbService.deleteSplitExpense(id);
  }

  // --- Settlements ---

  @override
  Future<List<SettlementModel>> getSettlements({
    String? groupId,
    String? personId,
  }) async {
    return await _dbService.getSettlements(
      groupId: groupId,
      personId: personId,
    );
  }

  @override
  Future<void> addSettlement(SettlementModel settlement) async {
    await _dbService.insertSettlement(settlement);
  }

  @override
  Future<void> deleteSettlement(String id) async {
    await _dbService.deleteSettlement(id);
  }

  // --- Currency Conversion ---

  @override
  Future<void> convertAllCurrencyAmounts(
    double factor, {
    String? fromCurrency,
    String? toCurrency,
    Map<String, double>? ratesToInr,
  }) async {
    await _dbService.convertAllCurrencyAmounts(
      factor,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      ratesToInr: ratesToInr,
    );
  }
}

