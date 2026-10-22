import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/person_model.dart';
import '../../data/models/settlement_model.dart';
import '../../data/models/split_expense_model.dart';
import '../../data/models/split_group_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/cash_book_repository.dart';
import '../../data/services/split_calculator_service.dart';

enum DateFilter {
  all('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  custom('Custom');

  final String label;
  const DateFilter(this.label);
}

class CashBookViewModel extends ChangeNotifier {
  final ICashBookRepository _repository;

  CashBookViewModel({ICashBookRepository? repository})
      : _repository = repository ?? CashBookRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  // Split system state
  List<PersonModel> _people = [];
  List<PersonModel> get people => List.unmodifiable(_people);

  List<SplitGroupModel> _groups = [];
  List<SplitGroupModel> get groups => List.unmodifiable(_groups);

  List<SplitExpenseModel> _splitExpenses = [];
  List<SplitExpenseModel> get splitExpenses => List.unmodifiable(_splitExpenses);

  List<SettlementModel> _settlements = [];
  List<SettlementModel> get settlements => List.unmodifiable(_settlements);

  // Filters for Cash Book
  DateFilter _selectedDateFilter = DateFilter.thisMonth;
  DateFilter get selectedDateFilter => _selectedDateFilter;

  TransactionType? _selectedTypeFilter;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  DateTimeRange? _customDateRange;
  DateTimeRange? get customDateRange => _customDateRange;

  // Initialize and load data
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.init();
      _categories = await _repository.getCategories();
      _transactions = await _repository.getTransactions();
      _people = await _repository.getPersons();
      _groups = await _repository.getGroups();
      final loadedExpenses = await _repository.getSplitExpenses();
      final loadedSettlements = await _repository.getSettlements();

      final groupIds = _groups.map((g) => g.id).toSet();
      _splitExpenses = loadedExpenses
          .where((e) => e.groupId == null || groupIds.contains(e.groupId))
          .toList();
      _settlements = loadedSettlements
          .where((s) => s.groupId == null || groupIds.contains(s.groupId))
          .toList();
    } catch (_) {
      // Fallback
      _categories = CategoryModel.defaultCategories;
      _transactions = [];
      _people = [PersonModel.defaultCurrentUser];
      _groups = [];
      _splitExpenses = [];
      _settlements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets up in-memory data directly for widget tests and previews
  void seedTestData({
    List<CategoryModel>? categories,
    List<TransactionModel>? transactions,
    List<PersonModel>? people,
    List<SplitGroupModel>? groups,
    List<SplitExpenseModel>? splitExpenses,
    List<SettlementModel>? settlements,
  }) {
    if (categories != null) _categories = List.from(categories);
    if (transactions != null) _transactions = List.from(transactions);
    if (people != null) _people = List.from(people);
    if (groups != null) _groups = List.from(groups);
    if (splitExpenses != null) _splitExpenses = List.from(splitExpenses);
    if (settlements != null) _settlements = List.from(settlements);
    _isLoading = false;
    notifyListeners();
  }

  // --- Split Getters & Calculations ---

  PersonModel get currentUser => _people.firstWhere(
        (p) => p.isCurrentUser,
        orElse: () => PersonModel.defaultCurrentUser,
      );

  PersonModel? getPersonById(String id) {
    try {
      return _people.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  SplitGroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Balance with a specific person from the perspective of current user
  /// Positive: that person owes current user
  /// Negative: current user owes that person
  double getPairwiseBalanceWith(String personId) {
    return SplitCalculatorService.calculatePairwiseBalance(
      currentUserId: currentUser.id,
      otherPersonId: personId,
      expenses: _splitExpenses,
      settlements: _settlements,
    );
  }

  /// Total amount that other people owe the current user
  double get totalOwedToYou {
    double sum = 0.0;
    for (final person in _people) {
      if (!person.isCurrentUser) {
        final bal = getPairwiseBalanceWith(person.id);
        if (bal > 0.01) {
          sum += bal;
        }
      }
    }
    return sum;
  }

  /// Total amount that current user owes other people
  double get totalYouOwe {
    double sum = 0.0;
    for (final person in _people) {
      if (!person.isCurrentUser) {
        final bal = getPairwiseBalanceWith(person.id);
        if (bal < -0.01) {
          sum += (-bal);
        }
      }
    }
    return sum;
  }

  /// Net balance in the split system
  double get netSplitBalance => totalOwedToYou - totalYouOwe;

  /// Simplified debts for a group
  List<SimplifiedDebt> getGroupSimplifiedDebts(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return [];

    return SplitCalculatorService.calculateSimplifiedDebts(
      memberIds: group.memberIds,
      expenses: _splitExpenses,
      settlements: _settlements,
      groupId: groupId,
    );
  }

  // --- Categories helper lists ---
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == TransactionType.expense).toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == TransactionType.income).toList();

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return CategoryModel(
        id: id,
        name: 'General',
        type: TransactionType.expense,
        iconCodePoint: Icons.category_rounded.codePoint,
        colorValue: 0xFF757575,
      );
    }
  }

  // Filtered transactions for Cash Book tab
  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();

    return _transactions.where((tx) {
      if (_selectedTypeFilter != null && tx.type != _selectedTypeFilter) {
        return false;
      }
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final cat = getCategoryById(tx.categoryId);
        final matchesTitle = tx.title.toLowerCase().contains(query);
        final matchesCat = cat?.name.toLowerCase().contains(query) ?? false;
        final matchesMode = tx.paymentMode.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCat && !matchesMode) {
          return false;
        }
      }

      switch (_selectedDateFilter) {
        case DateFilter.today:
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case DateFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
          return tx.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              tx.date.isBefore(endOfDay.add(const Duration(seconds: 1)));
        case DateFilter.thisMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case DateFilter.thisYear:
          return tx.date.year == now.year;
        case DateFilter.custom:
          if (_customDateRange != null) {
            final start = DateTime(
                _customDateRange!.start.year,
                _customDateRange!.start.month,
                _customDateRange!.start.day);
            final end = DateTime(
                _customDateRange!.end.year,
                _customDateRange!.end.month,
                _customDateRange!.end.day,
                23,
                59,
                59);
            return tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                tx.date.isBefore(end.add(const Duration(seconds: 1)));
          }
          return true;
        case DateFilter.all:
          return true;
      }
    }).toList();
  }

  // Summary totals for current filtered view
  double get totalIncome => filteredTransactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => filteredTransactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalBalance => totalIncome - totalExpense;

  double get allTimeBalance {
    final inc = _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final exp = _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    return inc - exp;
  }

  // Filter setters
  void setDateFilter(DateFilter filter) {
    _selectedDateFilter = filter;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange? range) {
    _customDateRange = range;
    _selectedDateFilter = DateFilter.custom;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetFilters() {
    _selectedDateFilter = DateFilter.thisMonth;
    _selectedTypeFilter = null;
    _selectedCategoryId = null;
    _searchQuery = '';
    _customDateRange = null;
    notifyListeners();
  }

  // Transaction CRUD
  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _repository.addTransaction(transaction);
  }

  bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      final existing = _transactions[index];
      if (!isCurrentMonth(existing.date) || !isCurrentMonth(transaction.date)) {
        return false;
      }
      _transactions[index] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _repository.updateTransaction(transaction);
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final existing = _transactions[index];
      if (!isCurrentMonth(existing.date)) {
        return false;
      }
      _transactions.removeAt(index);
      notifyListeners();
      await _repository.deleteTransaction(id);
      return true;
    }
    return false;
  }

  // Category CRUD
  Future<void> addCategory(CategoryModel category) async {
    _categories.add(category);
    notifyListeners();
    await _repository.addCategory(category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
      await _repository.updateCategory(category);
    }
  }

  Future<bool> deleteCategory(String id) async {
    final success = await _repository.deleteCategory(id);
    if (success) {
      _categories = await _repository.getCategories();
      _transactions = await _repository.getTransactions();
      notifyListeners();
    }
    return success;
  }

  Future<void> resetCategoriesToDefaults() async {
    await _repository.resetCategoriesToDefaults();
    _categories = await _repository.getCategories();
    notifyListeners();
  }

  int getTransactionCountForCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).length;
  }

  double getTotalAmountForCategory(String categoryId) {
    return _transactions
        .where((t) => t.categoryId == categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // --- Person Operations ---

  Future<void> addPerson(PersonModel person) async {
    _people.add(person);
    _people.sort((a, b) {
      if (a.isCurrentUser) return -1;
      if (b.isCurrentUser) return 1;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
    await _repository.addPerson(person);
  }

  Future<void> updatePerson(PersonModel person) async {
    final index = _people.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      _people[index] = person;
      notifyListeners();
      await _repository.updatePerson(person);
    }
  }

  Future<bool> deletePerson(String id) async {
    final success = await _repository.deletePerson(id);
    if (success) {
      _people.removeWhere((p) => p.id == id);
      _groups = await _repository.getGroups();
      _splitExpenses = await _repository.getSplitExpenses();
      notifyListeners();
    }
    return success;
  }

  // --- Group Operations ---

  Future<void> addGroup(SplitGroupModel group) async {
    _groups.insert(0, group);
    notifyListeners();
    await _repository.addGroup(group);
  }

  Future<void> updateGroup(SplitGroupModel group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      notifyListeners();
      await _repository.updateGroup(group);
    }
  }

  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    _splitExpenses.removeWhere((e) => e.groupId == id);
    _settlements.removeWhere((s) => s.groupId == id);
    notifyListeners();
    await _repository.deleteGroup(id);
    _transactions = await _repository.getTransactions();
    notifyListeners();
  }

  // --- Split Expense Operations ---

  Future<void> addSplitExpense(
    SplitExpenseModel expense, {
    bool syncToCashBook = false,
  }) async {
    String? linkedTxId;

    if (syncToCashBook && expense.paidByPersonId == currentUser.id) {
      final tx = TransactionModel(
        id: 'tx_split_${expense.id}',
        amount: expense.totalAmount,
        type: TransactionType.expense,
        categoryId: expense.categoryId ?? 'exp_food',
        date: expense.date,
        title: '[Split] ${expense.title}',
        paymentMode: 'Cash',
      );
      linkedTxId = tx.id;
      _transactions.insert(0, tx);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _repository.addTransaction(tx);
    }

    final savedExpense = expense.copyWith(linkedCashBookTxId: linkedTxId);
    _splitExpenses.insert(0, savedExpense);
    _splitExpenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _repository.addSplitExpense(savedExpense);
  }

  Future<bool> updateSplitExpense(
    SplitExpenseModel expense, {
    bool syncToCashBook = false,
  }) async {
    final index = _splitExpenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      final old = _splitExpenses[index];
      if (!isCurrentMonth(old.date) || !isCurrentMonth(expense.date)) {
        return false;
      }
      String? linkedTxId = old.linkedCashBookTxId;

      if (syncToCashBook && expense.paidByPersonId == currentUser.id) {
        final tx = TransactionModel(
          id: linkedTxId ?? 'tx_split_${expense.id}',
          amount: expense.totalAmount,
          type: TransactionType.expense,
          categoryId: expense.categoryId ?? 'exp_food',
          date: expense.date,
          title: '[Split] ${expense.title}',
          paymentMode: 'Cash',
        );
        linkedTxId = tx.id;
        await _repository.updateTransaction(tx);
        final txIdx = _transactions.indexWhere((t) => t.id == tx.id);
        if (txIdx != -1) {
          _transactions[txIdx] = tx;
        } else {
          _transactions.insert(0, tx);
        }
      } else if (!syncToCashBook && linkedTxId != null) {
        // Unlinked -> delete from cash book
        await _repository.deleteTransaction(linkedTxId);
        _transactions.removeWhere((t) => t.id == linkedTxId);
        linkedTxId = null;
      }

      final updated = expense.copyWith(linkedCashBookTxId: linkedTxId);
      _splitExpenses[index] = updated;
      _splitExpenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _repository.updateSplitExpense(updated);
      return true;
    }
    return false;
  }

  Future<bool> deleteSplitExpense(String id) async {
    final index = _splitExpenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      final exp = _splitExpenses[index];
      if (!isCurrentMonth(exp.date)) {
        return false;
      }
      if (exp.linkedCashBookTxId != null) {
        await _repository.deleteTransaction(exp.linkedCashBookTxId!);
        _transactions.removeWhere((t) => t.id == exp.linkedCashBookTxId);
      }
      _splitExpenses.removeAt(index);
      notifyListeners();
      await _repository.deleteSplitExpense(id);
      return true;
    }
    return false;
  }

  // --- Settlement Operations ---

  Future<void> addSettlement(
    SettlementModel settlement, {
    bool syncToCashBook = false,
  }) async {
    String? linkedTxId;

    if (syncToCashBook) {
      if (settlement.receiverId == currentUser.id) {
        // Current user received money -> Inflow / Income
        final payer = getPersonById(settlement.payerId);
        final tx = TransactionModel(
          id: 'tx_settle_${settlement.id}',
          amount: settlement.amount,
          type: TransactionType.income,
          categoryId: 'inc_other',
          date: settlement.date,
          title: '[Settlement] Repaid by ${payer?.name ?? "Friend"}',
          paymentMode: settlement.paymentMethod,
        );
        linkedTxId = tx.id;
        _transactions.insert(0, tx);
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        await _repository.addTransaction(tx);
      } else if (settlement.payerId == currentUser.id) {
        // Current user paid money -> Outflow / Expense
        final receiver = getPersonById(settlement.receiverId);
        final tx = TransactionModel(
          id: 'tx_settle_${settlement.id}',
          amount: settlement.amount,
          type: TransactionType.expense,
          categoryId: 'exp_other',
          date: settlement.date,
          title: '[Settlement] Paid to ${receiver?.name ?? "Friend"}',
          paymentMode: settlement.paymentMethod,
        );
        linkedTxId = tx.id;
        _transactions.insert(0, tx);
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        await _repository.addTransaction(tx);
      }
    }

    final saved = settlement.copyWith(linkedCashBookTxId: linkedTxId);
    _settlements.insert(0, saved);
    _settlements.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _repository.addSettlement(saved);
  }

  Future<bool> deleteSettlement(String id) async {
    final index = _settlements.indexWhere((s) => s.id == id);
    if (index != -1) {
      final st = _settlements[index];
      if (!isCurrentMonth(st.date)) {
        return false;
      }
      if (st.linkedCashBookTxId != null) {
        await _repository.deleteTransaction(st.linkedCashBookTxId!);
        _transactions.removeWhere((t) => t.id == st.linkedCashBookTxId);
      }
      _settlements.removeAt(index);
      notifyListeners();
      await _repository.deleteSettlement(id);
      return true;
    }
    return false;
  }

  /// Converts all recorded amounts in the database and in-memory state using [conversionFactor]
  Future<void> convertAllCurrencyAmounts(
    double conversionFactor, {
    String? fromCurrency,
    String? toCurrency,
    Map<String, double>? ratesToInr,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.convertAllCurrencyAmounts(
        conversionFactor,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        ratesToInr: ratesToInr,
      );
      await init();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

