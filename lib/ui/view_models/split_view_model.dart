import 'package:flutter/material.dart';
import '../../data/models/person_model.dart';
import '../../data/models/settlement_model.dart';
import '../../data/models/split_expense_model.dart';
import '../../data/models/split_group_model.dart';
import '../../data/repositories/cash_book_repository.dart';
import '../../data/services/split_calculator_service.dart';

/// ViewModel dedicated exclusively to split expenses, group management,
/// friend balances, and settlement workflows.
/// Follows Single Responsibility Principle (SRP) and depends on [ISplitRepository] (DIP).
class SplitViewModel extends ChangeNotifier {
  final ISplitRepository _repository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<PersonModel> _people = [];
  List<PersonModel> get people => List.unmodifiable(_people);

  List<SplitGroupModel> _groups = [];
  List<SplitGroupModel> get groups => List.unmodifiable(_groups);

  List<SplitExpenseModel> _splitExpenses = [];
  List<SplitExpenseModel> get splitExpenses => List.unmodifiable(_splitExpenses);

  List<SettlementModel> _settlements = [];
  List<SettlementModel> get settlements => List.unmodifiable(_settlements);

  SplitViewModel({ISplitRepository? repository})
      : _repository = repository ?? CashBookRepository();

  /// Loads all split data from repository
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _people = List.from(await _repository.getPersons());
      _groups = List.from(await _repository.getGroups());
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
    List<PersonModel>? people,
    List<SplitGroupModel>? groups,
    List<SplitExpenseModel>? splitExpenses,
    List<SettlementModel>? settlements,
  }) {
    if (people != null) _people = List.from(people);
    if (groups != null) _groups = List.from(groups);
    if (splitExpenses != null) _splitExpenses = List.from(splitExpenses);
    if (settlements != null) _settlements = List.from(settlements);
    _isLoading = false;
    notifyListeners();
  }

  // --- Getters & Calculations ---

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

  /// Net balance across all split friends and groups
  double get netSplitBalance => totalOwedToYou - totalYouOwe;

  /// Simplified debt settlement graph for a group
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

  // --- CRUD: Persons ---

  Future<void> addPerson(PersonModel person) async {
    _people.add(person);
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

  // --- CRUD: Groups ---

  Future<void> addGroup(SplitGroupModel group) async {
    _groups.add(group);
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
  }

  // --- CRUD: Split Expenses ---

  Future<void> addSplitExpense(SplitExpenseModel expense) async {
    _splitExpenses.insert(0, expense);
    notifyListeners();
    await _repository.addSplitExpense(expense);
  }

  Future<void> updateSplitExpense(SplitExpenseModel expense) async {
    final index = _splitExpenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _splitExpenses[index] = expense;
      notifyListeners();
      await _repository.updateSplitExpense(expense);
    }
  }

  Future<void> deleteSplitExpense(String id) async {
    _splitExpenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _repository.deleteSplitExpense(id);
  }

  // --- CRUD: Settlements ---

  Future<void> addSettlement(SettlementModel settlement) async {
    _settlements.insert(0, settlement);
    notifyListeners();
    await _repository.addSettlement(settlement);
  }

  Future<void> deleteSettlement(String id) async {
    _settlements.removeWhere((s) => s.id == id);
    notifyListeners();
    await _repository.deleteSettlement(id);
  }
}
