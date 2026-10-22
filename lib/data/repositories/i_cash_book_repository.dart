import '../models/category_model.dart';
import '../models/person_model.dart';
import '../models/settlement_model.dart';
import '../models/split_expense_model.dart';
import '../models/split_group_model.dart';
import '../models/transaction_model.dart';

/// Segregated interface for managing standard cash book ledger transactions & categories.
/// Follows Interface Segregation Principle (ISP) by separating ledger operations from split group operations.
abstract class ITransactionRepository {
  Future<void> init();

  // --- Categories ---
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<bool> deleteCategory(String id);
  Future<void> resetCategoriesToDefaults();

  // --- Transactions ---
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);

  // --- Currency Conversion ---
  Future<void> convertAllCurrencyAmounts(
    double factor, {
    String? fromCurrency,
    String? toCurrency,
    Map<String, double>? ratesToInr,
  });
}

/// Segregated interface for managing split expenses, groups, persons, and settlements.
/// Follows Interface Segregation Principle (ISP) by allowing split-specific consumers to depend only on split contracts.
abstract class ISplitRepository {
  // --- Persons ---
  Future<List<PersonModel>> getPersons();
  Future<void> addPerson(PersonModel person);
  Future<void> updatePerson(PersonModel person);
  Future<bool> deletePerson(String id);

  // --- Groups ---
  Future<List<SplitGroupModel>> getGroups();
  Future<void> addGroup(SplitGroupModel group);
  Future<void> updateGroup(SplitGroupModel group);
  Future<void> deleteGroup(String id);

  // --- Split Expenses ---
  Future<List<SplitExpenseModel>> getSplitExpenses({
    String? groupId,
    String? personId,
  });
  Future<void> addSplitExpense(SplitExpenseModel expense);
  Future<void> updateSplitExpense(SplitExpenseModel expense);
  Future<void> deleteSplitExpense(String id);

  // --- Settlements ---
  Future<List<SettlementModel>> getSettlements({
    String? groupId,
    String? personId,
  });
  Future<void> addSettlement(SettlementModel settlement);
  Future<void> deleteSettlement(String id);
}

/// Unified repository contract that combines [ITransactionRepository] and [ISplitRepository].
/// Enables Dependency Inversion Principle (DIP) across the application.
abstract class ICashBookRepository implements ITransactionRepository, ISplitRepository {}
