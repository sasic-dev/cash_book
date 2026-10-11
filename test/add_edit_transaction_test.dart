import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/ui/screens/add_edit_transaction_screen.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';

void main() {
  testWidgets(
      'AddEditTransactionScreen shows category selector tile and opens bottom sheet to select category',
      (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      categories: CategoryModel.defaultCategories,
      transactions: [],
      people: [PersonModel.defaultCurrentUser],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AddEditTransactionScreen(
          viewModel: viewModel,
          initialType: TransactionType.expense,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify only the 5 payment mode chips are rendered (no category chips on screen)
    expect(find.byType(ChoiceChip), findsNWidgets(5));

    // Verify Category section header and selector tile exist
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget); // Default expense category
    expect(find.text('Select'), findsOneWidget);

    // Tap on category tile to open bottom sheet
    await tester.tap(find.text('Food & Dining'));
    await tester.pumpAndSettle();

    // Verify Modal Bottom Sheet is open
    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Transport & Fuel'), findsOneWidget);

    // Test search field in bottom sheet (find TextField inside bottom sheet)
    final searchField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, 'Groceries');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Groceries'), findsOneWidget);
    expect(find.text('Transport & Fuel'), findsNothing);

    // Select Groceries
    await tester.tap(find.widgetWithText(ListTile, 'Groceries'));
    await tester.pumpAndSettle();

    // Verify sheet is closed and Groceries is now selected in the tile
    expect(find.text('Select Category'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });
}
