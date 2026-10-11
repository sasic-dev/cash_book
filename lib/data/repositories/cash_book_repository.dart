import '../models/category_model.dart';
import '../models/person_model.dart';
import '../models/settlement_model.dart';
import '../models/split_expense_model.dart';
import '../models/split_group_model.dart';
import '../models/transaction_model.dart';
import '../services/cash_book_database_service.dart';

class CashBookRepository {
  final CashBookDatabaseService _dbService;

  CashBookRepository({CashBookDatabaseService? dbService})
      : _dbService = dbService ?? CashBookDatabaseService();

  Future<void> init() async {
    await _dbService.migrateFromSharedPreferencesIfApplicable();
  }

  // --- Categories ---

  Future<List<CategoryModel>> getCategories() async {
    return await _dbService.getCategories();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _dbService.insertCategory(category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _dbService.updateCategory(category);
  }

  Future<bool> deleteCategory(String id) async {
    return await _dbService.deleteCategory(id);
  }

  Future<void> resetCategoriesToDefaults() async {
    await _dbService.resetCategoriesToDefaults();
  }

  // --- Transactions ---

  Future<List<TransactionModel>> getTransactions() async {
    return await _dbService.getTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbService.insertTransaction(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbService.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _dbService.deleteTransaction(id);
  }

  // --- Persons ---

  Future<List<PersonModel>> getPersons() async {
    return await _dbService.getPersons();
  }

  Future<void> addPerson(PersonModel person) async {
    await _dbService.insertPerson(person);
  }

  Future<void> updatePerson(PersonModel person) async {
    await _dbService.updatePerson(person);
  }

  Future<bool> deletePerson(String id) async {
    return await _dbService.deletePerson(id);
  }

  // --- Groups ---

  Future<List<SplitGroupModel>> getGroups() async {
    return await _dbService.getGroups();
  }

  Future<void> addGroup(SplitGroupModel group) async {
    await _dbService.insertGroup(group);
  }

  Future<void> updateGroup(SplitGroupModel group) async {
    await _dbService.updateGroup(group);
  }

  Future<void> deleteGroup(String id) async {
    await _dbService.deleteGroup(id);
  }

  // --- Split Expenses ---

  Future<List<SplitExpenseModel>> getSplitExpenses({
    String? groupId,
    String? personId,
  }) async {
    return await _dbService.getSplitExpenses(
      groupId: groupId,
      personId: personId,
    );
  }

  Future<void> addSplitExpense(SplitExpenseModel expense) async {
    await _dbService.insertSplitExpense(expense);
  }

  Future<void> updateSplitExpense(SplitExpenseModel expense) async {
    await _dbService.updateSplitExpense(expense);
  }

  Future<void> deleteSplitExpense(String id) async {
    await _dbService.deleteSplitExpense(id);
  }

  // --- Settlements ---

  Future<List<SettlementModel>> getSettlements({
    String? groupId,
    String? personId,
  }) async {
    return await _dbService.getSettlements(
      groupId: groupId,
      personId: personId,
    );
  }

  Future<void> addSettlement(SettlementModel settlement) async {
    await _dbService.insertSettlement(settlement);
  }

  Future<void> deleteSettlement(String id) async {
    await _dbService.deleteSettlement(id);
  }
}
