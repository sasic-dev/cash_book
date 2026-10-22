import 'package:flutter_test/flutter_test.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/data/models/settlement_model.dart';
import 'package:cash_book/data/models/split_expense_model.dart';
import 'package:cash_book/data/models/split_group_model.dart';
import 'package:cash_book/data/repositories/i_cash_book_repository.dart';
import 'package:cash_book/data/services/split_strategy.dart';
import 'package:cash_book/ui/view_models/split_view_model.dart';

class MockSplitRepository implements ISplitRepository {
  List<PersonModel> people = [PersonModel.defaultCurrentUser];
  List<SplitGroupModel> groups = [];
  List<SplitExpenseModel> splitExpenses = [];
  List<SettlementModel> settlements = [];

  @override
  Future<List<PersonModel>> getPersons() async => List.from(people);

  @override
  Future<void> addPerson(PersonModel person) async => people.add(person);

  @override
  Future<void> updatePerson(PersonModel person) async {
    final idx = people.indexWhere((p) => p.id == person.id);
    if (idx != -1) people[idx] = person;
  }

  @override
  Future<bool> deletePerson(String id) async {
    people.removeWhere((p) => p.id == id);
    return true;
  }

  @override
  Future<List<SplitGroupModel>> getGroups() async => List.from(groups);

  @override
  Future<void> addGroup(SplitGroupModel group) async => groups.add(group);

  @override
  Future<void> updateGroup(SplitGroupModel group) async {
    final idx = groups.indexWhere((g) => g.id == group.id);
    if (idx != -1) groups[idx] = group;
  }

  @override
  Future<void> deleteGroup(String id) async => groups.removeWhere((g) => g.id == id);

  @override
  Future<List<SplitExpenseModel>> getSplitExpenses({String? groupId, String? personId}) async => List.from(splitExpenses);

  @override
  Future<void> addSplitExpense(SplitExpenseModel expense) async => splitExpenses.insert(0, expense);

  @override
  Future<void> updateSplitExpense(SplitExpenseModel expense) async {
    final idx = splitExpenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) splitExpenses[idx] = expense;
  }

  @override
  Future<void> deleteSplitExpense(String id) async => splitExpenses.removeWhere((e) => e.id == id);

  @override
  Future<List<SettlementModel>> getSettlements({String? groupId, String? personId}) async => List.from(settlements);

  @override
  Future<void> addSettlement(SettlementModel settlement) async => settlements.insert(0, settlement);

  @override
  Future<void> deleteSettlement(String id) async => settlements.removeWhere((s) => s.id == id);
}

void main() {
  group('SplitStrategy OCP Tests', () {
    test('EqualSplitStrategy splits amount equally with precise rounding remainder', () {
      const strategy = EqualSplitStrategy();
      expect(strategy.typeName, 'equal');

      // 100.00 split 3 ways: 33.33, 33.33, and 33.34 for the last person
      final splits = strategy.calculateSplits(
        totalAmount: 100.0,
        participantIds: ['p1', 'p2', 'p3'],
      );

      expect(splits.length, 3);
      expect(splits[0].amount, 33.33);
      expect(splits[1].amount, 33.33);
      expect(splits[2].amount, 33.34);
      expect(splits.fold(0.0, (sum, s) => sum + s.amount), 100.0);

      // Validation
      expect(strategy.validate(totalAmount: 100, participantIds: ['p1']), isNull);
      expect(strategy.validate(totalAmount: 0, participantIds: ['p1']), isNotNull);
      expect(strategy.validate(totalAmount: 50, participantIds: []), isNotNull);
    });

    test('ExactSplitStrategy allocates exact custom amounts and validates sum', () {
      const strategy = ExactSplitStrategy();
      expect(strategy.typeName, 'exact');

      final customInputs = {'p1': 40.0, 'p2': 60.0};
      final splits = strategy.calculateSplits(
        totalAmount: 100.0,
        participantIds: ['p1', 'p2'],
        customInputs: customInputs,
      );

      expect(splits.length, 2);
      expect(splits[0].amount, 40.0);
      expect(splits[1].amount, 60.0);

      // Validation passes when sum matches
      expect(
        strategy.validate(
          totalAmount: 100.0,
          participantIds: ['p1', 'p2'],
          customInputs: customInputs,
        ),
        isNull,
      );

      // Validation fails when sum differs
      expect(
        strategy.validate(
          totalAmount: 100.0,
          participantIds: ['p1', 'p2'],
          customInputs: {'p1': 40.0, 'p2': 50.0},
        ),
        isNotNull,
      );
    });

    test('PercentageSplitStrategy allocates percentage shares and validates 100%', () {
      const strategy = PercentageSplitStrategy();
      expect(strategy.typeName, 'percentage');

      final customInputs = {'p1': 70.0, 'p2': 30.0};
      final splits = strategy.calculateSplits(
        totalAmount: 200.0,
        participantIds: ['p1', 'p2'],
        customInputs: customInputs,
      );

      expect(splits.length, 2);
      expect(splits[0].amount, 140.0);
      expect(splits[0].percentage, 70.0);
      expect(splits[1].amount, 60.0);
      expect(splits[1].percentage, 30.0);

      // Validates exactly 100%
      expect(
        strategy.validate(
          totalAmount: 200.0,
          participantIds: ['p1', 'p2'],
          customInputs: customInputs,
        ),
        isNull,
      );

      expect(
        strategy.validate(
          totalAmount: 200.0,
          participantIds: ['p1', 'p2'],
          customInputs: {'p1': 50.0, 'p2': 40.0},
        ),
        isNotNull,
      );
    });

    test('SplitStrategyRegistry allows dynamic runtime strategy registration', () {
      final defaultStrategy = SplitStrategyRegistry.getStrategy('equal');
      expect(defaultStrategy, isA<EqualSplitStrategy>());

      // Unknown falls back to Equal
      final unknown = SplitStrategyRegistry.getStrategy('non_existent');
      expect(unknown, isA<EqualSplitStrategy>());
    });
  });

  group('SplitViewModel SRP Tests', () {
    test('SplitViewModel manages friends, groups, expenses, and settlements independently', () async {
      final repo = MockSplitRepository();
      final vm = SplitViewModel(repository: repo);

      await vm.init();

      expect(vm.people.length, 1);
      expect(vm.currentUser.name, 'You');

      // Add Friend
      final friend = PersonModel(
        id: 'person_rohit',
        name: 'Rohit Sharma',
        phoneNumber: '9876543210',
        upiId: 'rohit@upi',
        colorValue: 0xFF2196F3,
        createdAt: DateTime.now(),
      );
      await vm.addPerson(friend);
      expect(vm.people.length, 2);
      expect(vm.getPersonById('person_rohit')?.name, 'Rohit Sharma');

      // Add Group
      final group = SplitGroupModel(
        id: 'grp_goa',
        name: 'Goa Trip',
        iconCodePoint: 0xe571,
        colorValue: 0xFF9C27B0,
        memberIds: [vm.currentUser.id, 'person_rohit'],
        createdAt: DateTime.now(),
      );
      await vm.addGroup(group);
      expect(vm.groups.length, 1);
      expect(vm.getGroupById('grp_goa')?.name, 'Goa Trip');

      // Add Split Expense (You paid 2000, split 1000 each)
      final exp = SplitExpenseModel(
        id: 'exp_hotel',
        title: 'Beach Villa',
        totalAmount: 2000.0,
        date: DateTime.now(),
        paidByPersonId: vm.currentUser.id,
        groupId: 'grp_goa',
        splits: [
          ExpenseSplitItem(personId: vm.currentUser.id, amount: 1000.0),
          ExpenseSplitItem(personId: 'person_rohit', amount: 1000.0),
        ],
        createdAt: DateTime.now(),
      );
      await vm.addSplitExpense(exp);

      expect(vm.splitExpenses.length, 1);
      expect(vm.getPairwiseBalanceWith('person_rohit'), 1000.0);
      expect(vm.totalOwedToYou, 1000.0);
      expect(vm.totalYouOwe, 0.0);
      expect(vm.netSplitBalance, 1000.0);

      // Rohit settles 1000 with You
      final settlement = SettlementModel(
        id: 'stl_1',
        payerId: 'person_rohit',
        receiverId: vm.currentUser.id,
        amount: 1000.0,
        date: DateTime.now(),
        groupId: 'grp_goa',
        createdAt: DateTime.now(),
      );
      await vm.addSettlement(settlement);

      expect(vm.settlements.length, 1);
      expect(vm.getPairwiseBalanceWith('person_rohit'), 0.0);
      expect(vm.totalOwedToYou, 0.0);
      expect(vm.netSplitBalance, 0.0);
    });
  });
}
