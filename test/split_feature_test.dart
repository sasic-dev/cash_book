import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/data/models/settlement_model.dart';
import 'package:cash_book/data/models/split_expense_model.dart';
import 'package:cash_book/data/models/split_group_model.dart';
import 'package:cash_book/data/repositories/cash_book_repository.dart';
import 'package:cash_book/data/services/cash_book_database_service.dart';
import 'package:cash_book/data/services/split_calculator_service.dart';
import 'package:cash_book/ui/screens/split_home_screen.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';
import 'package:cash_book/ui/widgets/add_edit_group_dialog.dart';
import 'package:cash_book/ui/screens/add_edit_split_expense_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('SplitCalculatorService tests', () {
    test('Calculates equal split and pairwise debt correctly', () {
      const youId = 'person_you';
      const rahulId = 'person_rahul';
      const snehaId = 'person_sneha';

      // You paid 3000, split 1000 each
      final exp1 = SplitExpenseModel(
        id: 'exp1',
        title: 'Hotel',
        totalAmount: 3000,
        date: DateTime.now(),
        paidByPersonId: youId,
        splitType: 'equal',
        splits: const [
          ExpenseSplitItem(personId: youId, amount: 1000),
          ExpenseSplitItem(personId: rahulId, amount: 1000),
          ExpenseSplitItem(personId: snehaId, amount: 1000),
        ],
        createdAt: DateTime.now(),
      );

      final balanceRahul = SplitCalculatorService.calculatePairwiseBalance(
        currentUserId: youId,
        otherPersonId: rahulId,
        expenses: [exp1],
        settlements: [],
      );

      expect(balanceRahul, 1000.0); // Rahul owes You 1000

      // Rahul settles 1000 to You
      final st1 = SettlementModel(
        id: 'st1',
        payerId: rahulId,
        receiverId: youId,
        amount: 1000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final balanceAfterSettlement = SplitCalculatorService.calculatePairwiseBalance(
        currentUserId: youId,
        otherPersonId: rahulId,
        expenses: [exp1],
        settlements: [st1],
      );

      expect(balanceAfterSettlement, 0.0); // Settled up!
    });

    test('Simplified debts reduces group transactions', () {
      const member1 = 'A';
      const member2 = 'B';
      const member3 = 'C';

      // A paid 30 for A, B, C (10 each). B and C owe A 10.
      final exp = SplitExpenseModel(
        id: 'exp1',
        title: 'Lunch',
        totalAmount: 30,
        date: DateTime.now(),
        paidByPersonId: member1,
        groupId: 'grp1',
        splits: const [
          ExpenseSplitItem(personId: member1, amount: 10),
          ExpenseSplitItem(personId: member2, amount: 10),
          ExpenseSplitItem(personId: member3, amount: 10),
        ],
        createdAt: DateTime.now(),
      );

      final debts = SplitCalculatorService.calculateSimplifiedDebts(
        memberIds: [member1, member2, member3],
        expenses: [exp],
        settlements: [],
        groupId: 'grp1',
      );

      expect(debts.length, 2);
      expect(debts.any((d) => d.fromPersonId == member2 && d.toPersonId == member1 && d.amount == 10), isTrue);
      expect(debts.any((d) => d.fromPersonId == member3 && d.toPersonId == member1 && d.amount == 10), isTrue);
    });
  });

  group('Database and ViewModel integration for Split', () {
    test('Initializes with default user and seeds properly', () async {
      final dbService = CashBookDatabaseService(customDbPath: inMemoryDatabasePath);
      final repo = CashBookRepository(dbService: dbService);
      final vm = CashBookViewModel(repository: repo);

      await vm.init();

      expect(vm.people.isNotEmpty, isTrue);
      expect(vm.currentUser.name, 'You');
      expect(vm.groups.isNotEmpty, isTrue);
      expect(vm.splitExpenses.isNotEmpty, isTrue);

      // Verify that sample friends owe You money
      expect(vm.totalOwedToYou, greaterThan(0.0));

      await dbService.close();
    });

    test('Adding split expense with sync to CashBook creates transaction', () async {
      final dbService = CashBookDatabaseService(customDbPath: inMemoryDatabasePath);
      final repo = CashBookRepository(dbService: dbService);
      final vm = CashBookViewModel(repository: repo);

      await vm.init();

      final initialTxCount = vm.transactions.length;

      final newExp = SplitExpenseModel(
        id: 'test_exp_999',
        title: 'Team Pizza',
        totalAmount: 900.0,
        date: DateTime.now(),
        paidByPersonId: vm.currentUser.id,
        splitType: 'equal',
        splits: [
          ExpenseSplitItem(personId: vm.currentUser.id, amount: 300.0),
          const ExpenseSplitItem(personId: 'person_rahul', amount: 300.0),
          const ExpenseSplitItem(personId: 'person_sneha', amount: 300.0),
        ],
        createdAt: DateTime.now(),
      );

      await vm.addSplitExpense(newExp, syncToCashBook: true);

      expect(vm.splitExpenses.any((e) => e.id == 'test_exp_999'), isTrue);
      expect(vm.transactions.length, initialTxCount + 1);
      expect(vm.transactions.first.title, '[Split] Team Pizza');
      expect(vm.transactions.first.amount, 900.0);

      await dbService.close();
    });
  });

  testWidgets('SplitHomeScreen renders Friends, Groups, and Activity tabs cleanly', (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      people: [
        PersonModel.defaultCurrentUser,
        PersonModel(
          id: 'person_rahul',
          name: 'Rahul Sharma',
          colorValue: 0xFF43A047,
          createdAt: DateTime.now(),
        ),
      ],
      groups: [
        SplitGroupModel(
          id: 'group_weekend_trip',
          name: 'Weekend Trip',
          iconCodePoint: Icons.directions_car_rounded.codePoint,
          colorValue: 0xFF00897B,
          memberIds: ['person_you', 'person_rahul'],
          createdAt: DateTime.now(),
        ),
      ],
      splitExpenses: [
        SplitExpenseModel(
          id: 'exp1',
          title: 'Dinner & Drinks',
          totalAmount: 1500,
          date: DateTime.now(),
          paidByPersonId: 'person_you',
          groupId: 'group_weekend_trip',
          splits: const [
            ExpenseSplitItem(personId: 'person_you', amount: 750),
            ExpenseSplitItem(personId: 'person_rahul', amount: 750),
          ],
          createdAt: DateTime.now(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: SplitHomeScreen(viewModel: viewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Split Home elements
    expect(find.text('Split Expenses'), findsOneWidget);
    expect(find.text('OVERALL SPLIT BALANCE'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Split Expense'), findsOneWidget); // FAB
  });

  testWidgets('AddEditGroupDialog allows searching and selecting friends', (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      people: [
        PersonModel.defaultCurrentUser,
        PersonModel(
          id: 'person_rahul',
          name: 'Rahul Sharma',
          phoneNumber: '9876543210',
          colorValue: 0xFF43A047,
          createdAt: DateTime.now(),
        ),
        PersonModel(
          id: 'person_sneha',
          name: 'Sneha Patel',
          phoneNumber: '9123456780',
          colorValue: 0xFFE53935,
          createdAt: DateTime.now(),
        ),
        PersonModel(
          id: 'person_vikram',
          name: 'Vikram Singh',
          phoneNumber: '9988776655',
          colorValue: 0xFF1E88E5,
          createdAt: DateTime.now(),
        ),
      ],
      groups: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddEditGroupDialog.show(context, viewModel: viewModel),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Group'), findsOneWidget);
    expect(find.text('Group Members (1)'), findsOneWidget); // Only 'You'

    // Before search: no friends list shown by default!
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Rahul Sharma'), findsNothing);
    expect(find.text('Sneha Patel'), findsNothing);

    // Search for 'Sneha'
    await tester.enterText(find.byType(TextField).at(2), 'Sneha');
    await tester.pumpAndSettle();

    // Now Sneha is found in search results
    expect(find.text('Sneha Patel'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsNothing);
    expect(find.text('Vikram Singh'), findsNothing);

    // Ensure visible and tap Sneha Patel
    await tester.ensureVisible(find.text('Sneha Patel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sneha Patel'));
    await tester.pumpAndSettle();

    // Now group members count is 2 and Sneha is an InputChip
    expect(find.text('Group Members (2)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Sneha Patel'), findsOneWidget);

    // Since Sneha is now selected, she is removed from search list
    expect(find.byType(ListTile), findsNothing);

    // Clear search -> returns to no list by default
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);

    // Search for all with single letter 'a' -> should show Rahul & Vikram, but NOT Sneha (already selected)
    await tester.enterText(find.byType(TextField).at(2), 'a');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rahul Sharma'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Vikram Singh'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Sneha Patel'), findsNothing); // Excluded because already selected!

    // Enter group name
    await tester.ensureVisible(find.byType(TextField).at(0));
    await tester.enterText(find.byType(TextField).at(0), 'Weekend Goa Trip');
    await tester.pumpAndSettle();

    // Save group
    await tester.ensureVisible(find.text('Create Group'));
    await tester.tap(find.text('Create Group'));
    await tester.pumpAndSettle();

    // Dialog closed and group added to viewModel
    expect(find.text('Create New Group'), findsNothing);
    expect(viewModel.groups.length, 1);
    expect(viewModel.groups.first.name, 'Weekend Goa Trip');
    expect(viewModel.groups.first.memberIds, containsAll(['person_you', 'person_sneha']));
  });

  testWidgets('AddEditSplitExpenseScreen Paid By picker selector and bottom sheet works', (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      people: [
        PersonModel.defaultCurrentUser,
        PersonModel(
          id: 'person_rahul',
          name: 'Rahul Sharma',
          phoneNumber: '9876543210',
          colorValue: 0xFF43A047,
          createdAt: DateTime.now(),
        ),
      ],
      groups: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: AddEditSplitExpenseScreen(viewModel: viewModel),
    ));
    await tester.pumpAndSettle();

    // Verify "Paid By" section is present with selector tile
    await tester.ensureVisible(find.text('Paid By'));
    expect(find.text('Paid By'), findsOneWidget);
    expect(find.text('Paid full amount for this expense'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);

    // Tap on the selector tile to open the bottom sheet
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Verify bottom sheet appears with title and list
    expect(find.text('Select who paid the upfront expense'), findsOneWidget);
    expect(find.text('Search person...'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Rahul Sharma'), findsOneWidget);

    // Select Rahul Sharma
    await tester.tap(find.widgetWithText(ListTile, 'Rahul Sharma'));
    await tester.pumpAndSettle();

    // Bottom sheet is dismissed and Rahul Sharma is now shown as payer
    expect(find.text('Select who paid the upfront expense'), findsNothing);
    expect(find.text('Rahul Sharma'), findsWidgets);
  });
}
